import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:scrobbler/components/accounts.dart';
import 'package:scrobbler/model/analytics.dart';
import 'package:scrobbler/model/lastfm.dart';
import 'package:scrobbler/model/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Map<String, dynamic> _prefsInitialValues = <String, dynamic>{
  DiscogsSettings.discogsUsernameKey: 'd-test-user',
  DiscogsSettings.skippedKey: false,
  LastfmSettings.lastfmUsernameKey: 'l-test-user',
  LastfmSettings.sessionKeyKey: 'session-key',
};

void main() {
  SharedPreferences prefs;
  MockScrobbler scrobbler;

  setUpAll(() async {
    ScrobblerAnalytics.analytics = MockFirebaseAnalytics();
    ScrobblerAnalytics.performance = MockFirebasePerformance();
    SharedPreferences.setMockInitialValues(_prefsInitialValues);
    prefs = await SharedPreferences.getInstance();
    scrobbler = MockScrobbler();
    when(scrobbler.initializeSession(any, any)).thenAnswer((_) => Future.value('test-session-key'));
  });

  Widget createAccountsWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DiscogsSettings>(
          create: (_) => DiscogsSettings(prefs),
          lazy: false,
        ),
        ChangeNotifierProvider<LastfmSettings>(
          create: (_) => LastfmSettings(prefs),
          lazy: false,
        ),
        Provider<Scrobbler>.value(value: scrobbler),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: AccountsForm(),
        ),
      ),
    );
  }

  Future<void> submitForm(
      WidgetTester tester, String discogsUsername, String lastfmUsername, String lastfmPassword) async {
    await tester.enterText(find.byKey(AccountsForm.discogsUsernameFieldKey), discogsUsername);
    await tester.enterText(find.byKey(AccountsForm.lastfmUsernameFieldKey), lastfmUsername);
    await tester.enterText(find.byKey(AccountsForm.lastfmPasswordFieldKey), lastfmPassword);

    expect(tester.widget<FlatButton>(find.byType(FlatButton)).onPressed, isNotNull);

    expect(tester.widget<FlatButton>(find.byType(FlatButton)).enabled, isTrue);

    await tester.tap(find.byType(FlatButton));

    await tester.pump();
  }

  void checkPreference(String key, String expectedValue) {
    expect(prefs.getString(key), equals(expectedValue));
  }

  void checkPreferences(String testDiscogsUsername, String testLastfmUsername, String testSessionKey) {
    checkPreference(DiscogsSettings.discogsUsernameKey, testDiscogsUsername);
    checkPreference(LastfmSettings.lastfmUsernameKey, testLastfmUsername);
    checkPreference(LastfmSettings.sessionKeyKey, testSessionKey);
  }

  void checkUnchanged(String key) {
    checkPreference(key, _prefsInitialValues[key]);
  }

  void checkAllUnchanged() {
    checkUnchanged(DiscogsSettings.discogsUsernameKey);
    checkUnchanged(LastfmSettings.lastfmUsernameKey);
    checkUnchanged(LastfmSettings.sessionKeyKey);
  }

  Future<void> editAndVerify(WidgetTester tester, String testDiscogsUsername, String testLastfmUsername,
      String testLastfmPassword, String testSessionKey,
      {bool shouldInitializeSession = true}) async {
    when(scrobbler.initializeSession(any, any)).thenAnswer((_) async {
      if (testSessionKey == null) {
        throw Exception('initializeSession-fail-test');
      }
      return testSessionKey;
    });

    await submitForm(tester, testDiscogsUsername, testLastfmUsername, testLastfmPassword);

    if (shouldInitializeSession) {
      verify(scrobbler.initializeSession(testLastfmUsername, testLastfmPassword)).called(1);
    } else {
      verifyNever(scrobbler.initializeSession(any, any));
    }

    checkPreferences(testDiscogsUsername, testLastfmUsername, testSessionKey);
  }

  testWidgets('Accounts form renders, validates and saves settings', (tester) async {
    await tester.pumpWidget(createAccountsWidget());

    expect(find.byType(Form), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.byType(FlatButton), findsOneWidget);

    expect(find.text(prefs.getString(DiscogsSettings.discogsUsernameKey)), findsOneWidget);
    expect(find.text(prefs.getString(LastfmSettings.lastfmUsernameKey)), findsOneWidget);

    // validates empty fields and doesn\'t save

    await tester.pumpWidget(createAccountsWidget());

    await submitForm(tester, '', '', '');
    checkAllUnchanged();

    await submitForm(tester, 'new_discogs_username', '', '');
    expect(find.text(AccountsForm.lastfmInvalidUsernameMessage), findsOneWidget);
    expect(find.text(AccountsForm.lastfmInvalidPasswordMessage), findsOneWidget);
    checkAllUnchanged();

    await submitForm(tester, '', 'new_lastfm_username', '');
    expect(find.text(AccountsForm.discogsInvalidUsernameMessage), findsOneWidget);
    expect(find.text(AccountsForm.lastfmInvalidPasswordMessage), findsOneWidget);
    checkAllUnchanged();

    await submitForm(tester, '', '', 'new_password');
    expect(find.text(AccountsForm.discogsInvalidUsernameMessage), findsOneWidget);
    expect(find.text(AccountsForm.lastfmInvalidUsernameMessage), findsOneWidget);
    checkAllUnchanged();

    // saves the new account details'

    const errorMessage = 'Exception: initializeSession-fail-test';

    await editAndVerify(
        tester, 'new_discogs_username_2', 'new_lastfm_username_2', 'new_password_2', 'new_session_key_2');
    expect(find.text(AccountsForm.saveSuccessMessage), findsOneWidget);
    expect(find.text(errorMessage), findsNothing);

    await clearSnackbars(tester);

    // saves new discogs username even if the last.fm password is empty if last.fm username is unchanged

    await editAndVerify(tester, 'new_discogs_username_3', 'new_lastfm_username_2', '', 'new_session_key_2',
        shouldInitializeSession: false);
    expect(find.text(AccountsForm.saveSuccessMessage), findsOneWidget);
    expect(find.text(errorMessage), findsNothing);

    await clearSnackbars(tester);

    // saves new usernames even if last.fm authentication fails

    await editAndVerify(tester, 'new_discogs_username_4', 'new_lastfm_username_4', 'new_password_4', null);
    expect(find.text(errorMessage), findsOneWidget);
    expect(find.text(AccountsForm.saveSuccessMessage), findsNothing);
  });
}

Future clearSnackbars(WidgetTester tester) async {
  // allow time for snackbar to leave the screen (5 seconds default duration)
  // below thanks to: https://github.com/flutter/flutter/blob/ec9813a5005f4c3e75a5a9f42ce53ae280959085/packages/flutter/test/material/snack_bar_test.dart#L42-L53
  await tester.pump(); // schedule animation
  await tester.pump(); // begin animation
  await tester.pump(const Duration(milliseconds: 750)); // 0.75s // animation last frame; five second timer starts here
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 750)); // 1.50s
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 750)); // 2.25s
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 750)); // 3.00s
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 750)); // 3.75s
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 750)); // 4.50s
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 750)); // 5.25s
  await tester.pump();
  await tester.pump(
      const Duration(milliseconds: 750)); // 6.00s // timer triggers to dismiss snackbar, reverse animation is scheduled
  await tester.pump(); // begin animation
}

// Mock classes
class MockScrobbler extends Mock implements Scrobbler {}

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

class MockTrace extends Mock implements Trace {}

class MockFirebasePerformance extends Mock implements FirebasePerformance {
  @override
  Trace newTrace(String name) => MockTrace();
}
