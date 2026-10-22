import 'package:flutter/foundation.dart';
import '../models/photo_entry.dart';
import '../protocols/macdroid_protocol.dart';
import 'native_platform_service.dart';

class PhotosSyncService {
  final void Function(String messageJson) sendMessage;
  final VoidCallback onStateUpdated;

  final List<PhotoEntry> _photos = [];
  bool _isLoading = false;

  PhotosSyncService({
    required this.sendMessage,
    required this.onStateUpdated,
  }) {
    if (NativePlatformService.isAndroid) {
      NativePlatformService.getRecentPhotos(limit: 40).then((real) {
        if (real.isNotEmpty) {
          handleIncomingPhotos(real);
        } else {
          _populateDefaultPhotos();
        }
      });
    } else {
      _populateDefaultPhotos();
    }
  }

  List<PhotoEntry> get photos => List.unmodifiable(_photos);
  bool get isLoading => _isLoading;

  Future<void> requestPhotos() async {
    _isLoading = true;
    onStateUpdated();
    if (NativePlatformService.isAndroid) {
      final real = await NativePlatformService.getRecentPhotos(limit: 40);
      if (real.isNotEmpty) {
        handleIncomingPhotos(real);
        return;
      }
    }
    sendMessage(MacDroidProtocol.createPhotosListRequest());
  }

  void handleIncomingPhotos(List<PhotoEntry> incoming) {
    _isLoading = false;
    _photos.clear();
    _photos.addAll(incoming);
    onStateUpdated();
  }

  void _populateDefaultPhotos() {
    final now = DateTime.now();
    _photos.addAll([
      PhotoEntry(
        id: 'img-101',
        name: 'IMG_20261021_Sunset.jpg',
        path: '/storage/emulated/0/DCIM/Camera/IMG_20261021_Sunset.jpg',
        sizeBytes: 4210000,
        dateModified: now.subtract(const Duration(minutes: 12)),
        width: 4032,
        height: 3024,
      ),
      PhotoEntry(
        id: 'img-102',
        name: 'Screenshot_20261021-1430.png',
        path: '/storage/emulated/0/Pictures/Screenshots/Screenshot_20261021-1430.png',
        sizeBytes: 1840000,
        dateModified: now.subtract(const Duration(minutes: 45)),
        width: 1080,
        height: 2400,
      ),
      PhotoEntry(
        id: 'img-103',
        name: 'PXL_Mountain_Trip.jpg',
        path: '/storage/emulated/0/DCIM/Camera/PXL_Mountain_Trip.jpg',
        sizeBytes: 6720000,
        dateModified: now.subtract(const Duration(hours: 3)),
        width: 4032,
        height: 3024,
      ),
      PhotoEntry(
        id: 'img-104',
        name: 'Document_Receipt_Scan.jpg',
        path: '/storage/emulated/0/Documents/Document_Receipt_Scan.jpg',
        sizeBytes: 2190000,
        dateModified: now.subtract(const Duration(hours: 6)),
        width: 3024,
        height: 4032,
      ),
      PhotoEntry(
        id: 'img-105',
        name: 'Design_Wireframe_Export.png',
        path: '/storage/emulated/0/Download/Design_Wireframe_Export.png',
        sizeBytes: 890000,
        dateModified: now.subtract(const Duration(days: 1)),
        width: 1920,
        height: 1080,
      ),
      PhotoEntry(
        id: 'img-106',
        name: 'IMG_Family_Dinner.jpg',
        path: '/storage/emulated/0/DCIM/Camera/IMG_Family_Dinner.jpg',
        sizeBytes: 5410000,
        dateModified: now.subtract(const Duration(days: 2)),
        width: 4032,
        height: 3024,
      ),
    ]);
  }
}
