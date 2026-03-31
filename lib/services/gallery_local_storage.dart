import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:gps_map_camera/models/app_models.dart';
import 'package:path_provider/path_provider.dart';
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

  static Future<Directory> _ensureCaptureDirectory() async {
    try {
      final base = await getApplicationDocumentsDirectory();
      final folder = Directory('${base.path}/$_capturesSubdir');
      if (!await folder.exists()) await folder.create(recursive: true);
      return folder;
    } catch (e, st) {
      // Fallback keeps capture working even if path_provider fails unexpectedly.
      debugPrint('GalleryLocalStorage._ensureCaptureDirectory fallback: $e\n$st');
      final folder = Directory('${Directory.systemTemp.path}/$_capturesSubdir');
      if (!await folder.exists()) await folder.create(recursive: true);
      return folder;
    }
  }

  /// Copies the camera temp file into a private app folder under application documents.
  /// This path is app-owned and survives normal cache/temp cleanup.
  static Future<String> copyCaptureToAppDirectory(String tempPath) async {
    final folder = await _ensureCaptureDirectory();
    final name = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final dest = File('${folder.path}/$name');
    await File(tempPath).copy(dest.path);
    return dest.path;
  }

  static Future<List<GeoPhoto>> removeMissingFiles(List<GeoPhoto> photos) async {
    final existing = <GeoPhoto>[];
    for (final photo in photos) {
      final file = File(photo.filePath);
      if (await file.exists()) {
        existing.add(photo);
      }
    }
    return existing;
  }

  /// Best-effort backup to the system Photos gallery.
  static Future<void> backupToSystemGallery(String filePath) async {
    try {
      await Gal.putImage(filePath, album: 'GPS Map Camera');
    } catch (e, st) {
      debugPrint('GalleryLocalStorage.backupToSystemGallery failed: $e\n$st');
    }
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
