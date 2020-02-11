import 'package:drs_app/components/accounts.dart';
import 'package:drs_app/model/lastfm.dart';
import 'package:drs_app/model/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Map<String, dynamic> _kPrefsInitialValues = <String, dynamic>{
  DiscogsSettings.discogsUsernameKey: 'd-test-user',
  DiscogsSettings.skippedKey: null,
  LastfmSettings.lastfmUsernameKey: 'l-test-user',
  LastfmSettings.sessionKeyKey: 'session-key',
};

void main() {
  SharedPreferences prefs;
  MockScrobbler scrobbler;
  Widget widget;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(_kPrefsInitialValues);
    prefs = await SharedPreferences.getInstance();
    scrobbler = MockScrobbler();
    widget = MultiProvider(
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
  });

  Widget createAccountsWidget() {
    return widget;
  }

  Future<void> submitForm(WidgetTester tester, String discogsUsername,
      String lastfmUsername, String lastfmPassword) async {
    await tester.enterText(
        find.byKey(AccountsForm.discogsUsernameFieldKey), discogsUsername);
    await tester.enterText(
        find.byKey(AccountsForm.lastfmUsernameFieldKey), lastfmUsername);
    await tester.enterText(
        find.byKey(AccountsForm.lastfmPasswordFieldKey), lastfmPassword);

    expect(tester.widget<FlatButton>(find.byType(FlatButton)).onPressed,
        isNotNull);

    expect(tester.widget<FlatButton>(find.byType(FlatButton)).enabled, isTrue);

    await tester.tap(find.byType(FlatButton));

    await tester.pump();
  }

  void checkPreference(String key, String expectedValue) {
    expect(prefs.getString(key), equals(expectedValue));
  }

  void checkPreferences(String testDiscogsUsername, String testLastfmUsername,
      String testSessionKey) {
    checkPreference(DiscogsSettings.discogsUsernameKey, testDiscogsUsername);
    checkPreference(LastfmSettings.lastfmUsernameKey, testLastfmUsername);
    checkPreference(LastfmSettings.sessionKeyKey, testSessionKey);
  }

  void checkUnchanged(String key) {
    checkPreference(key, _kPrefsInitialValues[key]);
  }

  void checkAllUnchanged() {
    checkUnchanged(DiscogsSettings.discogsUsernameKey);
    checkUnchanged(LastfmSettings.lastfmUsernameKey);
    checkUnchanged(LastfmSettings.sessionKeyKey);
  }

  Future<void> editAndVerify(WidgetTester tester, String testDiscogsUsername, String testLastfmUsername, String testLastfmPassword, String testSessionKey) async {
    when(scrobbler.initializeSession(any, any))
        .thenAnswer((_) async => testSessionKey);

    await submitForm(
        tester, testDiscogsUsername, testLastfmUsername, testLastfmPassword);

    verify(scrobbler.initializeSession(testLastfmUsername, testLastfmPassword))
        .called(1);

    checkPreferences(testDiscogsUsername, testLastfmUsername, testSessionKey);
  }

  testWidgets('Accounts form renders, validates and saves settings', (tester) async {
    await tester.pumpWidget(createAccountsWidget());

    expect(find.byType(Form), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.byType(FlatButton), findsOneWidget);

    expect(find.text(prefs.getString(DiscogsSettings.discogsUsernameKey)),
        findsOneWidget);
    expect(find.text(prefs.getString(LastfmSettings.lastfmUsernameKey)),
        findsOneWidget);

    // validates empty fields and doesn\'t save

    await tester.pumpWidget(createAccountsWidget());

    await submitForm(tester, '', '', '');
    checkAllUnchanged();

    await submitForm(tester, 'new_discogs_username', '', '');
    expect(
        find.text(AccountsForm.lastfmInvalidUsernameMessage), findsOneWidget);
    expect(
        find.text(AccountsForm.lastfmInvalidPasswordMessage), findsOneWidget);
    checkAllUnchanged();

    await submitForm(tester, '', 'new_lastfm_username', '');
    expect(
        find.text(AccountsForm.discogsInvalidUsernameMessage), findsOneWidget);
    expect(
        find.text(AccountsForm.lastfmInvalidPasswordMessage), findsOneWidget);
    checkAllUnchanged();

    await submitForm(tester, '', '', 'new_password');
    expect(
        find.text(AccountsForm.discogsInvalidUsernameMessage), findsOneWidget);
    expect(
        find.text(AccountsForm.lastfmInvalidUsernameMessage), findsOneWidget);
    checkAllUnchanged();

    //saves new usernames even if last.fm authentication fails

    await editAndVerify(tester, 'new_discogs_username_1', 'new_lastfm_username_1', 'new_password_1', null);

    // saves the new account details'

    await editAndVerify(tester, 'new_discogs_username_2', 'new_lastfm_username_2', 'new_password_2', 'new_session_key_2');
  });
}

// Mock classes
class MockScrobbler extends Mock implements Scrobbler {}
