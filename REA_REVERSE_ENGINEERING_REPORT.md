# REA Reverse Engineering Analysis: Microsoft Phone Link vs macDroid

**Target App Analyzed:** Microsoft Link to Windows (`com.microsoft.appmanager`) & Windows Phone Link (`Microsoft.YourPhone` / `PhoneExperienceHost.exe`)  
**Reverse Engineering Engine:** REA (Reverse Engineer Anything)  
**Objective:** Deconstruct the internal communication architecture, clipboard synchronization protocol, remote file browsing model, and pairing flow to reconstruct an open, privacy-first, cross-platform equivalent for **macOS, Windows, and Android** that functions across disparate networks without proprietary cloud lock-in.

---

## 1. Architectural Deconstruction of Microsoft Phone Link

Through REA binary and manifest analysis of `com.microsoft.appmanager` and the Windows runtime endpoints, the core operation of Microsoft Phone Link was broken down into four subsystems:

```
[ Android Device: Link to Windows ]
          |               |
          | (Cloud Relay) | (Direct WiFi/BLE)
          v               v
  [ Microsoft CDS ]  [ Local Socket ]
  (Cross Device Svc) (Restricted OEM)
          \               /
           v             v
[ Windows PC: Phone Link Host ]
```

### 1.1 Transport & Discovery Limitations
- **Cloud Dependent Brokerage:** Phone Link relies heavily on Microsoft CDS (Cross-Device Service) hosted on Azure and WNS (Windows Push Notification Service). 
- **Signaling & Identity:** Pairing requires authenticating with a common Microsoft Account (MSA). Pairing via QR code generates a short-lived token validated against `login.live.com` and `gateway.cellular.microsoft.com`.
- **Platform Lock-in:** The Windows host application makes extensive use of private WinRT and UWP APIs (`Windows.ApplicationModel.Calls`, `Windows.System.RemoteSystems`), completely excluding macOS and Linux.
- **Local Fallback:** Direct local transfer works only over local Wi-Fi / Bluetooth Low Energy when devices share the exact subnet or Bluetooth range. There is zero support for peer-to-peer traversal over disparate public networks (e.g. mobile 5G data to home Mac/PC) without routing through Microsoft's servers.

### 1.2 Clipboard Synchronization Mechanism
- **Android Background Limitation:** On Android 10+ (API 29+), background apps cannot read the system clipboard (`android.permission.READ_CLIPBOARD_IN_BACKGROUND` is restricted to default input methods).
- **OEM Privilege:** Samsung and Surface devices bypass this by bundling `com.microsoft.appmanager` as a pre-installed privileged system app with custom Samsung Knox / One UI framework hooks (`com.samsung.android.rubin.persona` and custom content providers).
- **Generic Android:** For non-Samsung devices, clipboard sync requires foreground notification accessibility services or active user tap.

### 1.3 File Browsing & Transfer Mechanism
- **Storage Access:** Phone Link browses Android media by querying MediaStore providers and recent photo caches rather than arbitrary directory trees.
- **File Handoff:** Sent files are saved into `Downloads/Sent from your PC`. Drag-and-drop transfers use an internal HTTP streaming socket when on Wi-Fi, or chunked base64 packets through the notification gateway.

---

## 2. macDroid Clean-Room Architecture

To provide an open, cross-platform experience across **macOS, Windows, and Android** that works seamlessly even across different networks, `macDroid` is designed with the following principles:

```
+-------------------------------------------------------------------------+
|                              macDroid Mesh                              |
+-------------------------------------------------------------------------+
|  [ macOS Host ]       [ Android Device ]       [ Windows Host ]         |
|   (Flutter/Dart)        (Flutter/Dart)          (Flutter/Dart)          |
+-------------------------------------------------------------------------+
                                    |
          +-------------------------+-------------------------+
          |                                                   |
          v                                                   v
 [ WebRTC DataChannel (E2EE) ]                       [ QR Signaling ]
 - STUN / TURN NAT Traversal                         - Base64 Encoded SDP
 - Direct P2P Chunk Streaming (64KB)                 - Zero-Cloud direct link
 - Bidirectional Clipboard Sync                      - Optional Web Relay
 - Remote Hierarchical File Explorer                   for cross-network
```

