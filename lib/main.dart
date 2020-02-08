import 'package:flutter/material.dart';
import 'package:flutter_user_agent/flutter_user_agent.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/home.dart';
import 'components/onboarding.dart';
import 'components/playlist.dart';
import 'model/discogs.dart';
import 'model/lastfm.dart';
import 'model/playlist.dart';
import 'model/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // initialize logger
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
    if (record.level > Level.INFO && record.stackTrace != null) {
      // ignore: avoid_print
      print(record.stackTrace);
    }
  });

  // initialize user-agent
  var userAgent = 'RecordScrobbler';
  try {
    userAgent = await FlutterUserAgent.getPropertyAsync('userAgent') as String;
    Logger.root.info('Set user agent to: $userAgent');
  } on Exception catch (e, stacktrace) {
    Logger.root.warning('Failed to get User Agent', e, stacktrace);
  }

  // run app
  runApp(MyApp(await SharedPreferences.getInstance(), userAgent));
}

class MyApp extends StatelessWidget {
  const MyApp(this.prefs, this.userAgent);

  final SharedPreferences prefs;
  final String userAgent;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DiscogsSettings>(
          create: (_) => DiscogsSettings(prefs),
        ),
        ChangeNotifierProvider<LastfmSettings>(
          create: (_) => LastfmSettings(prefs),
        ),
        ChangeNotifierProxyProvider<DiscogsSettings, Collection>(
          create: (_) => Collection(userAgent),
          update: (_, settings, collection) =>
              collection..updateUsername(settings.username),
        ),
        ProxyProvider<LastfmSettings, Scrobbler>(
          lazy: false,
          create: (_) => Scrobbler(userAgent),
          update: (_, settings, scrobbler) =>
              scrobbler..updateSessionKey(settings.sessionKey),
        ),
        ChangeNotifierProvider<Playlist>(create: (_) => Playlist()),
      ],
      child: MaterialApp(
        title: 'Record Scrobbler',
        theme: ThemeData(
          primarySwatch: Colors.amber, //blueGrey,
          //brightness: Brightness.dark,
          primaryColor: const Color(0xFF312F2D),
          //accentColor: const Color(0xFFFFC66D),
          //buttonColor: Colors.white,
        ),
        home: StartPage(),
        routes: <String, WidgetBuilder>{
          '/playlist': (_) => PlaylistPage(),
        },
      ),
    );
  }
}

class StartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<DiscogsSettings>(context);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 1000),
        child: (settings.username != null || settings.skipped)
            ? HomePage()
            : OnboardingPage(),
      ),
    );
  }
}
