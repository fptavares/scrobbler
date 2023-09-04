import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:scrobbler/model/analytics.dart';

import 'firebase_mocks.mocks.dart';

@GenerateMocks([FirebaseAnalytics, FirebasePerformance, Trace])
void replaceFirebaseWithMocks() {
  ScrobblerAnalytics.analytics = MockFirebaseAnalytics();
  final mockPerfomance = MockFirebasePerformance();
  when(mockPerfomance.newTrace(any)).thenReturn(MockTrace());
  ScrobblerAnalytics.performance = mockPerfomance;
}
