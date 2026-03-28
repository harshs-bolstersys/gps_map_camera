// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:gps_map_camera/services/storage_services.dart';

// final locationControllerProvider = NotifierProvider<LocationController, Position?>(LocationController.new);

// class LocationController extends Notifier<Position?> {
//   // Public keys for accessing SharedPreferences location data
//   static const latitudeKey = 'latitude';
//   static const longitudeKey = 'longitude';
//   static const _locationPermissionKey = 'location_permission_granted';
//   static const cityKey = 'city';
//   static const stateKey = 'state';
//   static const _isManuallySelectedKey = 'is_location_manually_selected';

//   // Keep private keys for backward compatibility
//   static const _latitudeKey = latitudeKey;
//   static const _longitudeKey = longitudeKey;
//   static const _cityKey = cityKey;
//   static const _stateKey = stateKey;

//   @override
//   Position? build() {
//     return null; // start with null
//   }

//   Future<Position?> loadCachedLocation() async {
//     final lat = await SharedPrefHelper.getString(_latitudeKey);
//     final lng = await SharedPrefHelper.getString(_longitudeKey);
//     final city = await SharedPrefHelper.getString(_cityKey);
//     final stateName = await SharedPrefHelper.getString(_stateKey);

//     if (lat != null && lng != null) {
//       log(
//         "LocationController: Cached Location ------------------------------------------------> Lat: $lat, Lng: $lng, City: $city, State: $stateName",
//       );

//       final position = Position(
//         latitude: double.parse(lat),
//         longitude: double.parse(lng),
//         timestamp: DateTime.now(),
//         accuracy: 1,
//         altitude: 0,
//         heading: 0,
//         speed: 0,
//         speedAccuracy: 0,
//         altitudeAccuracy: 0,
//         headingAccuracy: 0,
//       );

//       state = position;
//       return position;
//     }
//     return null;
//   }

//   bool isReturningFromSettings = false;

//   /// Check if location was manually selected (not from GPS)
//   Future<bool> isLocationManuallySelected() async {
//     return await SharedPrefHelper.getBool(_isManuallySelectedKey) ?? false;
//   }

//   /// Set the manual selection flag
//   Future<void> setLocationManuallySelected(bool isManual) async {
//     await SharedPrefHelper.setBool(_isManuallySelectedKey, isManual);
//   }

//   Future<void> requestAndSaveLocation({BuildContext? context, int retryCount = 0, bool forceGPS = false}) async {
//     const maxRetries = 3;
//     const retryDelay = Duration(seconds: 2);

//     // If location was manually selected and we're not forcing GPS, just load cached location
//     if (!forceGPS && await isLocationManuallySelected()) {
//       log("LocationController: Location was manually selected, loading cached location instead of fetching GPS");
//       await loadCachedLocation();
//       return;
//     }

//     try {
//       final serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         log("LocationController: Location services are disabled");
//         state = null;
//         if (context != null) {
//           await showEnableLocationServicesDialog(
//             context: context,
//             onEnablePressed: () async {
//               isReturningFromSettings = true;
//               Navigator.of(context).pop();
//               await Geolocator.openLocationSettings();
//               // Do NOT recheck here; handled on resume
//             },
//           );
//         }
//         return;
//       }

//       var permission = await Geolocator.checkPermission();

//       // Case: Denied (not forever)
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           log("LocationController: Location permission denied");
//           state = null;

//           if (context != null) {
//             await showLocationPermissionDialog(
//               context: context,
//               Sure_onPressed: () async {
//                 Navigator.of(context).pop();
//                 await requestAndSaveLocation(context: context);
//               },
//               isForeverDenied: false,
//             );
//           }
//           return;
//         }
//       }

//       if (permission == LocationPermission.deniedForever) {
//         log("LocationController: Location permission denied forever");
//         state = null;
//         if (context != null) {
//           await showLocationPermissionDialog(
//             context: context,
//             Sure_onPressed: () async {
//               isReturningFromSettings = true;
//               Navigator.of(context).pop(); // Pop the dialog
//               await Geolocator.openAppSettings();
//               // Do NOT recheck here
//             },
//             isForeverDenied: true,
//           );
//         }
//         return;
//       }

//       // Case: Granted - Get location with timeout and retry logic
//       await _getLocationWithRetry(context: context, retryCount: retryCount, maxRetries: maxRetries, retryDelay: retryDelay);
//     } catch (e) {
//       log("LocationController: Error in requestAndSaveLocation: $e");
//       if (retryCount < maxRetries) {
//         log("LocationController: Retrying location request (${retryCount + 1}/$maxRetries)");
//         await Future.delayed(retryDelay);
//         await requestAndSaveLocation(context: context, retryCount: retryCount + 1);
//       } else {
//         log("LocationController: Max retries reached, falling back to cached location");
//         await loadCachedLocation();
//       }
//     }
//   }

