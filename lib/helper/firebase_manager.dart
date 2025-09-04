import 'package:firebase_database/firebase_database.dart';

class FirebaseHelper {
  static final _db = FirebaseDatabase.instance.ref();

  static Future<void> updateUserLocation({
    required String userId,
    required double lat,
    required double lng,
  }) async {

    String dateTimeString = DateTime.now().toString();
    await _db.child("locations").child(userId).set({
      "lat": lat,
      "lng": lng,
      "timestamp": dateTimeString,
    });
  }
}