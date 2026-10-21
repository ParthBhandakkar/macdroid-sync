/**
 * macDroid Web Companion Logic
 * Real-time Clipboard, File Explorer, 1-Tap Transfer, and QR Pairing
 */

// Device identity
const isAndroid = /Android/i.test(navigator.userAgent);
const isMac = /Macintosh/i.test(navigator.userAgent);
const isWindows = /Windows/i.test(navigator.userAgent);

const myPlatform = isAndroid ? 'android' : (isMac ? 'macos' : (isWindows ? 'windows' : 'web'));
const myDeviceId = 'client-' + Math.random().toString(36).substring(2, 9);
const myDeviceName = (isAndroid ? 'Android Phone' : (isMac ? 'Mac Companion' : (isWindows ? 'Windows Companion' : 'Web Companion'))) + ' (' + myDeviceId.substring(7) + ')';

let currentRoomId = 'MD-DEMO-ROOM';
let socket = null;
let activePeer = null;
let lastClipboardHash = null;

// Incoming file transfer buffers
const incomingTransfers = new Map(); // id -> { name, size, chunks: [] }

// DOM Elements
const sidebarDeviceName = document.getElementById('sidebar-device-name');
const sidebarRoomName = document.getElementById('sidebar-room-name');
const heroPeerName = document.getElementById('hero-peer-name');
const heroPeerBadge = document.getElementById('hero-peer-badge');
const heroPeerDesc = document.getElementById('hero-peer-desc');
const quickClipPreview = document.getElementById('quick-clip-preview');

const clipboardList = document.getElementById('clipboard-list');
const manualClipInput = document.getElementById('manual-clip-input');
const btnBroadcastClip = document.getElementById('btn-broadcast-clip');

const fileExplorerList = document.getElementById('file-explorer-list');
const dirPathInput = document.getElementById('dir-path-input');
const btnDirUp = document.getElementById('btn-dir-up');
const btnDirRefresh = document.getElementById('btn-dir-refresh');
const fileFilterInput = document.getElementById('file-filter-input');

const dropzone = document.getElementById('dropzone');
const fileInput = document.getElementById('file-input');
const transfersList = document.getElementById('transfers-list');

const qrModal = document.getElementById('qr-modal');
const btnShowQr = document.getElementById('btn-show-qr');
const btnPairHero = document.getElementById('btn-pair-hero');
const btnCloseModal = document.getElementById('btn-close-modal');
const modalRoomId = document.getElementById('modal-room-id');
const btnCopyRoom = document.getElementById('btn-copy-room');
const joinRoomInput = document.getElementById('join-room-input');
const btnJoinRoom = document.getElementById('btn-join-room');

// Set Initial UI
sidebarDeviceName.textContent = myDeviceName;
sidebarRoomName.textContent = 'Room: ' + currentRoomId;
modalRoomId.textContent = currentRoomId;

// Initialize WebSocket Connection
function connectSocket(roomId) {
  currentRoomId = roomId;
  sidebarRoomName.textContent = 'Room: ' + roomId;
  modalRoomId.textContent = roomId;

  if (socket) {
    socket.close();
  }

  const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
  const wsUrl = `${protocol}//${location.host}`;

  socket = new WebSocket(wsUrl);

  socket.onopen = () => {
    socket.send(JSON.stringify({
      type: 'REGISTER',
      deviceId: myDeviceId,
      deviceName: myDeviceName,
      platform: myPlatform,
      sessionId: currentRoomId,
    }));
  };

  socket.onmessage = (e) => {
    try {
      const msg = JSON.parse(e.data);
      handleIncomingMessage(msg);
    } catch (_) {}
  };

  socket.onclose = () => {
    setTimeout(() => connectSocket(currentRoomId), 3000);
  };
}

function sendToPeers(payload) {
  if (socket && socket.readyState === WebSocket.OPEN) {
    socket.send(JSON.stringify({
      type: 'FORWARD',
      payload: payload,
    }));
  }
}

// SHA-256 Hash Helper
async function sha256(str) {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(str));
  return Array.from(new Uint8Array(buf)).map(b => b.toString(16).padStart(2, '0')).join('');
}

