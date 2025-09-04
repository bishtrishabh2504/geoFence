import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
as bg;
import 'package:geofence_demo/helper/local_storage.dart';
import 'package:geofence_demo/helper/network_helper.dart';

import '../../helper/firebase_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _locationText = "Waiting for location...";

  @override
  void initState() {
    super.initState();
    _initBackgroundGeolocation();
  }

  void _initBackgroundGeolocation() {
    bg.BackgroundGeolocation.ready(
      bg.Config(
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: 20,
        stopOnTerminate: false,
        startOnBoot: true,
        debug: true,
        logLevel: bg.Config.LOG_LEVEL_VERBOSE,
      ),
    ).then((state) {
      if (!state.enabled) {
        bg.BackgroundGeolocation.start();
      }
    });


    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      final lat = location.coords.latitude;
      final lng = location.coords.longitude;

      setState(() {
        _locationText = "Lat: $lat, Lng: $lng";
      });

      _sendLocationToServer(lat, lng);
    });
  }

  Future<void> _sendLocationToServer(double lat, double lng) async {
    final userId = AppStoragePref.shared.getUserId;
    final payload = {
      "user_id": userId,
      "lat": lat,
      "lng": lng,
    };

    try {
      await NetworkService().request<Map<String, dynamic>>(
        endpoint: "location",
        method: HttpMethod.post,
        data: payload,
        fromJson: (json) => json,
      );

      await FirebaseHelper.updateUserLocation(
        userId: userId.toString(),
        lat: lat,
        lng: lng,
      );
    } catch (e, stack) {
      // Handle error (e.g., log it)
      debugPrint("Failed to send location: $e and stack $stack");
    }
  }

  @override
  void dispose() {
    bg.BackgroundGeolocation.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home - Tracking")),
      body: Center(
        child: Text(
          _locationText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
