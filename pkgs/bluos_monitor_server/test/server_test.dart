import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

import 'test_definitions.dart';

void main() {
  late TestProcess monitorProc;
  late TestProcess playerProc;
  late int port;

  setUp(() async {
    monitorProc = await TestProcess.start(
      'dart',
      ['bin/server.dart'],
      environment: {'PORT': '0'},
    );
    playerProc = await TestProcess.start(
      'dart',
      ['test/fake_player.dart'],
      environment: {'PORT': '1'},
    );

    final output = await monitorProc.stdout.next;
    final match = _listeningPattern.firstMatch(output)!;
    port = int.parse(match[1]!);
  });

  group('BluOS monitor server', () {
    void testServer(String name, Future<void> Function(String host) func) {
      test(name, () async {
        await func('localhost:$port');
        await monitorProc.kill();
        await playerProc.kill();
      }, timeout: _defaultTimeout);
    }

    runTests(testServer);
  });
}

const _defaultTimeout = Timeout(Duration(seconds: 5));

final _listeningPattern = RegExp(r'Serving at http://[^:]+:(\d+)');
