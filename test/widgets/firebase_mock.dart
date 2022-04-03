import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

mixin FirebaseMock {
  static void setMock() {
    const channel = MethodChannel('plugins.flutter.io/firebase_analytics');

    channel.setMockMethodCallHandler((_) async {
      // do nothing
    });

    MethodChannelFirebase.channel.setMockMethodCallHandler((call) async {
      return null;
    });
  }
}
