import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class LogHelper {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static void logEvent(String name, {Map<String, Object>? params}) {
    print("Reported event: $name, params: $params");
    _analytics.logEvent(name: name, parameters: params);
  }

  static void logError(dynamic error, StackTrace stack, {String reason = ""}) {
    print("Reported error: $error, and stacktrace: $stack, reason: $reason");
    FirebaseCrashlytics.instance.recordError(error, stack, reason: reason);
  }
}
