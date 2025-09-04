import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:geofence_demo/helper/local_storage.dart';
import 'package:geofence_demo/screens/home_screen/home_screen.dart';
import 'package:geofence_demo/screens/login_screens/login_screen_view.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GetStorage.init();
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
