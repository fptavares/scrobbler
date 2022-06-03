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
  Settings.bluOSEnabledKey: true,
  Settings.bluOSMonitorAddressKey: 'monitor-address',
};

void main() {
  late SharedPreferences prefs;
  late MockScrobbler scrobbler;

  setUp(() async {
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

  Future<void> submitForm(WidgetTester tester, String discogsUsername, String lastfmUsername, String lastfmPassword,
      bool bluosEnabled, String bluosMonitorAddress) async {
    final bluosCheckbox = find.byKey(AccountsForm.bluosEnabledCheckboxKey);
    final bool isBluosEnabledChecked = tester.widget<CheckboxListTile>(bluosCheckbox).value ?? false;
    if (isBluosEnabledChecked != bluosEnabled) {
      await tester.tap(bluosCheckbox);
    }

    await tester.enterText(find.byKey(AccountsForm.discogsUsernameFieldKey), discogsUsername);
    await tester.enterText(find.byKey(AccountsForm.lastfmUsernameFieldKey), lastfmUsername);
    await tester.enterText(find.byKey(AccountsForm.lastfmPasswordFieldKey), lastfmPassword);
    if (bluosEnabled) {
      await tester.enterText(find.byKey(AccountsForm.bluosMonitorFieldKey), bluosMonitorAddress);
    }

    expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed, isNotNull);

    expect(tester.widget<TextButton>(find.byType(TextButton)).enabled, isTrue);

    await tester.tap(find.byType(TextButton));

    await tester.pumpAndSettle();
  }

  void checkStringPreference(String key, Object? expectedValue) {
    expect(prefs.getString(key), equals(expectedValue));
  }

  void checkBoolPreference(String key, Object? expectedValue) {
    expect(prefs.getBool(key), equals(expectedValue));
  }

  void checkPreferences(String testDiscogsUsername, String testLastfmUsername, String? testSessionKey,
      bool testBluOSEnabled, String testBluOSMonitorAddress) {
    checkStringPreference(Settings.discogsUsernameKey, testDiscogsUsername);
    checkStringPreference(Settings.lastfmUsernameKey, testLastfmUsername);
    checkStringPreference(Settings.lastfmSessionKeyKey, testSessionKey);
    checkBoolPreference(Settings.bluOSEnabledKey, testBluOSEnabled);
    checkStringPreference(Settings.bluOSMonitorAddressKey, testBluOSMonitorAddress);
  }

  void checkStringPreferenceUnchanged(String key) {
    checkStringPreference(key, _prefsInitialValues[key]);
  }

  void checkBoolPreferenceUnchanged(String key) {
    checkBoolPreference(key, _prefsInitialValues[key]);
  }

  void checkAllUnchanged() {
    checkStringPreferenceUnchanged(Settings.discogsUsernameKey);
    checkStringPreferenceUnchanged(Settings.lastfmUsernameKey);
    checkStringPreferenceUnchanged(Settings.lastfmSessionKeyKey);
    checkBoolPreferenceUnchanged(Settings.bluOSEnabledKey);
    checkStringPreferenceUnchanged(Settings.bluOSMonitorAddressKey);
  }

  Future<void> editAndVerify(WidgetTester tester, String testDiscogsUsername, String testLastfmUsername,
      String testLastfmPassword, String? testSessionKey, bool testbluOSEnabled, String testbluOSMonitorAddress,
      {bool shouldInitializeSession = true}) async {
    when(scrobbler.initializeSession(any, any)).thenAnswer((_) async {
      if (testSessionKey == null) {
        throw Exception('initializeSession-fail-test');
      }
      return testSessionKey;
    });

    await submitForm(
        tester, testDiscogsUsername, testLastfmUsername, testLastfmPassword, testbluOSEnabled, testbluOSMonitorAddress);

    if (shouldInitializeSession) {
      verify(scrobbler.initializeSession(testLastfmUsername, testLastfmPassword)).called(1);
    } else {
      verifyNever(scrobbler.initializeSession(any, any));
    }

    checkPreferences(
        testDiscogsUsername, testLastfmUsername, testSessionKey, testbluOSEnabled, testbluOSMonitorAddress);
  }

  testWidgets('Accounts form renders, validates and saves settings', (tester) async {
    await tester.pumpWidget(createAccountsWidget());

    expect(find.byType(Form), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.byType(CheckboxListTile), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);

    expect(find.text(prefs.getString(Settings.discogsUsernameKey)!), findsOneWidget);
    expect(find.text(prefs.getString(Settings.lastfmUsernameKey)!), findsOneWidget);
    expect(tester.widget<CheckboxListTile>(find.byKey(AccountsForm.bluosEnabledCheckboxKey)).value, isTrue);
    expect(find.text(prefs.getString(Settings.bluOSMonitorAddressKey)!), findsOneWidget);

    // check if "more info" works

    await tester.tap(find.text('More about BluOS monitor'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('github.com/fptavares/scrobbler/pkgs/bluos_monitor_server', findRichText: true),
        findsOneWidget);
    expect(find.widgetWithText(TextButton, 'OK'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'OK'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);

    // validates empty fields and doesn't save

    await submitForm(tester, '', '', '', false, '');
    checkAllUnchanged();

    await submitForm(tester, 'new_discogs_username', '', '', true, '123:abc');
    expect(find.text(AccountsForm.lastfmInvalidUsernameMessage), findsOneWidget);
    expect(find.text(AccountsForm.lastfmInvalidPasswordMessage), findsOneWidget);
    expect(find.text(AccountsForm.bluosInvalidAddressMessage), findsOneWidget);
    checkAllUnchanged();

    await submitForm(tester, '', 'new_lastfm_username', '', false, '');
    expect(find.text(AccountsForm.lastfmInvalidUsernameMessage), findsNothing);
    expect(find.text(AccountsForm.lastfmInvalidPasswordMessage), findsOneWidget);
    expect(find.text(AccountsForm.bluosInvalidAddressMessage), findsNothing);
    checkAllUnchanged();

    await submitForm(tester, '', '', 'new_password', false, '');
    expect(find.text(AccountsForm.lastfmInvalidUsernameMessage), findsOneWidget);
    expect(find.text(AccountsForm.lastfmInvalidPasswordMessage), findsNothing);
    expect(find.text(AccountsForm.bluosInvalidAddressMessage), findsNothing);
    checkAllUnchanged();

    await submitForm(tester, '', 'new_lastfm_username', 'new_password', true, 'http://invalid!@#%:abc');
    expect(find.text(AccountsForm.lastfmInvalidUsernameMessage), findsNothing);
    expect(find.text(AccountsForm.lastfmInvalidPasswordMessage), findsNothing);
    expect(find.text(AccountsForm.bluosInvalidAddressMessage), findsOneWidget);
    checkAllUnchanged();

    // saves the new account details'

    const errorMessage = 'Exception: initializeSession-fail-test';

    await editAndVerify(tester, 'new_discogs_username_2', 'new_lastfm_username_2', 'new_password_2',
        'new_session_key_2', true, 'new-monitor-address-2:9876');
    expect(find.text(AccountsForm.saveSuccessMessage), findsOneWidget);
    expect(find.text(errorMessage), findsNothing);

    await clearSnackbars(tester);

    // saves new discogs username even if the last.fm password is empty if last.fm username is unchanged

    await editAndVerify(tester, 'new_discogs_username_3', 'new_lastfm_username_2', '', 'new_session_key_2', false,
        'new-monitor-address-2:9876',
        shouldInitializeSession: false);
    expect(find.text(AccountsForm.saveSuccessMessage), findsOneWidget);
    expect(find.text(errorMessage), findsNothing);

    await clearSnackbars(tester);

    // saves new data even if last.fm authentication fails

    await editAndVerify(tester, 'new_discogs_username_4', 'new_lastfm_username_4', 'new_password_4', null, true, '');
    expect(find.text(errorMessage), findsOneWidget);
    expect(find.text(AccountsForm.saveSuccessMessage), findsNothing);

    await clearSnackbars(tester);

    // saves new last.fm account even if the discogs username is empty

    await editAndVerify(tester, '', 'new_lastfm_username_5', 'new_password_5', 'new_session_key_5', false, '');
    expect(find.text(AccountsForm.saveSuccessMessage), findsOneWidget);
    expect(find.text(errorMessage), findsNothing);

    await clearSnackbars(tester);

    // saves BluOS Enabled

    await editAndVerify(tester, '', 'new_lastfm_username_5', '', 'new_session_key_5', true, '',
        shouldInitializeSession: false);
    expect(find.text(AccountsForm.saveSuccessMessage), findsOneWidget);
    expect(find.text(errorMessage), findsNothing);

    await clearSnackbars(tester);

    // saves BluOS monitor address

    await editAndVerify(tester, '', 'new_lastfm_username_5', '', 'new_session_key_5', true, 'new-monitor-address-7',
        shouldInitializeSession: false);
    expect(find.text(AccountsForm.saveSuccessMessage), findsOneWidget);
    expect(find.text(errorMessage), findsNothing);
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
