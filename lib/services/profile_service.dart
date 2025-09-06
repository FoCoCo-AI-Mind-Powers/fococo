import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Initialize timezone data
  static Future<void> initializeTimezones() async {
    tz_data.initializeTimeZones();
  }

  /// Upload profile image to Firebase Storage
  Future<String?> uploadProfileImage(String userId, XFile imageFile) async {
    try {
      // Create a reference to the storage location
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');

      // Upload the file
      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(await imageFile.readAsBytes());
      } else {
        uploadTask = ref.putFile(File(imageFile.path));
      }

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  /// Pick image from gallery or camera
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Get current user location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Search for golf clubs near user's location using Google Places API
  Future<List<GolfClub>> searchNearbyGolfClubs(Position position,
      {String? apiKey}) async {
    if (apiKey == null || apiKey.isEmpty) {
      // Return some default golf clubs if no API key
      return _getDefaultGolfClubs();
    }

    try {
      final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=${position.latitude},${position.longitude}'
          '&radius=50000' // 50km radius
          '&type=establishment'
          '&keyword=golf+club+course'
          '&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        return results
            .map((place) => GolfClub(
                  name: place['name'] ?? 'Unknown Golf Club',
                  address: place['vicinity'] ?? '',
                  placeId: place['place_id'] ?? '',
                  rating: (place['rating'] as num?)?.toDouble(),
                  distance: _calculateDistance(
                    position.latitude,
                    position.longitude,
                    place['geometry']['location']['lat'],
                    place['geometry']['location']['lng'],
                  ),
                ))
            .toList()
          ..sort((a, b) => a.distance.compareTo(b.distance));
      }
    } catch (e) {
      print('Error searching golf clubs: $e');
    }

    return _getDefaultGolfClubs();
  }

  /// Get timezones ordered by proximity to user's location
  Future<List<TimezoneInfo>> getTimezonesOrderedByLocation(
      Position? userPosition) async {
    await initializeTimezones();

    final allTimezones = tz.timeZoneDatabase.locations.values.toList();
    final timezoneInfos = <TimezoneInfo>[];

    for (final location in allTimezones) {
      // Skip some internal/deprecated timezones
      if (location.name.contains('Etc/') ||
          location.name.contains('SystemV/') ||
          location.name.contains('US/') ||
          location.name.contains('Canada/')) {
        continue;
      }

      final now = DateTime.now();
      final tzDateTime = tz.TZDateTime.from(now, location);
      final offset = tzDateTime.timeZoneOffset;

      double distance = double.infinity;
      if (userPosition != null) {
        // Approximate timezone center coordinates (simplified)
        final tzCoords = _getTimezoneCoordinates(location.name);
        if (tzCoords != null) {
          distance = _calculateDistance(
            userPosition.latitude,
            userPosition.longitude,
            tzCoords['lat']!,
            tzCoords['lng']!,
          );
        }
      }

      timezoneInfos.add(TimezoneInfo(
        name: location.name,
        displayName: _formatTimezoneName(location.name),
        offset: offset,
        offsetString: _formatOffset(offset),
        distance: distance,
      ));
    }

    // Sort by distance (closest first), then by name
    timezoneInfos.sort((a, b) {
      if (a.distance == double.infinity && b.distance == double.infinity) {
        return a.displayName.compareTo(b.displayName);
      }
      if (a.distance == double.infinity) return 1;
      if (b.distance == double.infinity) return -1;
      return a.distance.compareTo(b.distance);
    });

    return timezoneInfos;
  }

  /// Calculate distance between two coordinates in kilometers
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) /
        1000; // Convert to km
  }

  /// Get default golf clubs when API is not available
  List<GolfClub> _getDefaultGolfClubs() {
    return [
      GolfClub(
          name: 'Local Golf Club',
          address: 'Near you',
          placeId: '',
          distance: 0),
      GolfClub(
          name: 'City Golf Course',
          address: 'City center',
          placeId: '',
          distance: 5),
      GolfClub(
          name: 'Country Club', address: 'Suburbs', placeId: '', distance: 10),
      GolfClub(
          name: 'Municipal Golf Course',
          address: 'Public course',
          placeId: '',
          distance: 15),
    ];
  }

  /// Get approximate coordinates for major timezones
  Map<String, double>? _getTimezoneCoordinates(String timezoneName) {
    final coordinates = <String, Map<String, double>>{
      'America/New_York': {'lat': 40.7128, 'lng': -74.0060},
      'America/Los_Angeles': {'lat': 34.0522, 'lng': -118.2437},
      'America/Chicago': {'lat': 41.8781, 'lng': -87.6298},
      'America/Denver': {'lat': 39.7392, 'lng': -104.9903},
      'Europe/London': {'lat': 51.5074, 'lng': -0.1278},
      'Europe/Paris': {'lat': 48.8566, 'lng': 2.3522},
      'Europe/Berlin': {'lat': 52.5200, 'lng': 13.4050},
      'Asia/Tokyo': {'lat': 35.6762, 'lng': 139.6503},
      'Asia/Shanghai': {'lat': 31.2304, 'lng': 121.4737},
      'Asia/Dubai': {'lat': 25.2048, 'lng': 55.2708},
      'Australia/Sydney': {'lat': -33.8688, 'lng': 151.2093},
      'Pacific/Auckland': {'lat': -36.8485, 'lng': 174.7633},
    };

    return coordinates[timezoneName];
  }

  /// Format timezone name for display
  String _formatTimezoneName(String timezoneName) {
    final parts = timezoneName.split('/');
    if (parts.length >= 2) {
      final city = parts.last.replaceAll('_', ' ');
      final region = parts[parts.length - 2];
      return '$city ($region)';
    }
    return timezoneName.replaceAll('_', ' ');
  }

  /// Format timezone offset
  String _formatOffset(Duration offset) {
    final hours = offset.inHours;
    final minutes = offset.inMinutes.remainder(60).abs();
    final sign = hours >= 0 ? '+' : '-';
    return 'UTC$sign${hours.abs().toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}

/// Golf club model
class GolfClub {
  final String name;
  final String address;
  final String placeId;
  final double? rating;
  final double distance;

  GolfClub({
    required this.name,
    required this.address,
    required this.placeId,
    this.rating,
    required this.distance,
  });

  @override
  String toString() => name;
}

/// Timezone info model
class TimezoneInfo {
  final String name;
  final String displayName;
  final Duration offset;
  final String offsetString;
  final double distance;

  TimezoneInfo({
    required this.name,
    required this.displayName,
    required this.offset,
    required this.offsetString,
    required this.distance,
  });

  @override
  String toString() => '$displayName $offsetString';
}
