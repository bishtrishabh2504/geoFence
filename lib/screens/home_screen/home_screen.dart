import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:geofence_demo/helper/local_storage.dart';
import 'package:geofence_demo/helper/network_helper.dart';
import 'package:geofence_demo/main.dart'; // for LogHelper + restartApp
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
    _initialTracking();
    _initBackgroundGeolocation();
  }

  Future<void> _initialTracking() async {
    LogHelper.logEvent("initial_tracking_start");
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

      LogHelper.logEvent("initial_tracking_got_location", params: {
        "lat": lat,
        "lng": lng,
      });

      await _sendLocationToServer(lat, lng);
      LogHelper.logEvent("initial_tracking_done");
    } catch (e, stack) {
      LogHelper.logError(e, stack, reason: "initial_tracking_failed");
      if (!mounted) return;
      setState(() => _firebaseStatus = "Failed to get initial location");
    }
  }

  void _initBackgroundGeolocation() {
    LogHelper.logEvent("bg_config_begin");

    bg.BackgroundGeolocation.ready(
      bg.Config(
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: 10,
        stopOnTerminate: false,
        startOnBoot: true,
        debug: true,
        logLevel: bg.Config.LOG_LEVEL_VERBOSE,
        enableHeadless: true,
      ),
    ).then((state) {
      LogHelper.logEvent("bg_config_ready", params: {
        "enabled": state.enabled,
        "isMoving": state.isMoving.toString(),
        "distanceFilter": state.distanceFilter.toString(),
      });

      if (!state.enabled) {
        bg.BackgroundGeolocation.start().then((_) {
          LogHelper.logEvent("bg_started");
        }).catchError((e, stack) {
          LogHelper.logError(e, stack, reason: "bg_start_failed");
        });
      }
    }).catchError((e, stack) {
      LogHelper.logError(e, stack, reason: "bg_ready_failed");
    });

    // Foreground onLocation listener
    bg.BackgroundGeolocation.onLocation((bg.Location location) async {
      try {
        final lat = location.coords.latitude;
        final lng = location.coords.longitude;

        LogHelper.logEvent("onLocation", params: {
          "lat": lat,
          "lng": lng,
          "source": "foreground_listener",
          "sample": location.sample,
          "odometer": location.odometer,
          "speed": location.coords.speed,
          "accuracy": location.coords.accuracy,
        });

        if (!mounted) return;
        setState(() {
          _locationText = "Lat: $lat, Lng: $lng";
          _firebaseStatus = "Updating Firebase...";
        });

        await _sendLocationToServer(lat, lng);
      } catch (e, stack) {
        LogHelper.logError(e, stack, reason: "onLocation_handler_failed");
        if (mounted) {
          setState(() => _firebaseStatus = "Update failed");
        }
      }
    });
    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent e) {
      LogHelper.logEvent("provider_change", params: {
        "status": e.status,
        "gps": e.gps,
        "network": e.network,
        "enabled": e.enabled,
      });
    });
  }

  Future<void> _sendLocationToServer(double lat, double lng) async {
    final userId = appStorage.getUserId;
    final payload = {"user_id": userId, "lat": lat, "lng": lng};

    // Firebase
    try {
      await FirebaseHelper.updateUserLocation(
        userId: userId.toString(),
        lat: lat,
        lng: lng,
      );
      if (mounted) {
        setState(() => _firebaseStatus = "location updated on Firebase");
      }
      LogHelper.logEvent("firebase_update_success", params: {
        "userId": userId,
        "lat": lat,
        "lng": lng,
      });
    } catch (e, stack) {
      LogHelper.logError(e, stack, reason: "firebase_update_failed");
      if (mounted) {
        setState(() => _firebaseStatus = "Failed to update Firebase");
      }
    }

    // API
    try {
      await NetworkService().request<Map<String, dynamic>>(
        endpoint: "location",
        method: HttpMethod.post,
        data: payload,
        fromJson: (json) => json,
      );
      LogHelper.logEvent("api_location_success", params: {
        "userId": userId,
        "lat": lat,
        "lng": lng,
      });
    } catch (e, stack) {
      LogHelper.logError(e, stack, reason: "api_location_failed");
    }
  }

  Future<void> stopBackgroundTracking() async {
    try {
      await bg.BackgroundGeolocation.stop();
      bg.BackgroundGeolocation.removeListeners();
      LogHelper.logEvent("bg_stopped_manually");
    } catch (e, stack) {
      LogHelper.logError(e, stack, reason: "bg_stop_failed");
    }
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
              LogHelper.logEvent("logout_clicked");
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
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              _firebaseStatus,
              style: const TextStyle(fontSize: 14, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
