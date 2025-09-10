import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:geofence_demo/helper/local_storage.dart';
import 'package:geofence_demo/helper/network_helper.dart';
import 'package:geofence_demo/main.dart'; 
import '../../helper/firebase_loghelper.dart';
import '../../helper/firebase_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _locationText = "Waiting for location...";
  String _firebaseStatus = "";

  @override
  void initState() {
    super.initState();
    LogHelper.logEvent("home_init");

    // First update when entering Home
    _initialTracking();

    // Start background geolocation with 15s interval
    _initBackgroundGeolocation();
  }

  Future<void> _initialTracking() async {
    try {
      final location = await bg.BackgroundGeolocation.getCurrentPosition(
        samples: 1,
        persist: false,
        extras: {"source": "initialTracking"},
      );

      final lat = location.coords.latitude;
      final lng = location.coords.longitude;

      if (!mounted) return;
      setState(() {
        _locationText = "Lat: $lat, Lng: $lng";
        _firebaseStatus = "Updating Firebase...";
      });

      await _sendLocationToServer(lat, lng);
    } catch (e, stack) {
      LogHelper.logError(e, stack, reason: "initial_tracking_failed");
      if (!mounted) return;
      setState(() => _firebaseStatus = "Failed to get initial location");
    }
  }

void _initBackgroundGeolocation() {
  bg.BackgroundGeolocation.ready(bg.Config(
    desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
    distanceFilter: 0,              
    locationUpdateInterval: 10000,  
    fastestLocationUpdateInterval: 10000,
    heartbeatInterval: 60,
    stopOnTerminate: false,
    startOnBoot: true,
    debug: true,
    logLevel: bg.Config.LOG_LEVEL_VERBOSE,
    enableHeadless: true,
    foregroundService: true,  
    preventSuspend: true,    
  )).then((state) async {
    if (!state.enabled) {
      await bg.BackgroundGeolocation.start();
        await bg.BackgroundGeolocation.changePace(true);
    }

    await bg.BackgroundGeolocation.changePace(true);
  });

bg.BackgroundGeolocation.onHeartbeat((bg.HeartbeatEvent event) async {
  final location = await bg.BackgroundGeolocation.getCurrentPosition(
    samples: 1,
    persist: false,
  );
  await _sendLocationToServer(
    location.coords.latitude,
    location.coords.longitude,
  );
});
  bg.BackgroundGeolocation.onLocation((bg.Location location) async {
    final lat = location.coords.latitude;
    final lng = location.coords.longitude;

    LogHelper.logEvent("onLocation_10s", params: {
      "lat": lat,
      "lng": lng,
      "accuracy": location.coords.accuracy,
      "speed": location.coords.speed,
    });

    if (mounted) {
      setState(() {
        _locationText = "Lat: $lat, Lng: $lng";
        _firebaseStatus = "Updating...";
      });
    }

    await _sendLocationToServer(lat, lng);
  });
}
  Future<void> _sendLocationToServer(double lat, double lng) async {
    final userId = appStorage.getUserId;
    final payload = {"user_id": userId, "lat": lat, "lng": lng};

    try {
      // API call first
      var response = await NetworkService().request<Map<String, dynamic>>(
        endpoint: "location",
        method: HttpMethod.post,
        data: payload,
        fromJson: (json) => json,
      );

      // Firebase only after API succeeds

      if(response['success'] ?? false) {
        await FirebaseHelper.updateUserLocation(
        userId: userId.toString(),
        lat: lat,
        lng: lng,
      );
      } else {
        await FirebaseHelper.updateUserLocation(
        userId: 'failed ${response['success'].toString()}',
        lat: lat,
        lng: lng,
      );
      }
      

      if (mounted) {
        setState(() => _firebaseStatus = "Location updated");
      }

      LogHelper.logEvent("location_update_success", params: {
        "lat": lat,
        "lng": lng,
        "userId": userId,
      });
    } catch (e, stack) {
      LogHelper.logError(e, stack, reason: "location_update_failed");
    }
  }

  Future<void> stopBackgroundTracking() async {
    await bg.BackgroundGeolocation.stop();
    bg.BackgroundGeolocation.removeListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home - Tracking"),
        actions: [
          IconButton(
            onPressed: () async {
              await stopBackgroundTracking();
              await AppStoragePref.customerStorage.erase();
              MyApp.of(context).restartApp();
            },
            icon: const Icon(Icons.exit_to_app_outlined),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_locationText,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(_firebaseStatus,
                style: const TextStyle(fontSize: 14, color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
