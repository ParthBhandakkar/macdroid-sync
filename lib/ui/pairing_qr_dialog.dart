import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/macdroid_state.dart';
import '../theme/app_theme.dart';

class PairingQrDialog extends StatefulWidget {
  final MacDroidState state;

  const PairingQrDialog({super.key, required this.state});

  @override
  State<PairingQrDialog> createState() => _PairingQrDialogState();
}

class _PairingQrDialogState extends State<PairingQrDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _isCopied = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qrData = widget.state.getPairingQrCodeData();

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppTheme.border, width: 1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.qr_code_scanner, color: AppTheme.accent, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Pair New Device',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Scan this QR code with your Android phone or another PC to pair instantly across any network.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // QR Code Container with sleek white border
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 210,
                    backgroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 18),

                // Room Code Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHover,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pairing Room ID',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                          Text(
                            widget.state.currentSessionId,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        icon: Icon(
                          _isCopied ? Icons.check : Icons.copy,
                          size: 16,
                          color: _isCopied ? AppTheme.emerald : AppTheme.accent,
                        ),
                        label: Text(
                          _isCopied ? 'Copied' : 'Copy',
                          style: TextStyle(
                            color: _isCopied ? AppTheme.emerald : AppTheme.accent,
                            fontSize: 12,
                          ),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.state.currentSessionId));
                          setState(() => _isCopied = true);
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) setState(() => _isCopied = false);
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(color: AppTheme.border),
                const SizedBox(height: 16),

                // Manual connect input
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Or Enter Peer Room Code / URL:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'e.g. ROOM-1234 or macdroid://...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        final val = _codeController.text.trim();
                        if (val.isNotEmpty) {
                          widget.state.pairWithScannedCode(val);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Connecting to session: $val'),
                              backgroundColor: AppTheme.primary,
                            ),
                          );
                        }
                      },
                      child: const Text('Connect'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
