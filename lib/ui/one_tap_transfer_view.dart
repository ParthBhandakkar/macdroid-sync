import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/transfer_task.dart';
import '../services/macdroid_state.dart';
import '../theme/app_theme.dart';

class OneTapTransferView extends StatelessWidget {
  final MacDroidState state;

  const OneTapTransferView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final tasks = state.transferTasks;
    final activePeer = state.activePeer;

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
                    const Text(
                      'One-Tap File Transfer',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activePeer != null
                          ? 'Send photos, documents, and videos directly to ${activePeer.name}'
                          : 'High-speed chunked P2P file transfer across any network',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                if (activePeer != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.emerald.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.emerald.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: AppTheme.emerald, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Direct P2P Ready',
                          style: TextStyle(
                            color: AppTheme.emerald,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Dropzone / File Picker Card
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: activePeer == null
                    ? null
                    : () async {
                        final result = await FilePicker.platform.pickFiles(
                          allowMultiple: true,
                        );
                        if (result != null && result.files.isNotEmpty) {
                          for (final file in result.files) {
                            if (file.path != null) {
                              try {
                                await state.sendOneTapFile(file.path!);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Transfer failed: $e'),
                                    backgroundColor: AppTheme.rose,
                                  ),
                                );
                              }
                            }
                          }
                        }
                      },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: activePeer != null ? AppTheme.primary.withOpacity(0.6) : AppTheme.border,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.upload_file_rounded,
                          size: 36,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        activePeer != null
                            ? 'Tap to Select Files to Send to ${activePeer.name}'
                            : 'Pair a Device to Enable File Transfer',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        activePeer != null
                            ? 'Any file format: Photos, APKs, Videos, Zip archives. Zero size limit.'
                            : 'Open Pairing to connect your Android phone or PC.',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Transfer Activity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Tasks List
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_vert_rounded, size: 48, color: AppTheme.textMuted.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          const Text(
                            'No active or recent transfers',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final isOut = task.direction == TransferDirection.outgoing;
                        final isDone = task.status == TransferStatus.completed;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isOut ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                    color: isOut ? AppTheme.accent : AppTheme.emerald,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      task.fileName,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDone
                                          ? AppTheme.emerald.withOpacity(0.15)
                                          : AppTheme.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isDone ? 'Completed' : '${(task.progress * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDone ? AppTheme.emerald : AppTheme.accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                value: isDone ? 1.0 : task.progress,
                                backgroundColor: AppTheme.surfaceHover,
                                color: isDone ? AppTheme.emerald : AppTheme.primary,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${task.formattedTransferred} of ${task.formattedTotalSize}',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                  ),
                                  if (!isDone && task.speedMBps > 0)
                                    Text(
                                      '${task.speedMBps.toStringAsFixed(1)} MB/s',
                                      style: const TextStyle(
                                        color: AppTheme.accent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ],
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
}
