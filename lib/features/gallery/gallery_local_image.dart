import 'dart:io';

import 'package:flutter/material.dart';

Widget galleryLocalImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  required Widget fallback,
}) {
  final file = File(path);
  if (!file.existsSync()) return fallback;
  return Image.file(file, fit: fit, errorBuilder: (context, error, stackTrace) => fallback);
}
