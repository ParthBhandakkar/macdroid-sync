#!/usr/bin/env node
/**
 * macDroid Cross-Network Signaling & Companion Server
 * Zero-dependency pure Node.js WebSocket & Static HTTP Server
 */

const http = require('http');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const os = require('os');

const PORT = process.env.PORT || 8765;
const PUBLIC_DIR = path.join(__dirname, 'public');

// Rooms for cross-network pairing: roomId -> Set of client sockets
const rooms = new Map();

// Helper to get local IP addresses
function getLocalIPs() {
  const nets = os.networkInterfaces();
  const results = [];
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (net.family === 'IPv4' && !net.internal) {
        results.push(net.address);
      }
    }
  }
  return results.length > 0 ? results : ['127.0.0.1'];
}

// MIME types for static companion files
const MIME_TYPES = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
};

const server = http.createServer((req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // Health / API route
  if (req.url === '/api/info') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      app: 'macDroid Signaling Server',
      status: 'online',
      localIps: getLocalIPs(),
      activeRooms: rooms.size,
      timestamp: Date.now(),
    }));
    return;
  }

  // Static companion files
  let safePath = path.normalize(req.url.split('?')[0]);
  if (safePath === '/' || safePath === '') safePath = '/index.html';
  const filePath = path.join(PUBLIC_DIR, safePath);

  if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
    res.writeHead(200, { 'Content-Type': contentType });
    fs.createReadStream(filePath).pipe(res);
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('404 Not Found');
  }
});

// Lightweight RFC 6455 WebSocket Implementation (Pure Node stdlib)
server.on('upgrade', (req, socket, head) => {
  const wsKey = req.headers['sec-websocket-key'];
  if (!wsKey) {
    socket.destroy();
    return;
  }

  const acceptKey = crypto
    .createHash('sha1')
    .update(wsKey + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11')
    .digest('base64');

  const responseHeaders = [
    'HTTP/1.1 101 Switching Protocols',
    'Upgrade: websocket',
    'Connection: Upgrade',
    `Sec-WebSocket-Accept: ${acceptKey}`,
    '\r\n',
  ];

  socket.write(responseHeaders.join('\r\n'));

  // Socket state
  let clientSessionId = 'DEFAULT';
  let clientDeviceId = null;
  let clientDeviceName = 'Unknown';
  let clientPlatform = 'unknown';

  // Frame parser buffer
  let buffer = Buffer.alloc(0);

  function sendJson(obj) {
    const jsonStr = JSON.stringify(obj);
    const payload = Buffer.from(jsonStr, 'utf8');
    const length = payload.length;

    let header;
    if (length < 126) {
      header = Buffer.from([0x81, length]);
    } else if (length < 65536) {
      header = Buffer.alloc(4);
      header[0] = 0x81;
      header[1] = 126;
      header.writeUInt16BE(length, 2);
    } else {
      header = Buffer.alloc(10);
      header[0] = 0x81;
      header[1] = 127;
      header.writeBigUInt64BE(BigInt(length), 2);
    }

    try {
      socket.write(Buffer.concat([header, payload]));
    } catch (_) {}
  }

  socket.sendJson = sendJson;

  socket.on('data', (chunk) => {
    buffer = Buffer.concat([buffer, chunk]);

    while (buffer.length >= 2) {
      const firstByte = buffer[0];
      const secondByte = buffer[1];
      const opcode = firstByte & 0x0f;
      const isMasked = (secondByte & 0x80) !== 0;
      let payloadLength = secondByte & 0x7f;
      let offset = 2;

      if (payloadLength === 126) {
        if (buffer.length < 4) break;
        payloadLength = buffer.readUInt16BE(2);
        offset = 4;
      } else if (payloadLength === 127) {
        if (buffer.length < 10) break;
        payloadLength = Number(buffer.readBigUInt64BE(2));
        offset = 10;
      }

      let maskingKey = null;
      if (isMasked) {
        if (buffer.length < offset + 4) break;
        maskingKey = buffer.subarray(offset, offset + 4);
        offset += 4;
      }

      if (buffer.length < offset + payloadLength) break;

      const payload = buffer.subarray(offset, offset + payloadLength);
      buffer = buffer.subarray(offset + payloadLength);

      // Unmask
      if (isMasked && maskingKey) {
        for (let i = 0; i < payload.length; i++) {
          payload[i] ^= maskingKey[i % 4];
        }
      }

      // Handle close
      if (opcode === 0x08) {
        socket.end();
        return;
      }

      // Handle ping
      if (opcode === 0x09) {
        socket.write(Buffer.from([0x8a, 0x00])); // Pong
        continue;
      }

      // Handle text frame
      if (opcode === 0x01) {
        try {
          const text = payload.toString('utf8');
          const msg = JSON.parse(text);
          handleClientMessage(msg);
        } catch (_) {}
      }
    }
  });

  function handleClientMessage(msg) {
    const type = msg.type;

    if (type === 'REGISTER') {
      clientSessionId = msg.sessionId || 'DEFAULT';
      clientDeviceId = msg.deviceId;
      clientDeviceName = msg.deviceName || 'Peer';
      clientPlatform = msg.platform || 'unknown';

      if (!rooms.has(clientSessionId)) {
        rooms.set(clientSessionId, new Set());
      }
      const room = rooms.get(clientSessionId);
      room.add(socket);

      // Notify other peers in this room that a peer joined
      for (const peer of room) {
        if (peer !== socket) {
          peer.sendJson({
            type: 'PEER_JOINED',
            deviceId: clientDeviceId,
            deviceName: clientDeviceName,
            platform: clientPlatform,
          });
        }
      }

      sendJson({
        type: 'REGISTERED',
        sessionId: clientSessionId,
        peerCount: room.size,
      });
    } else if (type === 'FORWARD') {
      // Forward to other peers in room (or target device if specified)
      const targetId = msg.targetDeviceId;
      const room = rooms.get(clientSessionId);
      if (room) {
        for (const peer of room) {
          if (peer !== socket) {
            peer.sendJson(msg.payload);
          }
        }
      }
    } else if (type === 'PING') {
      sendJson({ type: 'PONG', timestamp: Date.now() });
    }
  }

  socket.on('close', () => {
    const room = rooms.get(clientSessionId);
    if (room) {
      room.delete(socket);
      if (room.size === 0) {
        rooms.delete(clientSessionId);
      } else {
        for (const peer of room) {
          peer.sendJson({
            type: 'PEER_LEFT',
            deviceId: clientDeviceId,
          });
        }
      }
    }
  });

  socket.on('error', () => {
    socket.destroy();
  });
});

server.listen(PORT, '0.0.0.0', () => {
  const ips = getLocalIPs();
  console.log(`====================================================`);
  console.log(`  macDroid Signaling & Companion Server Running!    `);
  console.log(`====================================================`);
  console.log(`  Port: ${PORT}`);
  console.log(`  Local: http://localhost:${PORT}`);
  ips.forEach(ip => {
    console.log(`  Network (open on Android/PC): http://${ip}:${PORT}`);
  });
  console.log(`  WebSocket Signaling: ws://0.0.0.0:${PORT}`);
  console.log(`====================================================`);
});
