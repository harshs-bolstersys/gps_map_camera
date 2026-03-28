// locations_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';

class LocationsState {
  final List<SavedLocation> locations;
  final bool isAdding;

  const LocationsState({this.locations = const [], this.isAdding = false});

  LocationsState copyWith({List<SavedLocation>? locations, bool? isAdding}) =>
      LocationsState(
        locations: locations ?? this.locations,
        isAdding: isAdding ?? this.isAdding,
      );
}

class LocationsController extends StateNotifier<LocationsState> {
  LocationsController() : super(const LocationsState()) {
    _loadMock();
  }

  void _loadMock() {
    state = state.copyWith(locations: [
      SavedLocation(
        id: 'loc_1',
        title: 'Dodge St Omaha',
        coordinate: const GpsCoordinate(latitude: 41.259941, longitude: -95.990837),
        address: 'Dodge St, Omaha, NE, USA',
        rangeMeters: 30,
        savedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      SavedLocation(
        id: 'loc_2',
        title: 'Cape Canaveral Launch Pad',
        coordinate: const GpsCoordinate(latitude: 28.608537, longitude: -80.603999),
        address: 'Cape Canaveral, FL 32920, USA',
        rangeMeters: 50,
        savedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ]);
  }

  void addLocation(SavedLocation location) {
    state = state.copyWith(locations: [...state.locations, location]);
  }

  void deleteLocation(String id) {
    state = state.copyWith(locations: state.locations.where((l) => l.id != id).toList());
  }
}

final locationsControllerProvider =
    StateNotifierProvider<LocationsController, LocationsState>(
  (ref) => LocationsController(),
);
