import 'dart:async';
import 'dart:io';

import 'package:emulators/emulators.dart';

Future<void> main() async {
  final emu = await Emulators.build();

  // Shutdown all the running emulators
  await emu.shutdownAll();

  // For each emulator in the list, we run `flutter drive`.
  await emu.forEach([
    'iPhone 8 Plus',
    'iPhone 13 Pro Max',
    'iPad Pro (12.9-inch) (6th generation)',
    'Pixel_5',
  ])((device) async {
    final p = await emu.drive(device, 'test_driver/main.dart');
    await stderr.addStream(p.stderr);
    await stdout.addStream(p.stdout);
  });
}
