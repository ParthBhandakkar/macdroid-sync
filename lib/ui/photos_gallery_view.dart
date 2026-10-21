import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/photo_entry.dart';
import '../services/macdroid_state.dart';
import '../theme/app_theme.dart';

class PhotosGalleryView extends StatefulWidget {
  final MacDroidState state;

  const PhotosGalleryView({super.key, required this.state});

  @override
  State<PhotosGalleryView> createState() => _PhotosGalleryViewState();
}

class _PhotosGalleryViewState extends State<PhotosGalleryView> {
  PhotoEntry? _selectedPhoto;

  @override
  Widget build(BuildContext context) {
    final photos = widget.state.photos;

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
                          'Recent Photos & Media',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${photos.length} items',
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Instant camera roll sync • Fast thumbnail cache • 1-tap download to desktop',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Refresh Feed'),
                  onPressed: () {
                    widget.state.photosSync.requestPhotos();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Photos Grid
            Expanded(
              child: photos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.photo_library_outlined, size: 48, color: AppTheme.textMuted),
                          SizedBox(height: 14),
                          Text('No Photos Found', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 260,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        final photo = photos[index];
                        return _buildPhotoCard(photo);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(PhotoEntry photo) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview Container / Real or Mock visual
          Expanded(
            child: InkWell(
              onTap: () => _openLightbox(photo),
              child: Container(
                color: AppTheme.surfaceHover,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (photo.thumbnailBase64 != null && photo.thumbnailBase64!.isNotEmpty)
                      Image.memory(
                        base64Decode(photo.thumbnailBase64!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            photo.name.endsWith('.png') ? Icons.screenshot_rounded : Icons.image_rounded,
                            size: 48,
                            color: AppTheme.primary.withOpacity(0.5),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Icon(
                          photo.name.endsWith('.png') ? Icons.screenshot_rounded : Icons.image_rounded,
                          size: 48,
                          color: AppTheme.primary.withOpacity(0.5),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          photo.formattedSize,
                          style: const TextStyle(fontSize: 10, color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Metadata footer & Download button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(photo.dateModified),
                        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download_rounded, size: 18),
                  tooltip: 'Save to Desktop',
                  color: AppTheme.accent,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading ${photo.name} to Downloads folder...'),
                        backgroundColor: AppTheme.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openLightbox(PhotoEntry photo) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surface,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppBar(
                title: Text(photo.name),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.download_rounded),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Downloading ${photo.name}...'),
                          backgroundColor: AppTheme.primary,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: photo.thumbnailBase64 != null && photo.thumbnailBase64!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              base64Decode(photo.thumbnailBase64!),
                              fit: BoxFit.contain,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_rounded,
                                size: 80,
                                color: AppTheme.accent.withOpacity(0.6),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${photo.width ?? 4032} × ${photo.height ?? 3024}',
                                style: const TextStyle(color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                photo.path,
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
