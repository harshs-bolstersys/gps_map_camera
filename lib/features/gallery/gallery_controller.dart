// gallery_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gps_map_camera/models/app_models.dart';
import 'package:gps_map_camera/services/gallery_local_storage.dart';

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
    _initialLoad = _load();
  }

  /// First disk read; [addPhoto] / [deletePhoto] must wait so they never race with
  /// [_load] finishing and overwriting in-memory state with a stale list.
  late final Future<void> _initialLoad;

  Future<void> _load() async {
    final photos = await GalleryLocalStorage.loadPhotos();
    final existing = await GalleryLocalStorage.removeMissingFiles(photos);
    if (existing.length != photos.length) {
      await GalleryLocalStorage.persistPhotos(existing);
    }
    state = state.copyWith(photos: existing, isLoading: false);
  }

  void selectPhoto(GeoPhoto photo) => state = state.copyWith(selectedPhoto: photo);
  void clearSelection() => state = GalleryState(photos: state.photos);
  Future<void> addPhoto(GeoPhoto photo) async {
    await _initialLoad;
    final next = [photo, ...state.photos];
    state = state.copyWith(photos: next);
    await GalleryLocalStorage.persistPhotos(next);
  }

  Future<void> deletePhoto(String id) async {
    await _initialLoad;
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
