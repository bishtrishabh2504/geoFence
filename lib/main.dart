import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
as bg;
import 'package:geofence_demo/helper/local_storage.dart';
import 'package:geofence_demo/screens/home_screen/home_screen.dart';
import 'package:geofence_demo/screens/login_screens/login_screen_view.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BG Geolocation Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: AppStoragePref.shared.getIsLogin ? HomePage(): LoginScreen(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    bg.BackgroundGeolocation.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BG Geolocation Debug Test")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Current location:",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