// Handle Protocol Messages
async function handleIncomingMessage(msg) {
  const type = msg.type;

  if (type === 'PEER_JOINED' || type === 'HANDSHAKE') {
    if (msg.deviceId !== myDeviceId) {
      activePeer = {
        id: msg.deviceId,
        name: msg.deviceName || 'Remote Peer',
        platform: msg.platform || 'unknown',
      };
      heroPeerName.textContent = activePeer.name;
      heroPeerBadge.textContent = 'P2P Connected';
      heroPeerBadge.style.background = 'rgba(16, 185, 129, 0.2)';
      heroPeerBadge.style.color = 'var(--emerald)';
      heroPeerDesc.textContent = `Direct cross-network link active (${activePeer.platform.toUpperCase()})`;

      // Handshake back if they joined
      if (type === 'PEER_JOINED') {
        sendToPeers({
          type: 'HANDSHAKE',
          deviceId: myDeviceId,
          deviceName: myDeviceName,
          platform: myPlatform,
        });
      }
    }
  } else if (type === 'CLIPBOARD_SYNC') {
    if (msg.originDeviceId !== myDeviceId && msg.hash !== lastClipboardHash) {
      lastClipboardHash = msg.hash;
      addClipboardRecord(msg.text, msg.originDeviceName || 'Remote Peer', false);
      quickClipPreview.textContent = msg.text;

      // Try auto-writing to local clipboard if browser allows
      try {
        await navigator.clipboard.writeText(msg.text);
      } catch (_) {}
    }
  } else if (type === 'FILE_BROWSE_REQUEST') {
    // Companion provides mock or browsable structure
    sendToPeers({
      type: 'FILE_BROWSE_RESPONSE',
      requestId: msg.requestId,
      path: msg.path,
      entries: [
        { name: 'DCIM (Photos)', path: msg.path + '/DCIM', isDirectory: true, size: 0, modified: Date.now(), mimeType: 'inode/directory' },
        { name: 'Download', path: msg.path + '/Download', isDirectory: true, size: 0, modified: Date.now(), mimeType: 'inode/directory' },
        { name: 'Documents', path: msg.path + '/Documents', isDirectory: true, size: 0, modified: Date.now(), mimeType: 'inode/directory' },
        { name: 'Photo_2026.jpg', path: msg.path + '/Photo_2026.jpg', isDirectory: false, size: 3412000, modified: Date.now() - 3600000, mimeType: 'image/jpeg' },
        { name: 'Project_Contract.pdf', path: msg.path + '/Project_Contract.pdf', isDirectory: false, size: 1045000, modified: Date.now() - 86400000, mimeType: 'application/pdf' },
      ],
    });
  } else if (type === 'FILE_BROWSE_RESPONSE') {
    renderFileExplorer(msg.path, msg.entries || []);
  } else if (type === 'FILE_TRANSFER_REQUEST') {
    incomingTransfers.set(msg.transferId, {
      name: msg.fileName,
      totalBytes: msg.totalBytes,
      chunks: [],
      received: 0,
      startTime: Date.now(),
    });
    addTransferRecord(msg.transferId, msg.fileName, msg.totalBytes, 'incoming');
    sendToPeers({ type: 'FILE_TRANSFER_ACCEPT', transferId: msg.transferId });
  } else if (type === 'FILE_TRANSFER_CHUNK') {
    const transfer = incomingTransfers.get(msg.transferId);
    if (transfer) {
      transfer.chunks.push(msg.payload);
      const rawChunk = atob(msg.payload);
      transfer.received += rawChunk.length;
      updateTransferProgress(msg.transferId, transfer.received, transfer.totalBytes, transfer.startTime);
    }
  } else if (type === 'FILE_TRANSFER_COMPLETE') {
    const transfer = incomingTransfers.get(msg.transferId);
    if (transfer) {
      finalizeIncomingDownload(transfer);
      incomingTransfers.delete(msg.transferId);
    }
  }
}

// Clipboard Functions
async function broadcastClipText(text) {
  if (!text.trim()) return;
  const hash = await sha256(text);
  lastClipboardHash = hash;

  addClipboardRecord(text, 'This Device', true);
  quickClipPreview.textContent = text;

  sendToPeers({
    type: 'CLIPBOARD_SYNC',
    id: 'clip-' + Date.now(),
    text: text,
    hash: hash,
    originDeviceId: myDeviceId,
    originDeviceName: myDeviceName,
    timestamp: Date.now(),
  });
}

function addClipboardRecord(text, sender, isLocal) {
  const item = document.createElement('div');
  item.className = 'list-item';
  item.innerHTML = `
    <div class="item-info">
      <strong>${escapeHtml(text)}</strong>
      <span>From: ${sender} • ${new Date().toLocaleTimeString()}</span>
    </div>
    <button class="btn btn-secondary btn-sm btn-copy">Copy</button>
  `;
  item.querySelector('.btn-copy').addEventListener('click', () => {
    navigator.clipboard.writeText(text);
    item.querySelector('.btn-copy').textContent = 'Copied!';
    setTimeout(() => { item.querySelector('.btn-copy').textContent = 'Copy'; }, 1500);
  });
  clipboardList.prepend(item);
}

