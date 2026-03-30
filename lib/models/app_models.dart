// ─── GPS / Location ───────────────────────────────────────────────────────────

class GpsCoordinate {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;

  const GpsCoordinate({required this.latitude, required this.longitude, this.altitude, this.accuracy});

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

  String get decimal => '${latitude.toStringAsFixed(6)}°, ${longitude.toStringAsFixed(6)}°';

  @override
  String toString() => decimal;

  Map<String, dynamic> toJson() => {'latitude': latitude, 'longitude': longitude, 'altitude': altitude, 'accuracy': accuracy};

  factory GpsCoordinate.fromJson(Map<String, dynamic> json) {
    return GpsCoordinate(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
    );
  }
}

// ─── Stamp Configuration ──────────────────────────────────────────────────────

enum MapType { normal, satellite, terrain, hybrid }

enum CoordinateFormat { decimal, dms }

enum DateFormat { ddMMyyyy, mmDDyyyy, yyyyMMdd, longFormat }

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

  Map<String, dynamic> toJson() => {
    'showLocation': showLocation,
    'showCoordinates': showCoordinates,
    'showMap': showMap,
    'showDate': showDate,
    'showTime': showTime,
    'showAltitude': showAltitude,
    'showAccuracy': showAccuracy,
    'showCompass': showCompass,
    'showAddress': showAddress,
    'showLogo': showLogo,
    'showNote': showNote,
    'showPersonName': showPersonName,
    'showContactNumber': showContactNumber,
    'mapType': mapType.name,
    'coordinateFormat': coordinateFormat.name,
    'dateFormat': dateFormat.name,
    'timeFormat': timeFormat.name,
    'stampPosition': stampPosition.name,
    'logoPath': logoPath,
    'note': note,
    'personName': personName,
    'contactNumber': contactNumber,
    'mapZoom': mapZoom,
  };

  factory StampConfig.fromJson(Map<String, dynamic> json) {
    T enumByName<T extends Enum>(Iterable<T> values, String? name, T fallback) {
      if (name == null) return fallback;
      for (final v in values) {
        if (v.name == name) return v;
      }
      return fallback;
    }

    return StampConfig(
      showLocation: json['showLocation'] as bool? ?? true,
      showCoordinates: json['showCoordinates'] as bool? ?? true,
      showMap: json['showMap'] as bool? ?? true,
      showDate: json['showDate'] as bool? ?? true,
      showTime: json['showTime'] as bool? ?? true,
      showAltitude: json['showAltitude'] as bool? ?? false,
      showAccuracy: json['showAccuracy'] as bool? ?? false,
      showCompass: json['showCompass'] as bool? ?? false,
      showAddress: json['showAddress'] as bool? ?? true,
      showLogo: json['showLogo'] as bool? ?? false,
      showNote: json['showNote'] as bool? ?? false,
      showPersonName: json['showPersonName'] as bool? ?? false,
      showContactNumber: json['showContactNumber'] as bool? ?? false,
      mapType: enumByName(MapType.values, json['mapType'] as String?, MapType.normal),
      coordinateFormat: enumByName(CoordinateFormat.values, json['coordinateFormat'] as String?, CoordinateFormat.decimal),
      dateFormat: enumByName(DateFormat.values, json['dateFormat'] as String?, DateFormat.ddMMyyyy),
      timeFormat: enumByName(TimeFormat.values, json['timeFormat'] as String?, TimeFormat.h24),
      stampPosition: enumByName(StampPosition.values, json['stampPosition'] as String?, StampPosition.bottomLeft),
      logoPath: json['logoPath'] as String?,
      note: json['note'] as String?,
      personName: json['personName'] as String?,
      contactNumber: json['contactNumber'] as String?,
      mapZoom: (json['mapZoom'] as num?)?.toDouble() ?? 14.0,
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'filePath': filePath,
    'originalFilePath': originalFilePath,
    'coordinate': coordinate.toJson(),
    'address': address,
    'capturedAt': capturedAt.toIso8601String(),
    'stampConfig': stampConfig.toJson(),
    'compassBearing': compassBearing,
  };

  factory GeoPhoto.fromJson(Map<String, dynamic> json) {
    return GeoPhoto(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      originalFilePath: json['originalFilePath'] as String?,
      coordinate: GpsCoordinate.fromJson(Map<String, dynamic>.from(json['coordinate'] as Map)),
      address: json['address'] as String,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      stampConfig: StampConfig.fromJson(Map<String, dynamic>.from(json['stampConfig'] as Map)),
      compassBearing: (json['compassBearing'] as num?)?.toDouble(),
    );
  }
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
  final bool gridEnabled;
  final bool frontCamera;
  final bool flashEnabled;

  const AppSettings({
    this.saveOriginalPhoto = false,
    this.autoSaveToGallery = true,
    this.defaultFolderName = 'GPS Map Camera',
    this.gridEnabled = false,
    this.frontCamera = false,
    this.flashEnabled = false,
  });

  AppSettings copyWith({
    bool? saveOriginalPhoto,
    bool? autoSaveToGallery,
    String? defaultFolderName,
    bool? gridEnabled,
    bool? frontCamera,
    bool? flashEnabled,
  }) {
    return AppSettings(
      saveOriginalPhoto: saveOriginalPhoto ?? this.saveOriginalPhoto,
      autoSaveToGallery: autoSaveToGallery ?? this.autoSaveToGallery,
      defaultFolderName: defaultFolderName ?? this.defaultFolderName,
      gridEnabled: gridEnabled ?? this.gridEnabled,
      frontCamera: frontCamera ?? this.frontCamera,
      flashEnabled: flashEnabled ?? this.flashEnabled,
    );
  }
}
