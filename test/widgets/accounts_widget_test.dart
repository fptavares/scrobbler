import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:scrobbler/components/accounts.dart';
import 'package:scrobbler/components/error.dart';
import 'package:scrobbler/model/lastfm.dart';
import 'package:scrobbler/model/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/firebase_mocks.dart';
import '../mocks/model_mocks.dart';

final _prefsInitialValues = <String, Object>{
  Settings.discogsUsernameKey: 'd-test-user',
  Settings.skippedKey: false,
  Settings.lastfmUsernameKey: 'l-test-user',
  Settings.lastfmSessionKeyKey: 'session-key',
};

void main() {
  late SharedPreferences prefs;
  late MockScrobbler scrobbler;

  setUpAll(() async {
    replaceFirebaseWithMocks();
    SharedPreferences.setMockInitialValues(_prefsInitialValues);
    prefs = await SharedPreferences.getInstance();
    scrobbler = MockScrobbler();
    when(scrobbler.initializeSession(any, any)).thenAnswer((_) => Future.value('test-session-key'));
  });

  Widget createAccountsWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<Settings>(
          create: (_) => Settings(prefs),
          lazy: false,
        ),
        Provider<Scrobbler>.value(value: scrobbler),
      ],
      child: MaterialApp(
        home: const Scaffold(
          body: AccountsForm(),
        ),
        scaffoldMessengerKey: scrobblerScaffoldMessengerKey,
      ),
    );
  }

  Future<void> submitForm(
      WidgetTester tester, String discogsUsername, String lastfmUsername, String lastfmPassword) async {
    await tester.enterText(find.byKey(AccountsForm.discogsUsernameFieldKey), discogsUsername);
    await tester.enterText(find.byKey(AccountsForm.lastfmUsernameFieldKey), lastfmUsername);
    await tester.enterText(find.byKey(AccountsForm.lastfmPasswordFieldKey), lastfmPassword);

    expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed, isNotNull);

    expect(tester.widget<TextButton>(find.byType(TextButton)).enabled, isTrue);

    await tester.tap(find.byType(TextButton));

    await tester.pump();
  }

  void checkPreference(String key, Object? expectedValue) {
    expect(prefs.getString(key), equals(expectedValue));
  }

  void checkPreferences(String testDiscogsUsername, String testLastfmUsername, String? testSessionKey) {
    checkPreference(Settings.discogsUsernameKey, testDiscogsUsername);
    checkPreference(Settings.lastfmUsernameKey, testLastfmUsername);
    checkPreference(Settings.lastfmSessionKeyKey, testSessionKey);
  }

  void checkUnchanged(String key) {
    checkPreference(key, _prefsInitialValues[key]);
  }

  void checkAllUnchanged() {
    checkUnchanged(Settings.discogsUsernameKey);
    checkUnchanged(Settings.lastfmUsernameKey);
    checkUnchanged(Settings.lastfmSessionKeyKey);
  }

  Future<void> editAndVerify(WidgetTester tester, String testDiscogsUsername, String testLastfmUsername,
      String testLastfmPassword, String? testSessionKey,
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
    expect(find.byType(TextButton), findsOneWidget);

    expect(find.text(prefs.getString(Settings.discogsUsernameKey)!), findsOneWidget);
    expect(find.text(prefs.getString(Settings.lastfmUsernameKey)!), findsOneWidget);

    // validates empty fields and doesn\'t save

    await tester.pumpWidget(createAccountsWidget());

    await submitForm(tester, '', '', '');
    checkAllUnchanged();

    await submitForm(tester, 'new_discogs_username', '', '');
    expect(find.text(AccountsForm.discogsInvalidUsernameMessage), findsNothing);
    expect(find.text(AccountsForm.lastfmInvalidUsernameMessage), findsOneWidget);
    expect(find.text(AccountsForm.lastfmInvalidPasswordMessage), findsOneWidget);
    checkAllUnchanged();

    await submitForm(tester, '', 'new_lastfm_username', '');
    expect(find.text(AccountsForm.discogsInvalidUsernameMessage), findsNothing); // empty Discogs allowed now
    expect(find.text(AccountsForm.lastfmInvalidUsernameMessage), findsNothing);
    expect(find.text(AccountsForm.lastfmInvalidPasswordMessage), findsOneWidget);
    checkAllUnchanged();

    await submitForm(tester, '', '', 'new_password');
    expect(find.text(AccountsForm.discogsInvalidUsernameMessage), findsNothing); // empty Discogs allowed now
    expect(find.text(AccountsForm.lastfmInvalidUsernameMessage), findsOneWidget);
    expect(find.text(AccountsForm.lastfmInvalidPasswordMessage), findsNothing);
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