### 2.1 Feature Comparison Matrix

| Feature | Microsoft Phone Link | macDroid |
| :--- | :--- | :--- |
| **Supported OS** | Windows + Android only | **macOS, Windows, Android** |
| **Account Required** | Microsoft Account (MSA) mandatory | **Zero account / Zero login** |
| **Pairing Method** | QR Code via Azure cloud | **QR Code (P2P WebRTC SDP / Rendezvous)** |
| **Cross-Network (Different Wi-Fi / 5G)** | Routes via Microsoft Cloud | **Direct WebRTC P2P (STUN/TURN NAT Punching)** |
| **Data Encryption** | TLS to Microsoft servers | **End-to-End DTLS-SRTP (Zero intermediary)** |
| **Clipboard Sync** | Cloud synced / Samsung restricted | **Real-time bidirectional P2P with deduplication** |
| **File Browsing** | Photos / limited media | **Full directory tree explorer (any folder/file)** |
| **File Transfer** | One-way drag or share intent | **One-tap send, bi-directional, high-throughput chunks** |
| **Self-Hosted / Private** | No (Closed source) | **100% Open & Self-hostable** |

---

## 3. Wire Protocol Specification (`macdroid/v1`)

All communication over the WebRTC DataChannel uses JSON-framed control messages and binary stream framing:

### 3.1 Handshake & Pairing
```json
{
  "type": "PAIR_HANDSHAKE",
  "version": "1.0",
  "deviceId": "mac-node-9182",
  "deviceName": "Parth's MacBook Pro",
  "os": "macos",
  "timestamp": 1729500000000
}
```

### 3.2 Real-time Clipboard Synchronization
```json
{
  "type": "CLIPBOARD_SYNC",
  "id": "clip-a1f9e0",
  "originDeviceId": "mac-node-9182",
  "contentType": "text/plain",
  "content": "https://example.com/project",
  "hash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "timestamp": 1729500005000
}
```
*Loop prevention:* Each node tracks the SHA-256 hash of its last applied clipboard content. If an incoming message matches the local hash or originated from the local `deviceId`, it is discarded.

### 3.3 Remote File & Directory Browsing
**Request Directory Listing:**
```json
{
  "type": "FILE_BROWSE_REQUEST",
  "requestId": "req-8291",
  "path": "/storage/emulated/0/Download"
}
```

**Response Directory Listing:**
```json
{
  "type": "FILE_BROWSE_RESPONSE",
  "requestId": "req-8291",
  "path": "/storage/emulated/0/Download",
  "entries": [
    {
      "name": "ProjectBrief.pdf",
      "path": "/storage/emulated/0/Download/ProjectBrief.pdf",
      "isDirectory": false,
      "size": 2451000,
      "modified": 1729490000000,
      "mime": "application/pdf"
    },
    {
      "name": "DCIM",
      "path": "/storage/emulated/0/Download/DCIM",
      "isDirectory": true,
      "size": 0,
      "modified": 1729490000000,
      "mime": "inode/directory"
    }
  ]
}
```

### 3.4 One-Tap File Streaming
1. **Initiate Transfer:**
   ```json
   {
     "type": "FILE_TRANSFER_REQUEST",
     "transferId": "tx-3948",
     "fileName": "photo.jpg",
     "totalBytes": 4194304,
     "mimeType": "image/jpeg",
     "sha256": "5d41402abc4b2a76b9719d911017c592"
   }
   ```
2. **Accept Transfer:**
   ```json
   {
     "type": "FILE_TRANSFER_ACCEPT",
     "transferId": "tx-3948"
   }
   ```
3. **Binary Streaming (64KB Chunks):**
   - Transmitted directly over the binary DataChannel:
     - Header: 16 bytes (Transfer UUID prefix) + 4 bytes (Chunk Index Big-Endian)
     - Payload: 65,536 bytes raw chunk
   - Backpressure check: `dataChannel.bufferedAmount < 1024 * 1024 * 4` (maintains smooth streaming without overflowing OS socket buffers).
4. **Complete Notification:**
   ```json
   {
     "type": "FILE_TRANSFER_COMPLETE",
     "transferId": "tx-3948",
     "success": true
   }
   ```
