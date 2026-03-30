// gallery_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../services/gallery_local_storage.dart';

class GalleryState {
  final List<GeoPhoto> photos;
  final bool isLoading;
  final GeoPhoto? selectedPhoto;

  const GalleryState({this.photos = const [], this.isLoading = false, this.selectedPhoto});

  GalleryState copyWith({List<GeoPhoto>? photos, bool? isLoading, GeoPhoto? selectedPhoto}) => GalleryState(
    photos: photos ?? this.photos,
    isLoading: isLoading ?? this.isLoading,
    selectedPhoto: selectedPhoto ?? this.selectedPhoto,
  );
}

class GalleryController extends StateNotifier<GalleryState> {
  GalleryController() : super(const GalleryState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    final photos = await GalleryLocalStorage.loadPhotos();
    state = state.copyWith(photos: photos, isLoading: false);
  }

  void selectPhoto(GeoPhoto photo) => state = state.copyWith(selectedPhoto: photo);
  void clearSelection() => state = GalleryState(photos: state.photos);
  Future<void> addPhoto(GeoPhoto photo) async {
    final next = [photo, ...state.photos];
    state = state.copyWith(photos: next);
    await GalleryLocalStorage.persistPhotos(next);
  }

  Future<void> deletePhoto(String id) async {
    GeoPhoto? removed;
    for (final p in state.photos) {
      if (p.id == id) {
        removed = p;
        break;
      }
    }
    final next = state.photos.where((p) => p.id != id).toList();
    state = state.copyWith(photos: next);
    await GalleryLocalStorage.persistPhotos(next);
    if (removed != null) await GalleryLocalStorage.deletePhotoFiles(removed);
  }
}

final galleryControllerProvider = StateNotifierProvider<GalleryController, GalleryState>((ref) => GalleryController());
