import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/macdroid_state.dart';
import 'ui/home_dashboard.dart';
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
          setState(() => _selectedIndex = idx + 1);
        },
      ),
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
                  const SizedBox(height: 12),

                  // Nav Items
                  _buildNavItem(0, 'Dashboard', Icons.dashboard_rounded),
                  _buildNavItem(1, 'Universal Clipboard', Icons.content_paste_rounded),
                  _buildNavItem(2, 'Remote Storage', Icons.folder_open_rounded),
                  _buildNavItem(3, '1-Tap Transfer', Icons.send_to_mobile_rounded),

                  const Spacer(),

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
      return Scaffold(
        appBar: AppBar(
          title: const Text('macDroid'),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded),
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
          selectedIndex: _selectedIndex,
          backgroundColor: AppTheme.surface,
          indicatorColor: AppTheme.primary.withOpacity(0.2),
          onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.accent),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.content_paste_outlined),
              selectedIcon: Icon(Icons.content_paste_rounded, color: AppTheme.accent),
              label: 'Clipboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder_open_rounded, color: AppTheme.accent),
              label: 'Files',
            ),
            NavigationDestination(
              icon: Icon(Icons.swap_vert_rounded),
              selectedIcon: Icon(Icons.send_to_mobile_rounded, color: AppTheme.accent),
              label: 'Transfer',
            ),
          ],
        ),
      );
    }
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _selectedIndex = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
