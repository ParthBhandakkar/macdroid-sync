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
    final telemetry = state.telemetry;
    final nowPlaying = state.nowPlaying;
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
            const SizedBox(height: 20),

            // Active Device Hero Card & Live Telemetry
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
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
              child: Column(
                children: [
                  Row(
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
                                  : 'Scan the QR code from your phone or PC to establish a connection',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (activePeer != null)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.phonelink_ring_rounded, size: 16),
                          label: const Text('Mirror Screen'),
                          onPressed: () => onNavigateTab(1), // Go to screen mirror
                        ),
                    ],
                  ),

                  // Telemetry Strip
                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.border, height: 1),
                  const SizedBox(height: 14),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Battery
                        _buildTelemetryItem(
                          icon: telemetry.isCharging
                              ? Icons.battery_charging_full_rounded
                              : Icons.battery_std_rounded,
                          label: 'Battery',
                          value: '${telemetry.batteryLevel}%${telemetry.isCharging ? ' (Fast)' : ''}',
                          iconColor: telemetry.batteryLevel > 20 ? AppTheme.emerald : AppTheme.rose,
                        ),
                        const SizedBox(width: 28),
                        // Wi-Fi
                        _buildTelemetryItem(
                          icon: Icons.wifi_rounded,
                          label: 'Wi-Fi',
                          value: telemetry.wifiSsid ?? 'Not connected',
                          iconColor: AppTheme.accent,
                        ),
                        const SizedBox(width: 28),
                        // Cellular 5G
                        _buildTelemetryItem(
                          icon: Icons.signal_cellular_alt_rounded,
                          label: 'Cellular',
                          value: '${telemetry.cellularCarrier ?? "5G Network"} (${telemetry.cellularBars}/4)',
                          iconColor: Colors.orangeAccent,
                        ),
                        const SizedBox(width: 28),
                        // Storage
                        _buildTelemetryItem(
                          icon: Icons.pie_chart_rounded,
                          label: 'Internal Storage',
                          value: telemetry.formattedStorage,
                          iconColor: Colors.purpleAccent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quick Device Controls & Remote Toggles (Link to Windows & Apple style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Quick Remote Toggles:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  // Hotspot Toggle
                  _buildToggleChip(
                    label: 'Hotspot',
                    icon: Icons.wifi_tethering_rounded,
                    isActive: telemetry.isHotspotOn,
                    onTap: () {
                      state.telemetryService.toggleHotspot(!telemetry.isHotspotOn);
                    },
                  ),
                  // DND Toggle
                  _buildToggleChip(
                    label: 'Do Not Disturb',
                    icon: Icons.do_not_disturb_on_rounded,
                    isActive: telemetry.isDoNotDisturb,
                    onTap: () {
                      state.telemetryService.toggleDoNotDisturb(!telemetry.isDoNotDisturb);
                    },
                  ),
                  // Ringer Mode
                  _buildToggleChip(
                    label: 'Ringer: ${telemetry.ringerMode.toUpperCase()}',
                    icon: telemetry.ringerMode == 'silent'
                        ? Icons.volume_off_rounded
                        : (telemetry.ringerMode == 'vibrate' ? Icons.vibration_rounded : Icons.volume_up_rounded),
                    isActive: telemetry.ringerMode != 'silent',
                    onTap: () {
                      final next = telemetry.ringerMode == 'normal'
                          ? 'vibrate'
                          : (telemetry.ringerMode == 'vibrate' ? 'silent' : 'normal');
                      state.telemetryService.setRingerMode(next);
                    },
                  ),
                  // Find My Phone
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.rose,
                      side: const BorderSide(color: AppTheme.rose),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    icon: const Icon(Icons.ring_volume_rounded, size: 16),
                    label: const Text('Find My Phone'),
                    onPressed: () {
                      state.telemetryService.triggerFindMyPhone();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Playing high-pitch alert sound on mobile device...'),
                          backgroundColor: AppTheme.rose,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Remote Media Controller Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.music_note_rounded, color: AppTheme.accent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                nowPlaying.trackTitle,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                nowPlaying.appName,
                                style: const TextStyle(fontSize: 10, color: AppTheme.accent),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${nowPlaying.artist} • ${nowPlaying.album}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  // Playback Controls
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: () => state.mediaControl.previousTrack(),
                  ),
                  IconButton.filled(
                    icon: Icon(nowPlaying.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    onPressed: () => state.mediaControl.togglePlayPause(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: () => state.mediaControl.nextTrack(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Feature Hubs & Integrations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),

            // Feature Grid (Screen Mirroring, Notifications, Photos, Calls & SMS, Clipboard, Storage)
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 950 ? 3 : (constraints.maxWidth > 620 ? 2 : 1);

                final cards = [
                  _buildHubCard(
                    title: 'Screen Mirroring',
                    subtitle: 'Sequoia display cast & mouse injection',
                    icon: Icons.phonelink_ring_rounded,
                    color: AppTheme.accent,
                    badge: 'Interactive',
                    onTap: () => onNavigateTab(1),
                  ),
                  _buildHubCard(
                    title: 'Notifications',
                    subtitle: '${state.notifications.length} active alerts with quick reply',
                    icon: Icons.notifications_active_rounded,
                    color: AppTheme.primary,
                    badge: '${state.notifications.length} new',
                    onTap: () => onNavigateTab(2),
                  ),
                  _buildHubCard(
                    title: 'Photos & Media',
                    subtitle: 'Instant camera roll sync & download',
                    icon: Icons.photo_library_rounded,
                    color: Colors.pinkAccent,
                    badge: '${state.photos.length} items',
                    onTap: () => onNavigateTab(3),
                  ),
                  _buildHubCard(
                    title: 'Calls & Messages',
                    subtitle: 'Dial remote calls & SMS/RCS threads',
                    icon: Icons.phone_in_talk_rounded,
                    color: AppTheme.emerald,
                    badge: 'HFP Audio',
                    onTap: () => onNavigateTab(4),
                  ),
                  _buildHubCard(
                    title: 'Universal Clipboard',
                    subtitle: latestClip != null ? latestClip.text : 'Auto-sync clipboard across devices',
                    icon: Icons.content_paste_rounded,
                    color: Colors.cyanAccent,
                    badge: state.isAutoClipboardEnabled ? 'Active' : 'Paused',
                    onTap: () => onNavigateTab(5),
                  ),
                  _buildHubCard(
                    title: 'Remote Storage Explorer',
                    subtitle: 'Browse phone files, DCIM, and APKs',
                    icon: Icons.folder_open_rounded,
                    color: Colors.orangeAccent,
                    badge: 'Direct P2P',
                    onTap: () => onNavigateTab(6),
                  ),
                ];

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: cards.map((c) {
                    final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
                    return SizedBox(width: itemWidth, child: c);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildToggleChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accent.withOpacity(0.18) : AppTheme.surfaceHover,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppTheme.accent : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? AppTheme.accent : AppTheme.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppTheme.accent : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHubCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHover,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
