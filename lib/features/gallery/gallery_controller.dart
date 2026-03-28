// gallery_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';

class GalleryState {
  final List<GeoPhoto> photos;
  final bool isLoading;
  final GeoPhoto? selectedPhoto;

  const GalleryState({
    this.photos = const [],
    this.isLoading = false,
    this.selectedPhoto,
  });

  GalleryState copyWith({
    List<GeoPhoto>? photos,
    bool? isLoading,
    GeoPhoto? selectedPhoto,
  }) =>
      GalleryState(
        photos: photos ?? this.photos,
        isLoading: isLoading ?? this.isLoading,
        selectedPhoto: selectedPhoto ?? this.selectedPhoto,
      );
}

class GalleryController extends StateNotifier<GalleryState> {
  GalleryController() : super(const GalleryState()) {
    _loadMockPhotos();
  }

  void _loadMockPhotos() {
    final mockPhotos = List.generate(12, (i) {
      return GeoPhoto(
        id: 'photo_$i',
        filePath: 'assets/mock_$i.jpg',
        coordinate: GpsCoordinate(
          latitude: 28.6 + (i * 0.01),
          longitude: -80.6 + (i * 0.01),
          altitude: 10.0 + i,
          accuracy: 3.0 + (i % 4),
        ),
        address: _mockAddresses[i % _mockAddresses.length],
        capturedAt: DateTime.now().subtract(Duration(hours: i * 2)),
        stampConfig: const StampConfig(),
      );
    });
    state = state.copyWith(photos: mockPhotos);
  }

  void selectPhoto(GeoPhoto photo) => state = state.copyWith(selectedPhoto: photo);
  void clearSelection() => state = GalleryState(photos: state.photos);
  void deletePhoto(String id) {
    state = state.copyWith(photos: state.photos.where((p) => p.id != id).toList());
  }

  static const _mockAddresses = [
    'West Hollywood, Florida, USA',
    'Cape Canaveral, FL 32920',
    'Miami Beach, Florida, USA',
    'Orlando Downtown, Florida',
    'Tampa Bay, Florida, USA',
    'Daytona Beach, Florida',
  ];
}

final galleryControllerProvider =
    StateNotifierProvider<GalleryController, GalleryState>(
  (ref) => GalleryController(),
);
