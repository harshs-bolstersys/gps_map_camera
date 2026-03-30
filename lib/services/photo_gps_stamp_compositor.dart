import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../core/constants/app_colors.dart';
import '../models/app_models.dart';

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
  }) async {
    ui.Image? decoded;
    ui.Image? stamp;
    ui.Image? composed;
    try {
      final bytes = await File(jpegPath).readAsBytes();
      decoded = await _decodeImage(bytes);
      if (decoded == null) return;

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
      );
      if (stamp == null) return;

      composed = await _compositeUnder(decoded, stamp, marginH, marginB);
      decoded.dispose();
      decoded = null;
      stamp.dispose();
      stamp = null;

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

  static Future<ui.Image> _compositeUnder(ui.Image photo, ui.Image stamp, double marginH, double marginB) async {
    final ox = marginH;
    final oy = photo.height - marginB - stamp.height;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(photo, Offset.zero, Paint());
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
    double? altitude,
    double? accuracy,
    double? compassBearing,
  }) async {
    if (width < 120) return null;

    final ls = (width / 360.0).clamp(0.85, 4.0);
    final mapW = (62 * ls).roundToDouble();
    final padSide = 10 * ls;
    final padV = 8 * ls;
    final textMaxW = width - mapW - 2 * padSide;
    if (textMaxW < 48) return null;

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${capturedAt.day.toString().padLeft(2, '0')}/${months[capturedAt.month - 1]}/${capturedAt.year}';
    final tz = capturedAt.timeZoneOffset;
    final timeStr =
        '${capturedAt.hour.toString().padLeft(2, '0')}:${capturedAt.minute.toString().padLeft(2, '0')} '
        'GMT${tz.isNegative ? '-' : '+'}${tz.inHours.abs().toString().padLeft(2, '0')}:00';

    final coordLine = 'Lat ${location.latitude.toStringAsFixed(6)}°  Long ${location.longitude.toStringAsFixed(6)}°';

    double y = padV;
    final x0 = mapW + padSide;

    final brandBox = 14.0 * ls;
    final brandLabel = TextPainter(
      text: TextSpan(
        text: 'GPS Map Camera',
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
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: textMaxW);
    y += addrPainter.height + 3 * ls;

    final coordPainter = TextPainter(
      text: TextSpan(
        text: coordLine,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9 * ls),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textMaxW);
    y += coordPainter.height + 2 * ls;

    final datePainter = TextPainter(
      text: TextSpan(
        text: '$dateStr  $timeStr',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9 * ls),
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
    canvas.drawRRect(bgRRect, Paint()..color = const Color(0xD1000000));
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
    canvas.drawRect(Rect.fromLTWH(0, 0, mapW, stampH.toDouble()), Paint()..color = const Color(0xFF2D4A3E));
    _paintMapGrid(canvas, Size(mapW, stampH.toDouble()));
    canvas.restore();

    _paintMapPin(canvas, Offset(mapW / 2, stampH / 2), ls);

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

  static void _paintMapGrid(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 10) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }
    final road = Paint()..color = Colors.white.withValues(alpha: 0.18);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.35, 0, size.width * 0.12, size.height), road);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.1), road);
  }

  static void _paintMapPin(Canvas canvas, Offset center, double ls) {
    final pinR = 9 * ls;
    canvas.drawCircle(center.translate(0, -3 * ls), pinR, Paint()..color = Colors.red);
    _paintMaterialIcon(canvas, Icons.location_on, Colors.white, 12 * ls, center.translate(-6 * ls, -3 * ls - 6 * ls));
    canvas.drawRect(
      Rect.fromCenter(center: center.translate(0, 6 * ls), width: 2 * ls, height: 6 * ls),
      Paint()..color = Colors.red,
    );
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
