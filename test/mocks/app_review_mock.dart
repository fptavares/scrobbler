import 'package:in_app_review/in_app_review.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'app_review_mock.mocks.dart';

export 'app_review_mock.mocks.dart';

@GenerateMocks([InAppReview])
MockInAppReview createMockAppReview() {
  final review = MockInAppReview();
  when(review.isAvailable()).thenAnswer((_) => Future.value(true));
  return review;
}
