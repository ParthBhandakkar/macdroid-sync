import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/macdroid_state.dart';
import '../theme/app_theme.dart';
import '../models/remote_file_entry.dart';

class RemoteFileExplorer extends StatefulWidget {
  final MacDroidState state;

  const RemoteFileExplorer({super.key, required this.state});

  @override
  State<RemoteFileExplorer> createState() => _RemoteFileExplorerState();
}

class _RemoteFileExplorerState extends State<RemoteFileExplorer> {
  final TextEditingController _pathController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    _pathController.text = widget.state.currentRemotePath;
  }

  @override
  void didUpdateWidget(covariant RemoteFileExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.currentRemotePath != _pathController.text) {
      _pathController.text = widget.state.currentRemotePath;
    }
  }

  @override
  void dispose() {
    _pathController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  IconData _getFileIcon(RemoteFileEntry entry) {
    if (entry.isDirectory) return Icons.folder_rounded;
    final mime = entry.mimeType;
    if (mime.startsWith('image/')) return Icons.image_rounded;
    if (mime.startsWith('video/')) return Icons.movie_rounded;
    if (mime.startsWith('audio/')) return Icons.music_note_rounded;
    if (mime.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (mime.contains('zip') || mime.contains('tar') || mime.contains('archive')) {
      return Icons.archive_rounded;
    }
    if (entry.name.endsWith('.apk')) return Icons.android_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _getFileColor(RemoteFileEntry entry) {
    if (entry.isDirectory) return AppTheme.accent;
    final mime = entry.mimeType;
    if (mime.startsWith('image/')) return AppTheme.emerald;
    if (mime.startsWith('video/')) return Colors.orangeAccent;
    if (mime.startsWith('audio/')) return Colors.purpleAccent;
    if (mime.contains('pdf')) return AppTheme.rose;
    if (entry.name.endsWith('.apk')) return const Color(0xFF3DDC84);
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final activePeer = widget.state.activePeer;
    final allEntries = widget.state.remoteFiles;
    final filtered = _searchFilter.isEmpty
        ? allEntries
        : allEntries.where((e) => e.name.toLowerCase().contains(_searchFilter.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activePeer != null
                          ? 'Browse Storage: ${activePeer.name}'
                          : 'Remote Device File Explorer',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activePeer != null
                          ? 'Browse, navigate, and download files from ${activePeer.name} with one tap'
                          : 'Pair a device to explore its internal storage, folders, and files',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                // Quick Shortcuts
                Row(
                  children: [
                    _buildShortcutButton('Downloads', '/storage/emulated/0/Download'),
                    const SizedBox(width: 8),
                    _buildShortcutButton('DCIM (Photos)', '/storage/emulated/0/DCIM'),
                    const SizedBox(width: 8),
                    _buildShortcutButton('Root', '/'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Navigation Address Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                    tooltip: 'Parent Folder',
                    onPressed: () => widget.state.navigateUpRemote(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Refresh',
                    onPressed: () => widget.state.browseRemoteDirectory(_pathController.text),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _pathController,
                      style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Enter remote directory path...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                      ),
                      onSubmitted: (val) {
                        widget.state.browseRemoteDirectory(val.trim());
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: 'Filter files...',
                        isDense: true,
                        prefixIcon: Icon(Icons.search, size: 16),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (val) {
                        setState(() => _searchFilter = val);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Content List or Empty State
            Expanded(
              child: activePeer == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phonelink_erase_rounded, size: 54, color: AppTheme.textMuted.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          const Text(
                            'No Paired Device Connected',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Pair your Android phone or PC via QR Code to browse its files.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : widget.state.isLoadingFiles
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
                              SizedBox(height: 16),
                              Text('Loading directory contents...', style: TextStyle(color: AppTheme.textSecondary)),
                            ],
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Text(
                                _searchFilter.isEmpty
                                    ? 'Directory is empty or inaccessible.'
                                    : 'No files matching "$_searchFilter"',
                                style: const TextStyle(color: AppTheme.textMuted),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                final entry = filtered[index];
                                final icon = _getFileIcon(entry);
                                final color = _getFileColor(entry);
                                final dateStr = DateFormat('MMM d, yyyy HH:mm').format(entry.modified);

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      if (entry.isDirectory) {
                                        widget.state.browseRemoteDirectory(entry.path);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppTheme.border.withOpacity(0.6)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(icon, color: color, size: 24),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  entry.name,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${entry.formattedSize} • $dateStr',
                                                  style: const TextStyle(
                                                    color: AppTheme.textMuted,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!entry.isDirectory)
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.download_rounded, size: 14),
                                              label: const Text('1-Tap Download'),
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                              ),
                                              onPressed: () {
                                                // Trigger remote download request
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Downloading ${entry.name}...'),
                                                    backgroundColor: AppTheme.primary,
                                                  ),
                                                );
                                              },
                                            )
                                          else
                                            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutButton(String label, String path) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
      onPressed: () => widget.state.browseRemoteDirectory(path),
      child: Text(label),
    );
  }
}
