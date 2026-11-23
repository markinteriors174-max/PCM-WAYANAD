import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LocationResult {
  final String placeName;
  final double latitude;
  final double longitude;

  const LocationResult({
    required this.placeName,
    required this.latitude,
    required this.longitude,
  });
}

class LocationPickerHelper {
  static const String _prefApiKey = 'google_places_api_key';

  /// Pre-configured ultra-local micro-landmarks (Tea shops, Anganwadis, Junctions)
  static const List<Map<String, dynamic>> _knownLandmarks = [
    // Eranjanikunnu & Kizhakkoth Local Area
    {'name': 'Arichalil Tea Shop, Eranjanikunnu', 'lat': 11.3785, 'lng': 75.9180},
    {'name': 'Eranjanikunnu Anganwadi, Kizhakkoth', 'lat': 11.3792, 'lng': 75.9172},
    {'name': 'Eranjanikunnu, Kizhakkoth', 'lat': 11.3800, 'lng': 75.9168},
    {'name': 'Nellankandi, Kizhakkoth', 'lat': 11.3810, 'lng': 75.9150},
    {'name': 'Kizhakkoth Town', 'lat': 11.3750, 'lng': 75.9230},
    {'name': 'Parambil Bazar, Kizhakkoth', 'lat': 11.3730, 'lng': 75.9190},
    {'name': 'Adivaram Junction', 'lat': 11.4880, 'lng': 76.0120},
    {'name': 'Eangapuzha Junction', 'lat': 11.4580, 'lng': 75.9780},

    // Kalpetta & Surrounds
    {'name': 'Kainatty Junction, Kalpetta', 'lat': 11.6210, 'lng': 76.0820},
    {'name': 'Civil Station, Kalpetta', 'lat': 11.6145, 'lng': 76.0815},
    {'name': 'New Bus Stand, Kalpetta', 'lat': 11.6080, 'lng': 76.0850},
    {'name': 'Old Bus Stand, Kalpetta', 'lat': 11.6050, 'lng': 76.0870},
    {'name': 'Emily, Kalpetta', 'lat': 11.6160, 'lng': 76.0740},
    {'name': 'Pinangode Road, Kalpetta', 'lat': 11.6100, 'lng': 76.0780},
    {'name': 'Puliyarmala, Kalpetta', 'lat': 11.6310, 'lng': 76.0760},
    {'name': 'Vellaramkunnu, Kalpetta', 'lat': 11.5950, 'lng': 76.0910},
    {'name': 'Muttil Town, Wayanad', 'lat': 11.6420, 'lng': 76.1200},
    {'name': 'Edapetty, Muttil', 'lat': 11.6510, 'lng': 76.1150},
    {'name': 'Kambalakkad Town, Wayanad', 'lat': 11.6700, 'lng': 76.0720},
    {'name': 'Mandad, Kalpetta', 'lat': 11.6240, 'lng': 76.1050},

    // Sulthan Bathery & Surrounds
    {'name': 'Town Centre, Sulthan Bathery', 'lat': 11.6627, 'lng': 76.2570},
    {'name': 'Chungam Junction, Sulthan Bathery', 'lat': 11.6670, 'lng': 76.2620},
    {'name': 'Assumption Junction, Sulthan Bathery', 'lat': 11.6590, 'lng': 76.2530},
    {'name': 'Kuppady, Sulthan Bathery', 'lat': 11.6720, 'lng': 76.2730},
    {'name': 'Beenachi, Sulthan Bathery', 'lat': 11.6630, 'lng': 76.2230},
    {'name': 'Kolagappara, Wayanad', 'lat': 11.6480, 'lng': 76.1950},
    {'name': 'Meenangadi Town, Wayanad', 'lat': 11.6580, 'lng': 76.1730},
    {'name': 'Ambalavayal Town, Wayanad', 'lat': 11.6190, 'lng': 76.2160},

    // Mananthavady & Surrounds
    {'name': 'Town Centre, Mananthavady', 'lat': 11.8026, 'lng': 76.0032},
    {'name': 'Gandhi Park, Mananthavady', 'lat': 11.8040, 'lng': 76.0040},
    {'name': 'Valliyoorkavu, Mananthavady', 'lat': 11.8210, 'lng': 76.0240},
    {'name': 'Payyampally, Mananthavady', 'lat': 11.8310, 'lng': 76.0420},
    {'name': 'Dwaraka, Mananthavady', 'lat': 11.7760, 'lng': 76.0040},
    {'name': 'Panamaram Town, Wayanad', 'lat': 11.7456, 'lng': 76.0711},
    {'name': 'Vellamunda Town, Wayanad', 'lat': 11.7610, 'lng': 75.9320},

    // Meppadi & Vythiri
    {'name': 'Meppadi Town, Wayanad', 'lat': 11.5510, 'lng': 76.1260},
    {'name': 'Kottappadi, Meppadi', 'lat': 11.5620, 'lng': 76.1340},
    {'name': 'Vythiri Town, Wayanad', 'lat': 11.5514, 'lng': 76.0402},
    {'name': 'Pookode, Vythiri', 'lat': 11.5410, 'lng': 76.0280},
    {'name': 'Lakkidi, Wayanad', 'lat': 11.5170, 'lng': 76.0220},
    {'name': 'Chundale Town, Wayanad', 'lat': 11.5720, 'lng': 76.0610},
    {'name': 'Pozhuthana, Wayanad', 'lat': 11.5930, 'lng': 76.0220},
    {'name': 'Padinjarathara Town, Wayanad', 'lat': 11.6740, 'lng': 75.9620},
    {'name': 'Pulpally Town, Wayanad', 'lat': 11.7942, 'lng': 76.2796},
  ];

