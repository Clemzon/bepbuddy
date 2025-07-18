import 'dart:async';
import 'package:flutter/services.dart';

class ShareIntentService {
  static const _method = MethodChannel('com.madlabz.bepbuddy/share_intent');
  static const _events = EventChannel('com.madlabz.bepbuddy/share_intent_events');

  /// Call once at app startup to get the file (if any) used to launch the app.
  static Future<String?> getInitialUri() async {
    try {
      final uri = await _method.invokeMethod<String>('getInitialShare');
      return uri;
    } on PlatformException {
      return null;
    }
  }

  /// Stream of subsequent shared/tapped-file URIs.
  static Stream<String> get uriStream =>
      _events.receiveBroadcastStream().cast<String>();
}