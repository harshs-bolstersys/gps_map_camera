// ─── GPS / Location ───────────────────────────────────────────────────────────

class GpsCoordinate {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;

  const GpsCoordinate({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
  });

  String get latDMS {
    final d = latitude.abs().floor();
    final m = ((latitude.abs() - d) * 60).floor();
    final s = (((latitude.abs() - d) * 60 - m) * 60);
    final dir = latitude >= 0 ? 'N' : 'S';
    return '$d°$m\'${s.toStringAsFixed(1)}"$dir';
  }

  String get lngDMS {
    final d = longitude.abs().floor();
    final m = ((longitude.abs() - d) * 60).floor();
    final s = (((longitude.abs() - d) * 60 - m) * 60);
    final dir = longitude >= 0 ? 'E' : 'W';
    return '$d°$m\'${s.toStringAsFixed(1)}"$dir';
  }

  String get decimal =>
      '${latitude.toStringAsFixed(6)}°, ${longitude.toStringAsFixed(6)}°';

  @override
  String toString() => decimal;
}

// ─── Stamp Configuration ──────────────────────────────────────────────────────

enum MapType { normal, satellite, terrain, hybrid }

enum CoordinateFormat { decimal, dms }

enum DateFormat {
  ddMMyyyy,
  mmDDyyyy,
  yyyyMMdd,
  longFormat,
}

enum TimeFormat { h12, h24 }

enum StampPosition { bottomLeft, bottomRight, topLeft, topRight }

class StampConfig {
  final bool showLocation;
  final bool showCoordinates;
  final bool showMap;
  final bool showDate;
  final bool showTime;
  final bool showAltitude;
  final bool showAccuracy;
  final bool showCompass;
  final bool showAddress;
  final bool showLogo;
  final bool showNote;
  final bool showPersonName;
  final bool showContactNumber;
  final MapType mapType;
  final CoordinateFormat coordinateFormat;
  final DateFormat dateFormat;
  final TimeFormat timeFormat;
  final StampPosition stampPosition;
  final String? logoPath;
  final String? note;
  final String? personName;
  final String? contactNumber;
  final double mapZoom;

  const StampConfig({
    this.showLocation = true,
    this.showCoordinates = true,
    this.showMap = true,
    this.showDate = true,
    this.showTime = true,
    this.showAltitude = false,
    this.showAccuracy = false,
    this.showCompass = false,
    this.showAddress = true,
    this.showLogo = false,
    this.showNote = false,
    this.showPersonName = false,
    this.showContactNumber = false,
    this.mapType = MapType.normal,
    this.coordinateFormat = CoordinateFormat.decimal,
    this.dateFormat = DateFormat.ddMMyyyy,
    this.timeFormat = TimeFormat.h24,
    this.stampPosition = StampPosition.bottomLeft,
    this.logoPath,
    this.note,
    this.personName,
    this.contactNumber,
    this.mapZoom = 14.0,
  });

  StampConfig copyWith({
    bool? showLocation,
    bool? showCoordinates,
    bool? showMap,
    bool? showDate,
    bool? showTime,
    bool? showAltitude,
    bool? showAccuracy,
    bool? showCompass,
    bool? showAddress,
    bool? showLogo,
    bool? showNote,
    bool? showPersonName,
    bool? showContactNumber,
    MapType? mapType,
    CoordinateFormat? coordinateFormat,
    DateFormat? dateFormat,
    TimeFormat? timeFormat,
    StampPosition? stampPosition,
    String? logoPath,
    String? note,
    String? personName,
    String? contactNumber,
    double? mapZoom,
  }) {
    return StampConfig(
      showLocation: showLocation ?? this.showLocation,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      showMap: showMap ?? this.showMap,
      showDate: showDate ?? this.showDate,
      showTime: showTime ?? this.showTime,
      showAltitude: showAltitude ?? this.showAltitude,
      showAccuracy: showAccuracy ?? this.showAccuracy,
      showCompass: showCompass ?? this.showCompass,
      showAddress: showAddress ?? this.showAddress,
      showLogo: showLogo ?? this.showLogo,
      showNote: showNote ?? this.showNote,
      showPersonName: showPersonName ?? this.showPersonName,
      showContactNumber: showContactNumber ?? this.showContactNumber,
      mapType: mapType ?? this.mapType,
      coordinateFormat: coordinateFormat ?? this.coordinateFormat,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      stampPosition: stampPosition ?? this.stampPosition,
      logoPath: logoPath ?? this.logoPath,
      note: note ?? this.note,
      personName: personName ?? this.personName,
      contactNumber: contactNumber ?? this.contactNumber,
      mapZoom: mapZoom ?? this.mapZoom,
    );
  }
}

// ─── Captured Photo ───────────────────────────────────────────────────────────

class GeoPhoto {
  final String id;
  final String filePath;
  final String? originalFilePath;
  final GpsCoordinate coordinate;
  final String address;
  final DateTime capturedAt;
  final StampConfig stampConfig;
  final double? compassBearing;

  const GeoPhoto({
    required this.id,
    required this.filePath,
    this.originalFilePath,
    required this.coordinate,
    required this.address,
    required this.capturedAt,
    required this.stampConfig,
    this.compassBearing,
  });
}

// ─── Location (manual / saved) ────────────────────────────────────────────────

class SavedLocation {
  final String id;
  final String title;
  final GpsCoordinate coordinate;
  final String address;
  final double rangeMeters;
  final DateTime savedAt;

  const SavedLocation({
    required this.id,
    required this.title,
    required this.coordinate,
    required this.address,
    this.rangeMeters = 30,
    required this.savedAt,
  });
}

// ─── Template ─────────────────────────────────────────────────────────────────

class StampTemplate {
  final String id;
  final String name;
  final String description;
  final bool isPremium;
  final StampConfig config;

  const StampTemplate({
    required this.id,
    required this.name,
    required this.description,
    this.isPremium = false,
    required this.config,
  });
}

// ─── App Settings ─────────────────────────────────────────────────────────────

class AppSettings {
  final bool saveOriginalPhoto;
  final bool autoSaveToGallery;
  final String defaultFolderName;
  final bool soundEnabled;
  final bool timerEnabled;
  final int timerSeconds;
  final bool gridEnabled;
  final bool frontCamera;
  final bool flashEnabled;
  final bool mirrorEnabled;

  const AppSettings({
    this.saveOriginalPhoto = false,
    this.autoSaveToGallery = true,
    this.defaultFolderName = 'GPS Map Camera',
    this.soundEnabled = true,
    this.timerEnabled = false,
    this.timerSeconds = 3,
    this.gridEnabled = false,
    this.frontCamera = false,
    this.flashEnabled = false,
    this.mirrorEnabled = false,
  });

  AppSettings copyWith({
    bool? saveOriginalPhoto,
    bool? autoSaveToGallery,
    String? defaultFolderName,
    bool? soundEnabled,
    bool? timerEnabled,
    int? timerSeconds,
    bool? gridEnabled,
    bool? frontCamera,
    bool? flashEnabled,
    bool? mirrorEnabled,
  }) {
    return AppSettings(
      saveOriginalPhoto: saveOriginalPhoto ?? this.saveOriginalPhoto,
      autoSaveToGallery: autoSaveToGallery ?? this.autoSaveToGallery,
      defaultFolderName: defaultFolderName ?? this.defaultFolderName,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      gridEnabled: gridEnabled ?? this.gridEnabled,
      frontCamera: frontCamera ?? this.frontCamera,
      flashEnabled: flashEnabled ?? this.flashEnabled,
      mirrorEnabled: mirrorEnabled ?? this.mirrorEnabled,
    );
  }
}
