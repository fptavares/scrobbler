import 'package:drs_app/components/home.dart';
import 'package:drs_app/components/playlist.dart';
import 'package:drs_app/model/discogs.dart';
import 'package:drs_app/model/lastfm.dart';
import 'package:drs_app/model/playlist.dart';
import 'package:drs_app/model/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_user_agent/flutter_user_agent.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/onboarding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String userAgent = 'RecordScrobbler';
  try {
    userAgent = await FlutterUserAgent.getPropertyAsync('userAgent');
    print('Set user agent to: $userAgent');
  } catch(e, stacktrace) {
    print('Failed to get User Agent: $e');
    print(stacktrace);
  }

  runApp(MyApp(await SharedPreferences.getInstance(), userAgent));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final String userAgent;

  MyApp(this.prefs, this.userAgent);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DiscogsSettings(prefs)),
        ChangeNotifierProvider(create: (_) => LastfmSettings(prefs)),
        ChangeNotifierProxyProvider<DiscogsSettings, Collection>(
          create: (_) => Collection(userAgent),
          update: (_, settings, collection) =>
              collection..updateUsername(settings.username),
        ),
        ProxyProvider<LastfmSettings, Scrobbler>(
          lazy: false,
          create: (_) => Scrobbler(userAgent),
          update: (_, settings, scrobbler) =>
              scrobbler..sessionKey = settings.sessionKey,
        ),
        ChangeNotifierProvider(create: (_) => Playlist()),
        //ChangeNotifierProvider(create: (_) => Scrobbler()),
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
          '/playlist': (context) => PlaylistPage(),
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
      body: (settings.username != null || settings.skipped)
          ? HomePage()
          : OnboardingPage(),
    );
  }
}
