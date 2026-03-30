import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import 'storage_services.dart';

/// Persists gallery metadata via [SharedPrefHelper] and image files on disk.
class GalleryLocalStorage {
  GalleryLocalStorage._();

  static const _photosJsonKey = 'geo_gallery_photos_json_v1';
  static const _capturesSubdir = 'gps_map_captures';

  static Future<List<GeoPhoto>> loadPhotos() async {
    await SharedPrefHelper.init();
    final raw = await SharedPrefHelper.getString(_photosJsonKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => GeoPhoto.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e, st) {
      debugPrint('GalleryLocalStorage.loadPhotos: $e\n$st');
      return [];
    }
  }

  static Future<void> persistPhotos(List<GeoPhoto> photos) async {
    await SharedPrefHelper.init();
    final encoded = jsonEncode(photos.map((p) => p.toJson()).toList());
    await SharedPrefHelper.setString(_photosJsonKey, encoded);
  }

  /// Copies the camera temp file into a private app folder under [Directory.systemTemp].
  ///
  /// This does not use the system Photos gallery and avoids [path_provider], which on some
  /// iOS setups can fail when its Foundation FFI / native assets are unavailable.
  static Future<String> copyCaptureToAppDirectory(String tempPath) async {
    final folder = Directory('${Directory.systemTemp.path}/$_capturesSubdir');
    if (!await folder.exists()) await folder.create(recursive: true);
    final name = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final dest = File('${folder.path}/$name');
    await File(tempPath).copy(dest.path);
    return dest.path;
  }

  static Future<void> deletePhotoFiles(GeoPhoto photo) async {
    try {
      final f = File(photo.filePath);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('GalleryLocalStorage.deletePhotoFiles main: $e');
    }
    final orig = photo.originalFilePath;
    if (orig == null || orig.isEmpty) return;
    try {
      final f = File(orig);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('GalleryLocalStorage.deletePhotoFiles original: $e');
    }
  }
}
