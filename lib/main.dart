import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:geofence_demo/helper/local_storage.dart';
import 'package:geofence_demo/screens/home_screen/home_screen.dart';
import 'package:geofence_demo/screens/login_screens/login_screen_view.dart';
import 'package:get_storage/get_storage.dart';
import 'package:background_fetch/background_fetch.dart';

import 'helper/firebase_manager.dart';
import 'helper/network_helper.dart';

@pragma('vm:entry-point')
void backgroundTask(bg.HeadlessEvent headlessEvent) async {
  if (headlessEvent.name == bg.Event.LOCATION  || headlessEvent.name == bg.Event.TERMINATE
  || headlessEvent.name == bg.Event.HEARTBEAT) {
    final location = await bg.BackgroundGeolocation.getCurrentPosition(
        samples: 1,
        persist: true,
        extras: {
          "event": "terminate",
          "headless": true
        }
    );
    final lat = location.coords.latitude;
    final lng = location.coords.longitude;
    final userId = appStorage.getUserId;

    try {
      // Send to server
      await NetworkService().request<Map<String, dynamic>>(
        endpoint: "location",
        method: HttpMethod.post,
        data: {"user_id": userId, "lat": lat, "lng": lng},
        fromJson: (json) => json,
      );

      // Send to Firebase
    } catch (e) {
      print("Failed to send location in headless task: $e");
    }

    try{
      await FirebaseHelper.updateUserLocation(
        userId: userId.toString(),
        lat: lat,
        lng: lng,
      );
    }catch(e){
      print("Failed to update location in firebase in headless task: $e");
    }
  }
}
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;

  // Is this a background_fetch timeout event?  If so, simply #finish and bail-out.
  if (task.timeout) {
    print("[BackgroundFetch] HeadlessTask TIMEOUT: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  try {
    var location = await bg.BackgroundGeolocation.getCurrentPosition(
        samples: 2,
        extras: {
          "event": "background-fetch",
          "headless": true
        }
    );
    final lat = location.coords.latitude;
    final lng = location.coords.longitude;
    final userId = appStorage.getUserId;

    try {
      // Send to server
      await NetworkService().request<Map<String, dynamic>>(
        endpoint: "location",
        method: HttpMethod.post,
        data: {"user_id": userId, "lat": lat, "lng": lng},
        fromJson: (json) => json,
      );

      // Send to Firebase
    } catch (e) {
      print("Failed to send location in headless task: $e");
    }

    try{
      await FirebaseHelper.updateUserLocation(
        userId: userId.toString(),
        lat: lat,
        lng: lng,
      );
    }catch(e){
      print("Failed to update location in firebase in headless task: $e");
    }
    print("[location] $location");
  } catch(error) {
    print("[location] ERROR: $error");
  }
  BackgroundFetch.finish(taskId);
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GetStorage.init();
  bg.BackgroundGeolocation.registerHeadlessTask(backgroundTask);
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _uniqueKey = UniqueKey();

  restartApp() {
    setState(() => _uniqueKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: _uniqueKey,
      title: 'BG Geolocation Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: appStorage.getIsLogin ? HomePage() : LoginScreen(),
    );
  }
}
