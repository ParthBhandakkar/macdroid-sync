# macDroid: Cross-Platform Sync for Mac, Windows & Android

> **Universal Clipboard • Remote Device Storage Explorer • 1-Tap P2P File Transfer • QR Code Cross-Network Pairing**

macDroid is a clean-room, privacy-first alternative to Microsoft Phone Link / Link to Windows, engineered using insights from **REA (Reverse Engineer Anything)** to break platform boundaries and operate seamlessly across **macOS, Windows, and Android** without proprietary cloud locks or Microsoft Account mandates.

---

## 🌟 Key Features

1. **Universal Bidirectional Clipboard**
   - Copy text or links on Mac, Windows, or Android—instantly available on your other devices.
   - Built-in loop-suppression using SHA-256 content hashes to prevent infinite bounceback loops.
2. **Remote Storage & Folder Explorer**
   - Browse your Android phone's storage (`Downloads`, `DCIM`, `Documents`, etc.) or PC hard drive in real time.
   - Navigate subfolders, search file names, and download any file with 1-tap.
3. **One-Tap High-Speed File Streaming**
   - Drag & drop or pick any file (Photos, 4K Videos, APKs, Zip archives).
   - High-throughput 64KB binary chunk streaming over direct WebRTC DataChannels with zero file size limits.
4. **Cross-Network QR Code Pairing**
   - Pair devices in seconds by scanning a dynamic QR code.
   - Works across **different networks** (e.g. mobile 5G/LTE to office/home Wi-Fi) using STUN/TURN NAT traversal and lightweight WebRTC signaling.
5. **No Cloud Account Required**
   - 100% peer-to-peer and self-hosted. Your data, files, and clipboard never touch external corporate servers.

---

## 📂 Project Architecture

```
macDroid/
├── REA_REVERSE_ENGINEERING_REPORT.md  # Detailed technical breakdown of Phone Link vs macDroid
├── pubspec.yaml                       # Flutter cross-platform dependencies
├── lib/
│   ├── main.dart                      # Shell with responsive desktop sidebar & mobile navigation
│   ├── theme/
│   │   └── app_theme.dart             # Dark glassmorphic design system tokens
│   ├── models/
│   │   ├── peer_device.dart           # Peer device identity & connection state
│   │   ├── clipboard_entry.dart       # Clipboard entry with SHA-256 deduplication
│   │   ├── remote_file_entry.dart     # Hierarchical file & folder model
│   │   └── transfer_task.dart         # Active transfer job & speed tracker
│   ├── protocols/
│   │   └── macdroid_protocol.dart     # JSON wire protocol framing
│   ├── services/
│   │   ├── macdroid_state.dart        # Reactive state coordinating all features
│   │   ├── macdroid_signaling_service.dart # Cross-network WebSocket / WebRTC signaling
│   │   ├── clipboard_sync_service.dart # Real-time clipboard watcher & sync engine
│   │   ├── remote_file_service.dart   # Local & remote storage directory reader
│   │   ├── file_transfer_service.dart # 64KB chunked file streamer with backpressure
│   │   └── qr_pairing_service.dart    # QR code generator and session parser
│   └── ui/
│       ├── home_dashboard.dart        # Hero connection card & quick action shortcuts
│       ├── clipboard_sync_view.dart   # Universal clipboard sync feed
│       ├── remote_file_explorer.dart  # Remote directory browser & 1-tap download
│       ├── one_tap_transfer_view.dart # File dropzone & real-time transfer monitor
│       └── pairing_qr_dialog.dart     # QR code scanner & pairing modal
├── server/                            # Cross-network zero-config signaling & web companion
│   ├── server.js                      # Pure Node.js WebSocket relay (zero external npm deps)
│   └── public/                        # Responsive companion client (runs immediately on Android & PC)
│       ├── index.html
│       ├── app.js
│       └── style.css
└── test/
    ├── macdroid_self_check.dart       # Assert-based self-check (Protocol, Hash, Chunking, QR)
    └── widget_test.dart               # Flutter smoke test
```

---

## 🚀 Quickstart & How to Run

### Step 1: Start the Cross-Network Signaling & Companion Server
Run the lightweight signaling server on your Mac (or any host):
```bash
cd macDroid/server
node server.js
```
The server will output:
```text
====================================================
  macDroid Signaling & Companion Server Running!    
====================================================
  Port: 8765
  Local: http://localhost:8765
  Network (open on Android/PC): http://192.168.x.x:8765
  WebSocket Signaling: ws://0.0.0.0:8765
====================================================
```

### Step 2: Instant Zero-Install Test (Android & PC)
Open the network URL shown above (e.g. `http://192.168.x.x:8765`) in Google Chrome or any browser on your Android phone and Windows PC.
- Tap **Pair New Device** to see the pairing QR code.
- Test copying text: it immediately synchronizes across both screens!
- Test browsing files and dropping a file to send in 1-tap.

### Step 3: Run Native Desktop App (macOS & Windows)
To run natively on your Mac or Windows machine:
```bash
cd macDroid
flutter run -d macos      # On macOS
flutter run -d windows    # On Windows
```

### Step 4: Build Android APK
To produce the release Android APK for your phone:
```bash
cd macDroid
flutter build apk --release
```
The output APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🧪 Verification & Self-Checks

To run the standalone assert-based self-check testing protocol serialization, clipboard deduplication, 64KB chunk reassembly, and QR roundtrip:
```bash
cd macDroid
dart test/macdroid_self_check.dart
```
Output:
```text
=== Running macDroid Ponytail Self-Check ===
[PASS] Protocol Handshake Framing
[PASS] Clipboard SHA-256 Deduplication
[PASS] 64KB Binary Chunking and Reassembly
[PASS] QR Pairing Payload Encoding/Decoding Round-Trip
[PASS] Remote File Serialization & Size Formatting

ALL 5 SELF-CHECKS PASSED SUCCESSFULLY!
```

To run Flutter widget tests:
```bash
flutter test
```