//   Future<void> _getLocationWithRetry({
//     BuildContext? context,
//     int retryCount = 0,
//     int maxRetries = 3,
//     Duration retryDelay = const Duration(seconds: 2),
//   }) async {
//     try {
//       // Add timeout to prevent hanging
//       final pos =
//           await Geolocator.getCurrentPosition(
//             desiredAccuracy: LocationAccuracy.high,
//             timeLimit: const Duration(seconds: 15), // 15 second timeout
//           ).timeout(
//             const Duration(seconds: 20), // Overall timeout including geocoding
//             onTimeout: () {
//               throw Exception('Location request timed out');
//             },
//           );

//       // Get placemarks with error handling
//       List<Placemark> placemarks = [];
//       try {
//         placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude).timeout(const Duration(seconds: 10));
//       } catch (geocodingError) {
//         log("LocationController: Geocoding failed, using coordinates only: $geocodingError");
//         // Continue with empty placemarks - we still have coordinates
//       }

//       String city = placemarks.isNotEmpty ? (placemarks.first.locality ?? "") : "";
//       String stateName = placemarks.isNotEmpty ? (placemarks.first.administrativeArea ?? "") : "";

//       // Save to shared preferences
//       await SharedPrefHelper.setString(_latitudeKey, pos.latitude.toString());
//       await SharedPrefHelper.setString(_longitudeKey, pos.longitude.toString());
//       await SharedPrefHelper.setString(_cityKey, city);
//       await SharedPrefHelper.setString(_stateKey, stateName);
//       await SharedPrefHelper.setBool(_locationPermissionKey, true);
//       // Clear manual selection flag when getting GPS location
//       await setLocationManuallySelected(false);

//       log(
//         "LocationController: Live Location --------------------------------------------------> Lat: ${pos.latitude}, Lng: ${pos.longitude}, City: $city, State: $stateName",
//       );

//       state = pos;
//     } catch (e) {
//       log("LocationController: Error getting location (attempt ${retryCount + 1}): $e");

//       // Check if it's a DeadObjectException or similar recoverable error
//       if (e.toString().contains('DeadObjectException') ||
//           e.toString().contains('IO_ERROR') ||
//           e.toString().contains('Service not available')) {
//         if (retryCount < maxRetries) {
//           log("LocationController: Recoverable error detected, retrying in ${retryDelay.inSeconds}s...");
//           await Future.delayed(retryDelay);
//           await _getLocationWithRetry(
//             context: context,
//             retryCount: retryCount + 1,
//             maxRetries: maxRetries,
//             retryDelay: retryDelay,
//           );
//         } else {
//           log("LocationController: Max retries reached for location request, using cached location");
//           await loadCachedLocation();
//         }
//       } else {
//         // Non-recoverable error, use cached location
//         log("LocationController: Non-recoverable error, using cached location");
//         await loadCachedLocation();
//       }
//     }
//   }

//   Future<bool?> isPermissionGranted() async {
//     return SharedPrefHelper.getBool(_locationPermissionKey);
//   }

//   /// Method to handle app lifecycle changes and recover from DeadObjectException
//   Future<void> handleAppResume({BuildContext? context}) async {
//     if (isReturningFromSettings) {
//       isReturningFromSettings = false;
//       // Add a small delay to ensure the system is ready
//       await Future.delayed(const Duration(milliseconds: 500));
//       // Force GPS fetch when returning from settings (user explicitly enabled location)
//       await requestAndSaveLocation(context: context, forceGPS: true);
//     } else {
//       // On normal app resume, check if location was manually selected
//       // If yes, just load cached location; if no, try to get fresh GPS
//       final isManual = await isLocationManuallySelected();
//       if (isManual) {
//         log("LocationController: App resumed with manually selected location, loading cached location");
//         await loadCachedLocation();
//       } else {
//         // Only fetch fresh GPS if location wasn't manually selected
//         await requestAndSaveLocation(context: context, forceGPS: false);
//       }
//     }
//   }

//   /// Method to safely get location with fallback to cached location
//   Future<Position?> getLocationSafely({BuildContext? context, bool forceGPS = false}) async {
//     try {
//       // First try to get fresh location (respects manual selection flag unless forceGPS is true)
//       await requestAndSaveLocation(context: context, forceGPS: forceGPS);
//       return state;
//     } catch (e) {
//       log("LocationController: Failed to get fresh location, using cached: $e");
//       // Fallback to cached location
//       return await loadCachedLocation();
//     }
//   }
// }
