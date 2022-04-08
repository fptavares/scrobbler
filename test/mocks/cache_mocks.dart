import 'package:file/file.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/expect.dart';

import 'cache_mocks.mocks.dart';

export 'cache_mocks.mocks.dart';

@GenerateMocks([CacheManager, File, http.Client])
MockCacheManager createMockCacheManager([Map<Matcher, Future<File> Function(Invocation)>? responses]) {
  final cache = MockCacheManager();
  responses?.forEach((matcher, function) {
    when(cache.getSingleFile(argThat(matcher), headers: anyNamed('headers'))).thenAnswer(function);
  });
  return cache;
}

MockFile createMockFile(String Function() readCallback) {
  final file = MockFile();
  when(file.readAsStringSync()).thenAnswer((_) => readCallback());
  return file;
}
