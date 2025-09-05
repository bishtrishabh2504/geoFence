import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
as bg;
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> checkLocationPermission(BuildContext context) async {
    try {
      int status = await bg.BackgroundGeolocation.requestPermission();

      if (status == bg.ProviderChangeEvent.AUTHORIZATION_STATUS_DENIED) {
        _showPermissionDialog(context);
        return false;
      } else {
        return true;
      }
    } on Exception catch (e) {
      debugPrint("Permission request failed: $e");
      _showPermissionDialog(context);
      return false;
    }
  }

  static void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Location Permission Needed"),
        content: const Text(
          "We need your location to log you in and track deliveries.\n\n"
              "Please enable location in app settings.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings(); // from permission_handler
            },
            child: const Text("Open Settings"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }
}
