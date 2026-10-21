import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/macdroid_state.dart';
import '../services/screen_mirror_service.dart';
import '../theme/app_theme.dart';

class ScreenMirrorView extends StatefulWidget {
  final MacDroidState state;

  const ScreenMirrorView({super.key, required this.state});

  @override
  State<ScreenMirrorView> createState() => _ScreenMirrorViewState();
}

class _ScreenMirrorViewState extends State<ScreenMirrorView> {
  final GlobalKey _phoneCanvasKey = GlobalKey();
  Offset? _lastPointerPos;

  void _handlePointerEvent(PointerEvent event, String action) {
    if (!widget.state.screenMirror.isStreaming) return;

    final RenderBox? box = _phoneCanvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final localPos = box.globalToLocal(event.position);
    final width = box.size.width;
    final height = box.size.height;

    if (width > 0 && height > 0) {
      final xRatio = (localPos.dx / width).clamp(0.0, 1.0);
      final yRatio = (localPos.dy / height).clamp(0.0, 1.0);

      setState(() {
        _lastPointerPos = localPos;
      });

      widget.state.screenMirror.sendTouch(
        action: action,
        xRatio: xRatio,
        yRatio: yRatio,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mirrorService = widget.state.screenMirror;
    final isStreaming = mirrorService.isStreaming;
    final isPrivacyBlanked = mirrorService.isPrivacyBlanked;
    final activePeer = widget.state.activePeer;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Screen Mirroring & Control',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isStreaming
                                ? AppTheme.emerald.withOpacity(0.15)
                                : AppTheme.border,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isStreaming ? AppTheme.emerald : AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isStreaming ? 'Live Stream 60 FPS' : 'Idle',
                                style: TextStyle(
                                  color: isStreaming ? AppTheme.emerald : AppTheme.textMuted,
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
                    const Text(
                      'Sequoia-style phone mirroring • Touch & gesture injection • StandBy privacy screen',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                // Action Buttons & Privacy Blank Toggle
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // StandBy Privacy Blank Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPrivacyBlanked
                            ? AppTheme.primary.withOpacity(0.15)
                            : AppTheme.surfaceHover,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isPrivacyBlanked ? AppTheme.primary : AppTheme.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPrivacyBlanked ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 16,
                            color: isPrivacyBlanked ? AppTheme.accent : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Phone Screen Off',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 4),
                          Switch(
                            value: isPrivacyBlanked,
                            onChanged: (val) => mirrorService.togglePrivacyBlank(val),
                            activeColor: AppTheme.accent,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ),

                    // Start/Stop Mirroring Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isStreaming ? AppTheme.rose : AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: Icon(
                        isStreaming ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        size: 18,
                      ),
                      label: Text(isStreaming ? 'Stop Mirror' : 'Start Mirroring'),
                      onPressed: () {
                        if (isStreaming) {
                          mirrorService.stopMirroring();
                        } else {
                          mirrorService.startMirroring();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Main Display Area & Side Hardware Nav
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Phone Device Frame
                  Center(
                    child: Container(
                      width: 320,
                      height: 640,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(38),
                        border: Border.all(color: const Color(0xFF2A2A38), width: 6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          // Interactive Screen Surface
                          Positioned.fill(
                            child: Listener(
                              key: _phoneCanvasKey,
                              onPointerDown: (e) => _handlePointerEvent(e, 'down'),
                              onPointerMove: (e) => _handlePointerEvent(e, 'move'),
                              onPointerUp: (e) => _handlePointerEvent(e, 'up'),
                              child: _buildPhoneScreenContent(isStreaming, mirrorService),
                            ),
                          ),

                          // Dynamic Island / Camera Punch Hole Notch
                          Positioned(
                            top: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 90,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF1A1A24),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isStreaming ? AppTheme.emerald : const Color(0xFF1A1A24),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Touch indicator ripple
                          if (_lastPointerPos != null && isStreaming)
                            Positioned(
                              left: _lastPointerPos!.dx - 12,
                              top: _lastPointerPos!.dy - 12,
                              child: IgnorePointer(
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.accent.withOpacity(0.4),
                                    border: Border.all(color: AppTheme.accent, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Side Hardware Navigation Bar
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            _buildHardwareButton(
                              icon: Icons.arrow_back_rounded,
                              label: 'Back',
                              onPressed: () => mirrorService.sendNavigation('back'),
                            ),
                            const SizedBox(height: 10),
                            _buildHardwareButton(
                              icon: Icons.circle_outlined,
                              label: 'Home',
                              onPressed: () => mirrorService.sendNavigation('home'),
                            ),
                            const SizedBox(height: 10),
                            _buildHardwareButton(
                              icon: Icons.crop_square_rounded,
                              label: 'Recents',
                              onPressed: () => mirrorService.sendNavigation('recents'),
                            ),
                            const Divider(color: AppTheme.border, height: 20),
                            _buildHardwareButton(
                              icon: Icons.power_settings_new_rounded,
                              label: 'Power',
                              color: AppTheme.rose,
                              onPressed: () => mirrorService.sendNavigation('power'),
                            ),
                            const SizedBox(height: 10),
                            _buildHardwareButton(
                              icon: Icons.volume_up_rounded,
                              label: 'Vol +',
                              onPressed: () => mirrorService.sendNavigation('volume_up'),
                            ),
                            const SizedBox(height: 10),
                            _buildHardwareButton(
                              icon: Icons.volume_down_rounded,
                              label: 'Vol -',
                              onPressed: () => mirrorService.sendNavigation('volume_down'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Bottom Diagnostics Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.speed_rounded, size: 16, color: AppTheme.accent),
                  const SizedBox(width: 8),
                  Text(
                    isStreaming
                        ? 'Low-Latency WebRTC Stream • ~18ms RTT • Hardware H.264 Decoder'
                        : 'Stream offline. Click "Start Mirroring" to establish a direct display pipe.',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const Spacer(),
                  if (mirrorService.lastInjectedEvent != null)
                    Text(
                      mirrorService.lastInjectedEvent!,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.emerald),
                    ),
                  const SizedBox(width: 12),
                  Text(
                    activePeer != null ? activePeer.name : 'No device paired',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneScreenContent(bool isStreaming, ScreenMirrorService service) {
    if (!isStreaming) {
      return Container(
        color: const Color(0xFF12121A),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phonelink_ring_rounded, size: 36, color: AppTheme.accent),
              ),
              const SizedBox(height: 14),
              const Text(
                'Screen Mirroring',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Cast your phone screen and control it using mouse and keyboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Start Mirroring'),
                onPressed: () => service.startMirroring(),
              ),
            ],
          ),
        ),
      );
    }

    if (service.currentFrame != null && service.currentFrame!.imageBase64.isNotEmpty) {
      return Image.memory(
        base64Decode(service.currentFrame!.imageBase64),
        fit: BoxFit.cover,
      );
    }

    // Default Interactive Phone Simulation UI
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF0F172A), Color(0xFF020617)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 36),
          // Top Status Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                Row(
                  children: const [
                    Icon(Icons.wifi_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Icon(Icons.signal_cellular_4_bar_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Icon(Icons.battery_charging_full_rounded, size: 14, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Clock Widget
          Text(
            timeStr,
            style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w300, color: Colors.white),
          ),
          const Text(
            'Wednesday, October 21',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),

          const Spacer(),

          // Simulated App Icons Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildAppIcon(Icons.phone_rounded, 'Phone', const Color(0xFF22C55E)),
                _buildAppIcon(Icons.chat_bubble_rounded, 'Messages', const Color(0xFF3B82F6)),
                _buildAppIcon(Icons.photo_library_rounded, 'Photos', const Color(0xFFEC4899)),
                _buildAppIcon(Icons.camera_alt_rounded, 'Camera', const Color(0xFF6B7280)),
                _buildAppIcon(Icons.public_rounded, 'Chrome', const Color(0xFFF59E0B)),
                _buildAppIcon(Icons.music_note_rounded, 'Spotify', const Color(0xFF10B981)),
                _buildAppIcon(Icons.mail_rounded, 'Gmail', const Color(0xFFEF4444)),
                _buildAppIcon(Icons.settings_rounded, 'Settings', const Color(0xFF64748B)),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Bottom Home Bar Pill
          Center(
            child: Container(
              width: 100,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildAppIcon(IconData icon, String name, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildHardwareButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 20, color: color ?? AppTheme.textSecondary),
        ),
      ),
    );
  }
}
