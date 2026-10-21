import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/peer_device.dart';
import '../services/macdroid_state.dart';
import '../theme/app_theme.dart';
import 'pairing_qr_dialog.dart';

class HomeDashboard extends StatelessWidget {
  final MacDroidState state;
  final Function(int tabIndex) onNavigateTab;

  const HomeDashboard({
    super.key,
    required this.state,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final activePeer = state.activePeer;
    final latestClip = state.clipboardHistory.isNotEmpty ? state.clipboardHistory.first : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Welcome & Identity Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome to macDroid',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Connected as: ${state.localDeviceName} (${state.localPlatform.name.toUpperCase()})',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: const Text('Pair via QR'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => PairingQrDialog(state: state),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Active Device Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.surface,
                    AppTheme.surfaceHover,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activePeer != null ? AppTheme.primary.withOpacity(0.5) : AppTheme.border,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: activePeer != null
                          ? AppTheme.primary.withOpacity(0.2)
                          : AppTheme.border.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      activePeer != null
                          ? (activePeer.platform == DevicePlatform.android
                              ? Icons.phone_android_rounded
                              : Icons.laptop_mac_rounded)
                          : Icons.phonelink_off_rounded,
                      color: activePeer != null ? AppTheme.accent : AppTheme.textMuted,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                activePeer != null ? activePeer.name : 'No Active Peer Connected',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: activePeer != null
                                    ? AppTheme.emerald.withOpacity(0.15)
                                    : AppTheme.border,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: activePeer != null ? AppTheme.emerald : AppTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    activePeer != null ? 'P2P Synced' : 'Ready to Pair',
                                    style: TextStyle(
                                      color: activePeer != null ? AppTheme.emerald : AppTheme.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activePeer != null
                              ? 'Direct WebRTC mesh established • Cross-network NAT punched'
                              : 'Scan the QR code from your phone or Windows PC to establish a connection',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (activePeer != null)
                    OutlinedButton(
                      onPressed: () => onNavigateTab(1), // Go to files
                      child: const Text('Browse Files'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Quick Access & Integration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),

            // Feature Grid Cards (Responsive Layout)
            LayoutBuilder(
              builder: (context, constraints) {
                final card1 = _buildFeatureCard(
                  title: 'Universal Clipboard',
                  subtitle: state.isAutoClipboardEnabled ? 'Auto-syncing in real time' : 'Auto-sync paused',
                  icon: Icons.content_paste_rounded,
                  accentColor: AppTheme.primary,
                  contentWidget: latestClip != null
                      ? Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceHover,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  latestClip.text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 14),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: latestClip.text));
                                },
                              ),
                            ],
                          ),
                        )
                      : const Text(
                          'Copy anywhere to sync instantly',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                  actionLabel: 'Open Clipboard',
                  onAction: () => onNavigateTab(0),
                );

                final card2 = _buildFeatureCard(
                  title: 'Remote Storage',
                  subtitle: activePeer != null
                      ? 'Browsing ${activePeer.name}'
                      : 'Connect device to browse storage',
                  icon: Icons.folder_open_rounded,
                  accentColor: AppTheme.accent,
                  contentWidget: const Text(
                    'Access internal storage, Downloads, DCIM, and files with 1-tap download.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  actionLabel: 'Explore Files',
                  onAction: () => onNavigateTab(1),
                );

                final card3 = _buildFeatureCard(
                  title: '1-Tap File Send',
                  subtitle: 'High speed chunked P2P transfer',
                  icon: Icons.send_to_mobile_rounded,
                  accentColor: AppTheme.emerald,
                  contentWidget: const Text(
                    'Drag & drop any file. Chunked 64KB binary streams with zero size limit.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  actionLabel: 'Send File',
                  onAction: () => onNavigateTab(2),
                );

                if (constraints.maxWidth > 720) {
                  return Row(
                    children: [
                      Expanded(child: card1),
                      const SizedBox(width: 16),
                      Expanded(child: card2),
                      const SizedBox(width: 16),
                      Expanded(child: card3),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      card1,
                      const SizedBox(height: 14),
                      card2,
                      const SizedBox(height: 14),
                      card3,
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Widget contentWidget,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          contentWidget,
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}
