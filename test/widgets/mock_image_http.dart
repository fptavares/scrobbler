// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:mockito/mockito.dart';

const List<int> kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
];

// Returns a mock HTTP client that responds with an image to all requests.
MockHttpClient createMockImageHttpClient(SecurityContext _) {
  final client = MockHttpClient();
  final request = MockHttpClientRequest();
  final response = MockHttpClientResponse();
  final headers = MockHttpHeaders();
  when(client.getUrl(any)).thenAnswer((_) => Future<HttpClientRequest>.value(request));
  when(request.headers).thenReturn(headers);
  when(request.close()).thenAnswer((_) => Future<HttpClientResponse>.value(response));
  when(response.contentLength).thenReturn(kTransparentImage.length);
  when(response.statusCode).thenReturn(HttpStatus.ok);
  when(response.listen(any)).thenAnswer((invocation) {
    final onData = invocation.positionalArguments[0] as void Function(List<int>);
    final onDone = invocation.namedArguments[#onDone] as void Function();
    final onError = invocation.namedArguments[#onError] as void Function(Object, [StackTrace]);
    final cancelOnError = invocation.namedArguments[#cancelOnError] as bool;
    return Stream<List<int>>.fromIterable(<List<int>>[kTransparentImage]).listen(onData, onDone: onDone, onError: onError, cancelOnError: cancelOnError);
  });
  return client;
}

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpClientRequest extends Mock implements HttpClientRequest {}

class MockHttpClientResponse extends Mock implements HttpClientResponse {}

class MockHttpHeaders extends Mock implements HttpHeaders {}
