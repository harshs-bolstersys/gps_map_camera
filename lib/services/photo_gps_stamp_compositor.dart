import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gps_map_camera/core/constants/image_constant.dart';
import 'package:image/image.dart' as img;
import 'package:gps_map_camera/core/constants/app_colors.dart';
import 'package:gps_map_camera/models/app_models.dart';

/// Draws the same GPS stamp as the camera preview onto a JPEG after capture.
class PhotoGpsStampCompositor {
  PhotoGpsStampCompositor._();

  static Future<void> compositeOntoFileIfPossible({
    required String jpegPath,
    required GpsCoordinate location,
    required String address,
    required DateTime capturedAt,
    required StampConfig stampConfig,
    double? altitude,
    double? accuracy,
    double? compassBearing,
    bool flipHorizontally = false,
  }) async {
    ui.Image? decoded;
    ui.Image? stamp;
    ui.Image? composed;
    ui.Image? mapAssetImage;

    try {
      final bytes = await File(jpegPath).readAsBytes();
      decoded = await _decodeImage(bytes);
      if (decoded == null) return;

      // Load the map background image from constants
      try {
        final Uint8List mapBytes = (await rootBundle.load(ImageConstants.googleMapImg)).buffer.asUint8List();
        mapAssetImage = await _decodeImage(mapBytes);
      } catch (e) {
        debugPrint("Could not load map asset: $e");
      }

      final scaleRef = decoded.width / 390.0;
      final marginH = (10 * scaleRef).clamp(8.0, decoded.width / 3.0);
      final marginB = (12 * scaleRef).clamp(8.0, decoded.height / 3.0);
      final stampW = (decoded.width - 2 * marginH).round();

      stamp = await _renderStamp(
        width: stampW,
        location: location,
        address: address,
        capturedAt: capturedAt,
        stampConfig: stampConfig,
        altitude: altitude,
        accuracy: accuracy,
        compassBearing: compassBearing,
        mapImage: mapAssetImage, // Pass the image here
      );
      if (stamp == null) return;

      composed = await _compositeUnder(decoded, stamp, marginH, marginB, flipHorizontally: flipHorizontally);

      // Cleanup early
      decoded.dispose();
      decoded = null;
      stamp.dispose();
      stamp = null;
      mapAssetImage?.dispose();
      mapAssetImage = null;

      final jpg = await _encodeJpeg(composed);
      composed.dispose();
      composed = null;

      await File(jpegPath).writeAsBytes(jpg, flush: true);
    } catch (e, st) {
      debugPrint('PhotoGpsStampCompositor: $e\n$st');
    } finally {
      decoded?.dispose();
      stamp?.dispose();
      composed?.dispose();
      mapAssetImage?.dispose();
    }
  }

  static Future<ui.Image?> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  static Future<ui.Image> _compositeUnder(
    ui.Image photo,
    ui.Image stamp,
    double marginH,
    double marginB, {
    required bool flipHorizontally,
  }) async {
    final ox = marginH;
    final oy = photo.height - marginB - stamp.height;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.save();
    if (flipHorizontally) {
      canvas.translate(photo.width.toDouble(), 0);
      canvas.scale(-1.0, 1.0);
    }
    canvas.drawImage(photo, Offset.zero, Paint());
    canvas.restore();

    canvas.drawImage(stamp, Offset(ox, oy), Paint());
    final picture = recorder.endRecording();
    final out = await picture.toImage(photo.width, photo.height);
    picture.dispose();
    return out;
  }

