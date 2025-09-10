import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:geofence_demo/helper/local_storage.dart';
import 'package:geofence_demo/screens/home_screen/home_screen.dart';
import 'package:geofence_demo/screens/login_screens/login_screen_view.dart';
import 'package:get_storage/get_storage.dart';
import 'package:background_fetch/background_fetch.dart';

import 'helper/firebase_loghelper.dart';
import 'helper/firebase_manager.dart';
import 'helper/network_helper.dart';

@pragma('vm:entry-point')
void backgroundTask(bg.HeadlessEvent headlessEvent) async {
  if (headlessEvent.name == bg.Event.LOCATION) {
    final location = headlessEvent.event as bg.Location;
    final lat = location.coords.latitude;
    final lng = location.coords.longitude;
    final userId = appStorage.getUserId;

    try {
      await NetworkService().request<Map<String, dynamic>>(
        endpoint: "location",
        method: HttpMethod.post,
        data: {"user_id": userId, "lat": lat, "lng": lng},
        fromJson: (json) => json,
      );

      await FirebaseHelper.updateUserLocation(
        userId: userId.toString(),
        lat: lat,
        lng: lng,
      );
    } catch (e) {
      print("Headless task failed: $e");
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GetStorage.init();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  bg.BackgroundGeolocation.registerHeadlessTask(backgroundTask);
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
