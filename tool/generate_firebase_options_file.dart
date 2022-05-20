import 'dart:io';

void main() {
  final firebaseFile = File('lib/firebase_options.dart');

  if (firebaseFile.existsSync()) {
    // ignore: avoid_print
    print('The Firebase Options file already exists at: ${firebaseFile.path}');
    exit(1);
  }

  firebaseFile.writeAsStringSync('''
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '',
    projectId: '',
  );
}
''');
}
