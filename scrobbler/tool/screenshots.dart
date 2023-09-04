import 'dart:async';
import 'dart:io';

import 'package:emulators/emulators.dart';

const kIosPath = 'ios/fastlane/screenshots/en-US';
const kAndroidPhonePath = 'android/fastlane/metadata/android/en-US/images/phoneScreenshots';
const kAndroidTabletPath = 'android/fastlane/metadata/android/en-US/images/tenInchScreenshots';

Future<void> main() async {
  final emu = await Emulators.build();

  // Shutdown all the running emulators
  await emu.shutdownAll();

  Future<void> Function(Device) emulatorCallback(String iosPath, String androidPath) {
    return (device) async {
      final p = await emu.drive(device, 'test_driver/main.dart', config: {
        'iosPath': iosPath,
        'androidPath': androidPath,
      });
      await stderr.addStream(p.stderr);
      await stdout.addStream(p.stdout);
    };
  }

  // For each emulator in the list, we run `flutter drive`.
  await emu.forEach([
    'iPhone 13 Pro Max',
    'iPhone 8 Plus',
    'iPad Pro (12.9-inch) (6th generation)',
    'iPad Pro (12.9-inch) (2nd generation)',
    'Pixel_5',
  ])(emulatorCallback(kIosPath, kAndroidPhonePath));

  // Android tablet screenshots go to a different path
  await emu.forEach([
    'Nexus_9',
  ])(emulatorCallback(kIosPath, kAndroidTabletPath));
}
