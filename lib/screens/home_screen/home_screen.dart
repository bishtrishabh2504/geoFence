import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:geofence_demo/helper/local_storage.dart';
import 'package:geofence_demo/helper/network_helper.dart';
import 'package:geofence_demo/main.dart';
import '../../helper/firebase_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _locationText = "Waiting for location...";
  String _firebaseStatus = ""; // To display Firebase update status

  @override
  void initState() {
    super.initState();
    _initialTracking();
    _initBackgroundGeolocation();
  }
  void _initialTracking() async {
    final location = await bg.BackgroundGeolocation.getCurrentPosition(
      samples: 1,
      persist: false,
    );
    final lat = location.coords.latitude;
    final lng = location.coords.longitude;

    setState(() {
      _locationText = "Lat: $lat, Lng: $lng";
      _firebaseStatus = "Updating Firebase...";
    });

    await _sendLocationToServer(lat, lng);
  }
  void _initBackgroundGeolocation() {
    bg.BackgroundGeolocation.ready(
      bg.Config(
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: 10, // This will invoke the onLocation every 1o meters
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

    bg.BackgroundGeolocation.onLocation((bg.Location location) async {
      final lat = location.coords.latitude;
      final lng = location.coords.longitude;

      setState(() {
        _locationText = "Lat: $lat, Lng: $lng";
        _firebaseStatus = "Updating Firebase...";
      });

      await _sendLocationToServer(lat, lng);
    });
  }

  Future<void> _sendLocationToServer(double lat, double lng) async {
    final userId = appStorage.getUserId;
    final payload = {
      "user_id": userId,
      "lat": lat,
      "lng": lng,
    };

    try {
      // Send to API
      await NetworkService().request<Map<String, dynamic>>(
        endpoint: "location",
        method: HttpMethod.post,
        data: payload,
        fromJson: (json) => json,
      );

      // Update Firebase
      await FirebaseHelper.updateUserLocation(
        userId: userId.toString(),
        lat: lat,
        lng: lng,
      );

      // Show success status
      setState(() {
        _firebaseStatus = "location updated on Firebase";
      });
    } catch (e, stack) {
      setState(() {
        _firebaseStatus = "Failed to update Firebase";
      });
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
      appBar: AppBar(title: const Text("Home - Tracking"),
      actions: [
        IconButton(onPressed: ()async{
          await stopBackgroundTracking();
          await AppStoragePref.customerStorage.erase();
          MyApp.of(context).restartApp();
        }, icon: Icon(Icons.exit_to_app_outlined))
      ],),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _locationText,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
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

  Future<void> stopBackgroundTracking() async {
    await bg.BackgroundGeolocation.stop();
    bg.BackgroundGeolocation.removeListeners();
  }

}