  /// Get stored Google Places API Key
  static Future<String?> getGoogleApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefApiKey);
    } catch (_) {
      return null;
    }
  }

  /// Save Google Places API Key
  static Future<void> saveGoogleApiKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefApiKey, key.trim());
    } catch (_) {}
  }

  /// Dialog to enter or update Google Places API Key
  static void showApiKeyDialog(BuildContext context) async {
    final currentKey = await getGoogleApiKey() ?? '';
    final textCtrl = TextEditingController(text: currentKey);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.vpn_key, color: Color(0xFF0284C7)),
            SizedBox(width: 8),
            Text('Google Places API Key', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Google Cloud Maps / Places API Key for micro-level 50m nearby search:',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await saveGoogleApiKey(textCtrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Google Places API Key saved successfully!'),
                    backgroundColor: Color(0xFF15803D),
                  ),
                );
              }
            },
            child: const Text('SAVE KEY'),
          ),
        ],
      ),
    );
  }

  /// Public utility to clean any location string of GPS numbers or unwanted ISP town names
  static String sanitizePlaceString(String raw) => _sanitizePlace(raw);

  /// Cleans raw text while strictly removing GPS numbers and non-Wayanad ISP locations
  static String _sanitizePlace(String raw) {
    String cleaned = raw
        .replaceAll(RegExp(r'\(\s*-?\d+(?:\.\d+)?\s*,\s*-?\d+(?:\.\d+)?\s*\)'), '') // remove (lat, lng)
        .replaceAll(RegExp(r'-?\d{1,3}\.\d{3,}\s*,\s*-?\d{1,3}\.\d{3,}'), '') // remove standalone coordinates
        .replaceAll(RegExp(r'GPS:?', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r',\s*,'), ',')
        .trim();

    // Strip Thrissur / Kochi / Ernakulam if returned by ISP broadband gateway
    if (cleaned.toLowerCase().contains('thrissur') || cleaned.toLowerCase().contains('തൃശൂർ')) {
      cleaned = cleaned.replaceAll(RegExp(r',?\s*thrissur', caseSensitive: false), '')
                       .replaceAll(RegExp(r',?\s*തൃശൂർ'), '').trim();
    }
    if (cleaned.toLowerCase().contains('ernakulam') || cleaned.toLowerCase().contains('kochi')) {
      cleaned = cleaned.replaceAll(RegExp(r',?\s*ernakulam', caseSensitive: false), '')
                       .replaceAll(RegExp(r',?\s*kochi', caseSensitive: false), '').trim();
    }

    // Strip redundant "Koduvally" references
    cleaned = cleaned.replaceAll(RegExp(r',?\s*Koduvally', caseSensitive: false), '').trim();

    if (cleaned.startsWith(',')) cleaned = cleaned.substring(1).trim();
    if (cleaned.endsWith(',')) cleaned = cleaned.substring(0, cleaned.length - 1).trim();
    return cleaned.isNotEmpty ? cleaned : 'Arichalil Tea Shop, Eranjanikunnu';
  }

  /// Calls Google Places Nearby Search API with a micro radius of 150m
  static Future<String?> _fetchGooglePlacesNearby(double lat, double lng, String apiKey) async {
    // 1. Google Places API (New) searchNearby
    try {
      final urlNew = Uri.parse('https://places.googleapis.com/v1/places:searchNearby');
      final response = await http.post(
        urlNew,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.shortFormattedAddress',
        },
        body: json.encode({
          'maxResultCount': 5,
          'locationRestriction': {
            'circle': {
              'center': {'latitude': lat, 'longitude': lng},
              'radius': 150.0,
            }
          }
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final places = data['places'] as List?;
        if (places != null && places.isNotEmpty) {
          final first = places[0] as Map<String, dynamic>;
          final name = first['displayName']?['text']?.toString().trim();
          final shortAddr = first['shortFormattedAddress']?.toString().trim();
          if (name != null && name.isNotEmpty) {
            if (shortAddr != null && shortAddr.isNotEmpty && !shortAddr.contains(name)) {
              return '$name, $shortAddr';
            }
            return name;
          }
        }
      }
    } catch (_) {}

    // 2. Google Places Nearby Search (Legacy)
    try {
      final legacyUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=150&rankby=prominence&key=$apiKey',
      );
      final response = await http.get(legacyUrl).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final first = results[0] as Map<String, dynamic>;
          final name = first['name']?.toString().trim();
          final vicinity = first['vicinity']?.toString().trim();
          if (name != null && name.isNotEmpty) {
            if (vicinity != null && vicinity.isNotEmpty && !vicinity.contains(name)) {
              return '$name, $vicinity';
            }
            return name;
          }
        }
      }
    } catch (_) {}

    // 3. Google Geocoding (with POI filter)
    try {
      final geocodeUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&result_type=point_of_interest|establishment|premise|sublocality&key=$apiKey',
      );
      final response = await http.get(geocodeUrl).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final first = results[0] as Map<String, dynamic>;
          final formatted = first['formatted_address']?.toString().trim();
          if (formatted != null && formatted.isNotEmpty) {
            final parts = formatted.split(',');
            if (parts.length >= 2) {
              return '${parts[0].trim()}, ${parts[1].trim()}';
            }
            return parts[0].trim();
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// BigDataCloud client-side reverse geocoder (free, instant, ultra accurate locality)
  static Future<String?> _fetchBigDataCloud(double lat, double lng) async {
    try {
      final uri = Uri.parse('https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=en');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final locality = data['locality']?.toString().trim();
        final city = data['city']?.toString().trim();
        final principalSub = data['principalSubdivision']?.toString().trim() ?? 'Kerala';
        
        String bestName = '';
        if (locality != null && locality.isNotEmpty && locality.toLowerCase() != 'koduvally') {
          bestName = locality;
        } else if (city != null && city.isNotEmpty && city.toLowerCase() != 'koduvally') {
          bestName = city;
        }

        if (bestName.toLowerCase().contains('thrissur') || bestName.toLowerCase().contains('ernakulam') || bestName.toLowerCase().contains('kochi')) {
          return null; // Reject ISP gateway locations
        }

        if (bestName.isNotEmpty) {
          return '$bestName, $principalSub';
        }
      }
    } catch (_) {}
    return null;
  }

  /// Resolves the human-readable micro-locality name without distant towns
  static Future<String> _resolveMicroPlaceName(double lat, double lng) async {
    // 1. Google Places Nearby Search (if API Key is configured)
    final googleKey = await getGoogleApiKey();
    if (googleKey != null && googleKey.isNotEmpty) {
      final googlePlace = await _fetchGooglePlacesNearby(lat, lng, googleKey);
      if (googlePlace != null && googlePlace.isNotEmpty) {
        return _sanitizePlace(googlePlace);
      }
    }

    // 2. High-precision nearest known local landmark search (TIGHT RADIUS < 300m for micro, < 650m for village)
    double closestDist = double.infinity;
    String? closestNearbyLandmark;
    for (final spot in _knownLandmarks) {
      final d = Geolocator.distanceBetween(
        lat,
        lng,
        spot['lat'] as double,
        spot['lng'] as double,
      );
      if (d < closestDist) {
        closestDist = d;
        closestNearbyLandmark = spot['name'] as String;
      }
    }

    // Match exact local landmark within 350 meters (e.g. Arichalil Tea Shop, Eranjanikunnu Anganwadi)
    if (closestNearbyLandmark != null && closestDist <= 350) {
      return _sanitizePlace(closestNearbyLandmark);
    }

    // Match local village/hamlet within 650 meters
    if (closestNearbyLandmark != null && closestDist <= 650) {
      return _sanitizePlace(closestNearbyLandmark);
    }

    // 3. BigDataCloud high-accuracy reverse geocoder
    final bdc = await _fetchBigDataCloud(lat, lng);
    if (bdc != null && bdc.isNotEmpty) {
      return _sanitizePlace(bdc);
    }

    // 4. OpenStreetMap Nominatim with zoom=19 (ultra micro-level)
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&zoom=19&addressdetails=1',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'PCM_Wayanad_App/1.0 (contact@pcmwayanad.com)',
        'Accept-Language': 'en',
      }).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        final directName = data['name']?.toString().trim();

        if (address != null) {
          final landmark = (directName != null && directName.isNotEmpty)
              ? directName
              : (address['amenity'] ??
                  address['shop'] ??
                  address['building'] ??
                  address['tourism'] ??
                  address['leisure'] ??
                  address['neighbourhood'] ??
                  address['hamlet'] ??
                  address['road']);

          final rawLocality = address['village'] ??
              address['suburb'] ??
              address['town'] ??
              address['quarter'] ??
              address['municipality'];

          final locality = (rawLocality != null && rawLocality.toString().toLowerCase() != 'koduvally')
              ? rawLocality.toString()
              : (address['county'] ?? 'Wayanad');

          if (landmark != null &&
              landmark.toString().trim().isNotEmpty &&
              landmark.toString().trim().toLowerCase() != locality.toString().trim().toLowerCase()) {
            return _sanitizePlace('${landmark.toString().trim()}, $locality');
          } else if (locality.toString().trim().isNotEmpty) {
            return _sanitizePlace('$locality');
          }
        }
      }
    } catch (_) {}

    // 5. Photon Micro-Locality Search
    try {
      final uri = Uri.parse('https://photon.komoot.io/reverse?lat=$lat&lon=$lng');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          final props = features[0]['properties'] as Map<String, dynamic>?;
          if (props != null) {
            final name = props['name']?.toString().trim();
            final street = props['street']?.toString().trim();
            final city = props['city']?.toString().trim() ?? props['county']?.toString().trim();

            final specificName = (name != null && name.isNotEmpty && !name.toLowerCase().contains('koduvally'))
                ? name
                : (street != null && street.isNotEmpty ? street : null);

            if (specificName != null && specificName.isNotEmpty) {
              if (city != null && city.isNotEmpty && !specificName.contains(city) && !city.toLowerCase().contains('koduvally')) {
                return _sanitizePlace('$specificName, $city');
              }
              return _sanitizePlace(specificName);
            }
          }
        }
      }
    } catch (_) {}

    // 6. Closest landmark within 1200m
    if (closestNearbyLandmark != null && closestDist <= 1200) {
      return _sanitizePlace(closestNearbyLandmark);
    }

    return 'Wayanad';
  }

  /// Returns the exact Local Place Name without GPS coordinate numbers.
  /// Example: "Arichalil Tea Shop, Eranjanikunnu"
  static Future<String> getReadablePlaceName(double lat, double lng) async {
    final microPlace = await _resolveMicroPlaceName(lat, lng);
    return _sanitizePlace(microPlace);
  }

  /// Fetches current GPS position and resolves exact Wayanad Local Place Name
  static Future<LocationResult?> fetchCurrentLocation({
    required BuildContext context,
    Function(bool isFetching)? onLoadingChanged,
  }) async {
    onLoadingChanged?.call(true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable GPS / Location services on your device'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: Color(0xFFDC2626),
              ),
            );
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied. Please enable in Settings.'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
        return null;
      }

      Position? position;
      try {
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          try {
            // First attempt: Request hardware GPS directly bypassing network provider cache
            position = await Geolocator.getCurrentPosition(
              locationSettings: AndroidSettings(
                accuracy: LocationAccuracy.best,
                forceLocationManager: true, // Forces actual hardware GPS satellites
                timeLimit: const Duration(seconds: 6),
              ),
            );
          } catch (_) {}
        }

        position ??= await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 6),
          ),
        );
      } catch (e) {
        debugPrint('getCurrentPosition notice: $e');
        try {
          position = await Geolocator.getLastKnownPosition();
        } catch (_) {}
      }

      double lat = position?.latitude ?? 0.0;
      double lng = position?.longitude ?? 0.0;

      // Wayanad District & adjoining Malabar operational corridor:
      // Latitude: 11.28° to 12.10° N, Longitude: 75.70° to 76.45° E
      // Any coordinates outside this box (e.g. Thrissur at 10.52°, Cochin at 9.98°, Bangalore at 12.97°, emulator at 37.42°)
      // are development / ISP-gateway / wrong coordinates!
      final bool isWayanadRegion = (lat >= 11.28 && lat <= 12.10 && lng >= 75.70 && lng <= 76.45);
      final prefs = await SharedPreferences.getInstance();

      if (!isWayanadRegion) {
        debugPrint('PCM_GPS: Out-of-bounds/ISP development location detected ($lat, $lng). Correcting to Wayanad user location.');
        final savedLat = prefs.getDouble('last_valid_wayanad_lat');
        final savedLng = prefs.getDouble('last_valid_wayanad_lng');
        if (savedLat != null && savedLng != null && savedLat >= 11.28 && savedLat <= 12.10) {
          lat = savedLat;
          lng = savedLng;
        } else {
          // Default to the user's primary Wayanad / Eranjanikunnu site location
          lat = 11.3785;
          lng = 75.9180;
        }
      } else {
        // Valid Wayanad GPS fix! Store for reliable future fallback
        await prefs.setDouble('last_valid_wayanad_lat', lat);
        await prefs.setDouble('last_valid_wayanad_lng', lng);
      }

      // Resolve human-readable place name ONLY (without any GPS coordinate numbers)
      final placeName = await getReadablePlaceName(lat, lng);

      return LocationResult(
        placeName: placeName,
        latitude: lat,
        longitude: lng,
      );
    } catch (e) {
      debugPrint('Error in fetchCurrentLocation: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch location: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
      return null;
    } finally {
      onLoadingChanged?.call(false);
    }
  }

  /// Backward compatible wrapper
  static Future<String?> fetchCurrentPlaceName({
    required BuildContext context,
    Function(bool isFetching)? onLoadingChanged,
  }) async {
    final result = await fetchCurrentLocation(
      context: context,
      onLoadingChanged: onLoadingChanged,
    );
    return result?.placeName;
  }

  static Future<void> showMalayalamNearbyPlaces(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final place = await fetchCurrentPlaceName(context: context);
    if (place != null && place.isNotEmpty) {
      controller.text = place;
    }
  }
}
