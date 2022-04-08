import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scrobbler/components/accounts.dart';
import 'package:scrobbler/components/onboarding.dart';
import 'package:scrobbler/model/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/firebase_mocks.dart';

void main() {
  final skipButton = find.text('Skip');
  final startButton = find.text('Get started');

  group('Onboarding page', () {
    late DiscogsSettings discogsSettings;

    Future<Widget> createOnboarding() async {
      replaceFirebaseWithMocks();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      discogsSettings = DiscogsSettings(prefs);
      final lastfmSettings = LastfmSettings(prefs);

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<DiscogsSettings>.value(value: discogsSettings),
          ChangeNotifierProvider<LastfmSettings>.value(value: lastfmSettings),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: OnboardingPage(),
          ),
        ),
      );
    }

    testWidgets('renders welcome screen', (tester) async {
      await tester.pumpWidget(await createOnboarding());

      expect(find.text('Scrobbler'), findsOneWidget);
      expect(startButton, findsOneWidget);
      expect(skipButton, findsOneWidget);

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(2));
    });

    testWidgets('allows setting up accounts', (tester) async {
      await tester.pumpWidget(await createOnboarding());

      await tester.tap(startButton);
      await tester.pumpAndSettle();

      expect(find.byType(AccountsForm), findsOneWidget);
      expect(skipButton, findsOneWidget);

      expect(find.text('Record Scrobbler'), findsNothing);
      expect(startButton, findsNothing);
    });

    testWidgets('allows skipping', (tester) async {
      await tester.pumpWidget(await createOnboarding());

      expect(discogsSettings.skipped, isFalse);

      await tester.tap(skipButton);

      expect(discogsSettings.skipped, isTrue);
    });
  });
}