btnBroadcastClip.addEventListener('click', () => {
  const val = manualClipInput.value.trim();
  if (val) {
    broadcastClipText(val);
    manualClipInput.value = '';
  }
});

// File Explorer Rendering
function requestBrowse(path) {
  dirPathInput.value = path;
  fileExplorerList.innerHTML = '<div style="padding: 20px; color: var(--text-muted);">Requesting directory from peer...</div>';
  sendToPeers({
    type: 'FILE_BROWSE_REQUEST',
    requestId: 'req-' + Date.now(),
    path: path,
  });
}

function renderFileExplorer(path, entries) {
  fileExplorerList.innerHTML = '';
  if (entries.length === 0) {
    fileExplorerList.innerHTML = '<div style="padding: 20px; color: var(--text-muted);">Empty folder</div>';
    return;
  }

  entries.forEach(entry => {
    const row = document.createElement('div');
    row.className = 'file-row';
    const iconSvg = entry.isDirectory
      ? `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="2"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path></svg>`
      : `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--emerald)" stroke-width="2"><path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"></path><polyline points="13 2 13 9 20 9"></polyline></svg>`;

    row.innerHTML = `
      ${iconSvg}
      <span class="file-name">${escapeHtml(entry.name)}</span>
      <span class="file-meta">${entry.isDirectory ? 'Folder' : formatBytes(entry.size)}</span>
      ${!entry.isDirectory ? '<button class="btn btn-primary btn-sm btn-down">1-Tap Download</button>' : ''}
    `;

    if (entry.isDirectory) {
      row.addEventListener('click', () => requestBrowse(entry.path));
    } else {
      const downBtn = row.querySelector('.btn-down');
      if (downBtn) {
        downBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          alert(`Download initiated for ${entry.name}`);
        });
      }
    }

    fileExplorerList.appendChild(row);
  });
}

btnDirUp.addEventListener('click', () => {
  const parts = dirPathInput.value.split('/').filter(Boolean);
  if (parts.length > 0) {
    parts.pop();
    requestBrowse('/' + parts.join('/'));
  }
});

btnDirRefresh.addEventListener('click', () => {
  requestBrowse(dirPathInput.value);
});

// File Streaming (1-Tap Transfer)
dropzone.addEventListener('click', () => fileInput.click());
dropzone.addEventListener('dragover', (e) => { e.preventDefault(); dropzone.style.borderColor = 'var(--accent)'; });
dropzone.addEventListener('dragleave', () => { dropzone.style.borderColor = ''; });
dropzone.addEventListener('drop', (e) => {
  e.preventDefault();
  dropzone.style.borderColor = '';
  if (e.dataTransfer.files.length) {
    handleSelectedFiles(e.dataTransfer.files);
  }
});

fileInput.addEventListener('change', () => {
  if (fileInput.files.length) {
    handleSelectedFiles(fileInput.files);
  }
});

async function handleSelectedFiles(files) {
  for (const file of files) {
    await sendFileStream(file);
  }
}

async function sendFileStream(file) {
  const transferId = 'tx-' + Date.now();
  addTransferRecord(transferId, file.name, file.size, 'outgoing');

  sendToPeers({
    type: 'FILE_TRANSFER_REQUEST',
    transferId: transferId,
    fileName: file.name,
    totalBytes: file.size,
    mimeType: file.type || 'application/octet-stream',
  });

  const CHUNK_SIZE = 64 * 1024;
  const totalChunks = Math.ceil(file.size / CHUNK_SIZE) || 1;
  const startTime = Date.now();

  for (let i = 0; i < totalChunks; i++) {
    const start = i * CHUNK_SIZE;
    const end = Math.min(file.size, start + CHUNK_SIZE);
    const blob = file.slice(start, end);
    const buffer = await blob.arrayBuffer();

    let binary = '';
    const bytes = new Uint8Array(buffer);
    for (let b = 0; b < bytes.byteLength; b++) {
      binary += String.fromCharCode(bytes[b]);
    }
    const b64 = btoa(binary);

    sendToPeers({
      type: 'FILE_TRANSFER_CHUNK',
      transferId: transferId,
      chunkIndex: i,
      totalChunks: totalChunks,
      payload: b64,
    });

    updateTransferProgress(transferId, end, file.size, startTime);
    if (i % 8 === 0) await new Promise(r => setTimeout(r, 4));
  }

  sendToPeers({
    type: 'FILE_TRANSFER_COMPLETE',
    transferId: transferId,
    success: true,
  });
}

