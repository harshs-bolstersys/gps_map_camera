// file_name_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FileNameState {
  final String pattern;
  final bool useDate;
  final bool useTime;
  final bool useLocation;
  final bool useSequence;
  final String prefix;
  final String preview;

  const FileNameState({
    this.pattern = 'GPS_{date}_{time}',
    this.useDate = true,
    this.useTime = true,
    this.useLocation = false,
    this.useSequence = false,
    this.prefix = 'GPS',
    this.preview = 'GPS_20250812_1432.jpg',
  });

  FileNameState copyWith({
    String? pattern,
    bool? useDate,
    bool? useTime,
    bool? useLocation,
    bool? useSequence,
    String? prefix,
    String? preview,
  }) =>
      FileNameState(
        pattern: pattern ?? this.pattern,
        useDate: useDate ?? this.useDate,
        useTime: useTime ?? this.useTime,
        useLocation: useLocation ?? this.useLocation,
        useSequence: useSequence ?? this.useSequence,
        prefix: prefix ?? this.prefix,
        preview: preview ?? this.preview,
      );
}

class FileNameController extends StateNotifier<FileNameState> {
  FileNameController() : super(const FileNameState());

  void _rebuild() {
    final s = state;
    final parts = <String>[s.prefix];
    if (s.useDate) parts.add('20250812');
    if (s.useTime) parts.add('1432');
    if (s.useLocation) parts.add('WestHollywood');
    if (s.useSequence) parts.add('001');
    final preview = '${parts.join("_")}.jpg';
    state = state.copyWith(preview: preview);
  }

  void setPrefix(String v) { state = state.copyWith(prefix: v); _rebuild(); }
  void toggleDate(bool v) { state = state.copyWith(useDate: v); _rebuild(); }
  void toggleTime(bool v) { state = state.copyWith(useTime: v); _rebuild(); }
  void toggleLocation(bool v) { state = state.copyWith(useLocation: v); _rebuild(); }
  void toggleSequence(bool v) { state = state.copyWith(useSequence: v); _rebuild(); }
}

final fileNameControllerProvider =
    StateNotifierProvider<FileNameController, FileNameState>(
  (ref) => FileNameController(),
);
