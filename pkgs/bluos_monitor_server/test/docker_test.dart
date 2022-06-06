@Tags(['docker-test'])
import 'package:test/test.dart';

import 'test_definitions.dart';

void main() {
  group('BluOS monitor Docker server', () {
    test('responds to playlist request', () async {
      final response = await get('localhost:8080', '/playlist');
      verifyResponse(response, count: 0, isPolling: false);
    }, timeout: Timeout(Duration(seconds: 3)));
  });
}