function addTransferRecord(id, name, totalBytes, direction) {
  const card = document.createElement('div');
  card.id = 'tx-card-' + id;
  card.className = 'list-item';
  card.innerHTML = `
    <div style="flex: 1;">
      <div style="display: flex; justify-content: space-between; margin-bottom: 6px;">
        <strong>${direction === 'outgoing' ? '&uarr;' : '&darr;'} ${escapeHtml(name)}</strong>
        <span id="tx-stat-${id}" style="color: var(--accent); font-weight: 600; font-size: 12px;">0%</span>
      </div>
      <div style="height: 6px; background: var(--surface-hover); border-radius: 3px; overflow: hidden;">
        <div id="tx-bar-${id}" style="width: 0%; height: 100%; background: var(--primary); transition: width 0.1s;"></div>
      </div>
      <div style="display: flex; justify-content: space-between; margin-top: 4px; font-size: 11px; color: var(--text-muted);">
        <span id="tx-bytes-${id}">0 / ${formatBytes(totalBytes)}</span>
        <span id="tx-speed-${id}">0 MB/s</span>
      </div>
    </div>
  `;
  transfersList.prepend(card);
}

function updateTransferProgress(id, current, total, startTime) {
  const bar = document.getElementById('tx-bar-' + id);
  const stat = document.getElementById('tx-stat-' + id);
  const bytes = document.getElementById('tx-bytes-' + id);
  const speed = document.getElementById('tx-speed-' + id);

  if (!bar) return;
  const pct = Math.min(100, Math.round((current / total) * 100)) || 0;
  bar.style.width = pct + '%';
  stat.textContent = pct === 100 ? 'Completed' : pct + '%';
  if (pct === 100) {
    stat.style.color = 'var(--emerald)';
    bar.style.background = 'var(--emerald)';
  }

  if (bytes) bytes.textContent = `${formatBytes(current)} of ${formatBytes(total)}`;

  const elapsed = (Date.now() - startTime) / 1000;
  if (speed && elapsed > 0.1) {
    const mbps = (current / (1024 * 1024)) / elapsed;
    speed.textContent = mbps.toFixed(1) + ' MB/s';
  }
}

function finalizeIncomingDownload(transfer) {
  const byteCharacters = transfer.chunks.map(b64 => atob(b64)).join('');
  const byteNumbers = new Array(byteCharacters.length);
  for (let i = 0; i < byteCharacters.length; i++) {
    byteNumbers[i] = byteCharacters.charCodeAt(i);
  }
  const byteArray = new Uint8Array(byteNumbers);
  const blob = new Blob([byteArray]);

  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = transfer.name;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
}

// Navigation Tabs
document.querySelectorAll('.nav-item').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.nav-item').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));
    btn.classList.add('active');
    const tabId = 'tab-' + btn.getAttribute('data-tab');
    const pane = document.getElementById(tabId);
    if (pane) pane.classList.add('active');
  });
});

document.querySelectorAll('.feature-card').forEach(card => {
  card.addEventListener('click', () => {
    const target = card.getAttribute('data-nav');
    const btn = document.querySelector(`.nav-item[data-tab="${target}"]`);
    if (btn) btn.click();
  });
});

// QR Code Modal
function renderQrCode() {
  const container = document.getElementById('qrcode');
  container.innerHTML = '';
  const qrString = `macdroid://${btoa(JSON.stringify({ s: currentRoomId, d: myDeviceId, u: location.origin }))}`;
  new QRCode(container, {
    text: qrString,
    width: 200,
    height: 200,
  });
}

btnShowQr.addEventListener('click', () => {
  renderQrCode();
  qrModal.classList.add('active');
});

btnPairHero.addEventListener('click', () => {
  renderQrCode();
  qrModal.classList.add('active');
});

btnCloseModal.addEventListener('click', () => {
  qrModal.classList.remove('active');
});

btnCopyRoom.addEventListener('click', () => {
  navigator.clipboard.writeText(currentRoomId);
  btnCopyRoom.textContent = 'Copied';
  setTimeout(() => { btnCopyRoom.textContent = 'Copy'; }, 1500);
});

btnJoinRoom.addEventListener('click', () => {
  const code = joinRoomInput.value.trim().toUpperCase();
  if (code) {
    connectSocket(code);
    qrModal.classList.remove('active');
    alert(`Connected to Room: ${code}`);
  }
});

// Helpers
function formatBytes(bytes) {
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
  return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

// Start initial connection
connectSocket(currentRoomId);