  static Future<Uint8List> _encodeJpeg(ui.Image image) async {
    final bd = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bd == null) throw StateError('rawRgba failed');
    final lib = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: bd.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    return Uint8List.fromList(img.encodeJpg(lib, quality: 92));
  }

  static Future<ui.Image?> _renderStamp({
    required int width,
    required GpsCoordinate location,
    required String address,
    required DateTime capturedAt,
    required StampConfig stampConfig,
    ui.Image? mapImage, // Added parameter
    double? altitude,
    double? accuracy,
    double? compassBearing,
  }) async {
    if (width < 120) return null;

    final ls = (width / 360.0).clamp(0.85, 4.0);
    final mapW = (75 * ls).roundToDouble();
    final padSide = 10 * ls;
    final padV = 8 * ls;
    final textMaxW = width - mapW - 2 * padSide;
    if (textMaxW < 48) return null;

    final months = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];
    final dateStr = '${capturedAt.day.toString().padLeft(2, '0')} ${months[capturedAt.month - 1]}, ${capturedAt.year}';
    final amPm = capturedAt.hour >= 12 ? 'PM' : 'AM';
    final hour12 = (capturedAt.hour % 12 == 0) ? 12 : capturedAt.hour % 12;
    final timeStr = '$hour12:${capturedAt.minute.toString().padLeft(2, '0')} $amPm';
    final coordLine = 'Lat: ${location.latitude}°  Long: ${location.longitude}°';

    double y = padV;
    final x0 = mapW + padSide;

    final brandBox = 14.0 * ls;
    final brandLabel = TextPainter(
      text: TextSpan(
        text: 'GPS CAM',
        style: TextStyle(color: AppColors.primary, fontSize: 9 * ls, fontWeight: FontWeight.w700, letterSpacing: 0.3),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textMaxW - brandBox - 4 * ls);
    final row0 = (brandBox > brandLabel.height ? brandBox : brandLabel.height);
    y += row0 + 4 * ls;

    final addrPainter = TextPainter(
      text: TextSpan(
        text: address,
        style: TextStyle(color: Colors.white, fontSize: 11 * ls, fontWeight: FontWeight.w700, height: 1.2),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textMaxW);
    y += addrPainter.height + 3 * ls;

    final coordPainter = TextPainter(
      text: TextSpan(
        text: coordLine,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 9 * ls),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textMaxW);
    y += coordPainter.height + 2 * ls;

    final datePainter = TextPainter(
      text: TextSpan(
        text: 'DateTime: $dateStr - $timeStr',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 9 * ls),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textMaxW);
    y += datePainter.height;

    TextPainter? altPainter;
    if (stampConfig.showAltitude && altitude != null) {
      y += 2 * ls;
      altPainter = TextPainter(
        text: TextSpan(
          text: 'Alt: ${altitude.toStringAsFixed(1)}m  ±${accuracy?.toStringAsFixed(1) ?? '--'}m',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9 * ls),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: textMaxW);
      y += altPainter.height;
    }

    double? compassTextY;
    TextPainter? compassPainter;
    if (stampConfig.showCompass && compassBearing != null) {
      y += 2 * ls;
      compassTextY = y;
      final b = compassBearing;
      compassPainter = TextPainter(
        text: TextSpan(
          text: '${b.toStringAsFixed(0)}° ${_bearingLabel(b)}',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9 * ls),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: textMaxW - 14 * ls);
      y += compassPainter.height;
    }

    y += padV;
    final stampH = (y.ceil()).clamp((72 * ls).round(), 10000);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final bgRRect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, width.toDouble(), stampH.toDouble()), Radius.circular(10 * ls));
    canvas.drawRRect(bgRRect, Paint()..color = Colors.black.withOpacity(0.5));
    canvas.drawRRect(
      bgRRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final mapClip = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, mapW, stampH.toDouble()),
      topLeft: Radius.circular(10 * ls),
      bottomLeft: Radius.circular(10 * ls),
    );

    canvas.save();
    canvas.clipRRect(mapClip);

    // IMAGE REPLACEMENT LOGIC
    if (mapImage != null) {
      // Draw the asset image scaled to fill the map area
      canvas.drawImageRect(
        mapImage,
        Rect.fromLTWH(0, 0, mapImage.width.toDouble(), mapImage.height.toDouble()),
        Rect.fromLTWH(0, 0, mapW, stampH.toDouble()),
        Paint()..filterQuality = ui.FilterQuality.high,
      );
    } else {
      // Fallback color if image fails to load
      canvas.drawRect(Rect.fromLTWH(0, 0, mapW, stampH.toDouble()), Paint()..color = const Color(0xFF2D4A3E));
    }
    canvas.restore();

    final centerIconSize = 20 * ls;
    _paintMaterialIcon(
      canvas,
      Icons.location_on,
      Colors.red,
      centerIconSize,
      Offset((mapW - centerIconSize) / 2, (stampH - centerIconSize) / 2),
    );

    var ty = padV;
    final brandPrimary = RRect.fromRectAndRadius(
      Rect.fromLTWH(x0, ty + (row0 - brandBox) / 2, brandBox, brandBox),
      Radius.circular(3 * ls),
    );
    canvas.drawRRect(brandPrimary, Paint()..color = AppColors.primary);
    _paintMaterialIcon(
      canvas,
      Icons.camera_alt,
      Colors.white,
      9 * ls,
      Offset(x0 + (brandBox - 9 * ls) / 2, ty + (row0 - 9 * ls) / 2),
    );

    brandLabel.paint(canvas, Offset(x0 + brandBox + 4 * ls, ty + (row0 - brandLabel.height) / 2));
    ty += row0 + 4 * ls;
    addrPainter.paint(canvas, Offset(x0, ty));
    ty += addrPainter.height + 3 * ls;
    coordPainter.paint(canvas, Offset(x0, ty));
    ty += coordPainter.height + 2 * ls;
    datePainter.paint(canvas, Offset(x0, ty));
    ty += datePainter.height;
    altPainter?.paint(canvas, Offset(x0, ty + 2 * ls));
    if (altPainter != null) ty += 2 * ls + altPainter.height;

    if (compassPainter != null && compassTextY != null) {
      _paintMaterialIcon(
        canvas,
        Icons.explore_rounded,
        Colors.white.withValues(alpha: 0.6),
        10 * ls,
        Offset(x0, compassTextY + (compassPainter.height - 10 * ls) / 2),
      );
      compassPainter.paint(canvas, Offset(x0 + 10 * ls + 3 * ls, compassTextY));
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, stampH);
    picture.dispose();
    return image;
  }

  static void _paintMaterialIcon(Canvas canvas, IconData icon, Color color, double size, Offset topLeft) {
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: size, color: color),
      ),
    )..layout();
    painter.paint(canvas, topLeft);
  }

  static String _bearingLabel(double deg) {
    if (deg < 22.5 || deg >= 337.5) return 'N';
    if (deg < 67.5) return 'NE';
    if (deg < 112.5) return 'E';
    if (deg < 157.5) return 'SE';
    if (deg < 202.5) return 'S';
    if (deg < 247.5) return 'SW';
    if (deg < 292.5) return 'W';
    return 'NW';
  }
}
