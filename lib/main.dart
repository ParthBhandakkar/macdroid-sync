import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/macdroid_state.dart';
import 'ui/home_dashboard.dart';
import 'ui/screen_mirror_view.dart';
import 'ui/notifications_view.dart';
import 'ui/photos_gallery_view.dart';
import 'ui/calls_and_sms_view.dart';
import 'ui/clipboard_sync_view.dart';
import 'ui/remote_file_explorer.dart';
import 'ui/one_tap_transfer_view.dart';
import 'ui/pairing_qr_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MacDroidApp());
}

class MacDroidApp extends StatefulWidget {
  const MacDroidApp({super.key});

  @override
  State<MacDroidApp> createState() => _MacDroidAppState();
}

class _MacDroidAppState extends State<MacDroidApp> {
  late final MacDroidState _state;

  @override
  void initState() {
    super.initState();
    _state = MacDroidState();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        return MaterialApp(
          title: 'macDroid - Cross-Platform Sync',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: MacDroidShell(state: _state),
        );
      },
    );
  }
}

class MacDroidShell extends StatefulWidget {
  final MacDroidState state;

  const MacDroidShell({super.key, required this.state});

  @override
  State<MacDroidShell> createState() => _MacDroidShellState();
}

class _MacDroidShellState extends State<MacDroidShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 750;

    final pages = [
      HomeDashboard(
        state: widget.state,
        onNavigateTab: (idx) {
          setState(() => _selectedIndex = idx);
        },
      ),
      ScreenMirrorView(state: widget.state),
      NotificationsView(state: widget.state),
      PhotosGalleryView(state: widget.state),
      CallsAndSmsView(state: widget.state),
      ClipboardSyncView(state: widget.state),
      RemoteFileExplorer(state: widget.state),
      OneTapTransferView(state: widget.state),
    ];

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Left Navigation Sidebar
            Container(
              width: 250,
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(right: BorderSide(color: AppTheme.border, width: 1)),
              ),
              child: Column(
                children: [
                  // App Brand Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.sync_alt_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'macDroid',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              Text(
                                'Mac • Win • Android',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: AppTheme.border, height: 1),
                  const SizedBox(height: 8),

                  // Nav Items
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildNavItem(0, 'Dashboard', Icons.dashboard_rounded),
                        _buildNavItem(1, 'Screen Mirroring', Icons.phonelink_ring_rounded),
                        _buildNavItem(2, 'Notifications', Icons.notifications_none_rounded, badgeCount: widget.state.notifications.length),
                        _buildNavItem(3, 'Photos & Media', Icons.photo_library_outlined),
                        _buildNavItem(4, 'Calls & SMS', Icons.phone_in_talk_rounded),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          child: Divider(color: AppTheme.border, height: 1),
                        ),
                        _buildNavItem(5, 'Universal Clipboard', Icons.content_paste_rounded),
                        _buildNavItem(6, 'Remote Storage', Icons.folder_open_rounded),
                        _buildNavItem(7, '1-Tap Transfer', Icons.send_to_mobile_rounded),
                      ],
                    ),
                  ),

                  // Bottom Device Status Pill
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHover,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.state.isConnected ? AppTheme.emerald : AppTheme.rose,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.state.localDeviceName,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  widget.state.isConnected ? 'Signaling Mesh Active' : 'Offline / Standalone',
                                  style: TextStyle(
                                    color: widget.state.isConnected ? AppTheme.emerald : AppTheme.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.qr_code, size: 18, color: AppTheme.accent),
                            tooltip: 'Pair Device',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => PairingQrDialog(state: widget.state),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Active View
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: pages,
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile / Android layout with Bottom Navigation Bar
      const pageTitles = [
        'macDroid',
        'Screen Mirroring',
        'Notifications',
        'Photos & Media',
        'Calls & SMS',
        'Universal Clipboard',
        'Remote Storage',
        '1-Tap Transfer',
      ];

      return PopScope(
        canPop: _selectedIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_selectedIndex != 0) {
            setState(() => _selectedIndex = 0);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: _selectedIndex != 0
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Back to Home',
                    onPressed: () => setState(() => _selectedIndex = 0),
                  )
                : null,
            title: Text(pageTitles[_selectedIndex.clamp(0, pageTitles.length - 1)]),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                tooltip: 'Pair Device',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => PairingQrDialog(state: widget.state),
                  );
                },
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex < 5 ? _selectedIndex : 0,
            backgroundColor: AppTheme.surface,
            indicatorColor: AppTheme.primary.withOpacity(0.2),
            onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.accent),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.phonelink_ring_outlined),
                selectedIcon: Icon(Icons.phonelink_ring_rounded, color: AppTheme.accent),
                label: 'Mirror',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: widget.state.notifications.isNotEmpty,
                  label: Text('${widget.state.notifications.length}'),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
                selectedIcon: const Icon(Icons.notifications_rounded, color: AppTheme.accent),
                label: 'Alerts',
              ),
              const NavigationDestination(
                icon: Icon(Icons.photo_library_outlined),
                selectedIcon: Icon(Icons.photo_library_rounded, color: AppTheme.accent),
                label: 'Photos',
              ),
              const NavigationDestination(
                icon: Icon(Icons.phone_outlined),
                selectedIcon: Icon(Icons.phone_rounded, color: AppTheme.accent),
                label: 'Calls',
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildNavItem(int index, String label, IconData icon, {int? badgeCount}) {
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _selectedIndex = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
