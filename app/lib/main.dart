import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/error.dart';
import 'components/home.dart';
import 'components/onboarding.dart';
import 'components/playlist.dart';
import 'firebase_options.dart';
import 'model/analytics.dart';
import 'model/bluos.dart';
import 'model/discogs.dart';
import 'model/lastfm.dart';
import 'model/playlist.dart';
import 'model/settings.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (!kIsWeb) {
      // Pass all uncaught errors from the framework to Crashlytics.
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
      Isolate.current.addErrorListener(RawReceivePort((pair) async {
        final List<dynamic> errorAndStacktrace = pair;
        await FirebaseCrashlytics.instance.recordError(
          errorAndStacktrace.first,
          errorAndStacktrace.last,
        );
      }).sendPort);

      if (Platform.isMacOS) {
        ScrobblerAnalytics.instance.performanceEnabled = false;
      }
    }

    // initialize logger
    const isProduction = bool.fromEnvironment('dart.vm.product');
    if (isProduction) {
      Logger.root.level = Level.WARNING;
      Logger.root.onRecord.listen((record) {
        analytics.logException('${record.level.name}: record.message}');
        if (record.error != null) {
          FirebaseCrashlytics.instance.recordError(record.error, record.stackTrace);
        }
      });
    } else {
      Logger.root.level = Level.INFO; // defaults to Level.INFO
      Logger.root.onRecord.listen((record) {
        print('[${record.level.name}] ${record.loggerName}: ${record.message}'); // ignore: avoid_print
        if (record.level > Level.INFO) {
          if (record.error != null) {
            print('Error: ${record.error}'); // ignore: avoid_print
          }
          if (record.stackTrace != null) {
            print(record.stackTrace); // ignore: avoid_print
          }
        }
      });
    }

    // create user-agent
    var userAgent = 'Scrobbler';
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      final version = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;

      userAgent = 'Scrobbler/$version+$buildNumber';

      Logger.root.info('Set user agent to: $userAgent');
    } on Exception catch (e, st) {
      Logger.root.warning('Failed to get package info for user agent', e, st);
    }

    final prefs = await SharedPreferences.getInstance();

    // run app
    runApp(ScrobblerApp(prefs, userAgent));
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack));
}

class ScrobblerApp extends StatelessWidget {
  const ScrobblerApp(this.prefs, this.userAgent, {super.key});

  final SharedPreferences prefs;
  final String userAgent;

  @override
  Widget build(BuildContext context) {
    analytics.logAppOpen();

    final theme = ThemeData();

    const primaryColor = Color(0xFF2a241a);
    const secondaryColor = Colors.amber;
    const disabledColor = Colors.white30;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<Settings>(
          create: (_) => Settings(prefs),
        ),
        ChangeNotifierProxyProvider<Settings, Collection?>(
          create: (_) => Collection(userAgent),
          update: (_, settings, collection) => collection
            ?..updateUsername(settings.discogsUsername).catchError(
                (e, stackTrace) => Logger.root.warning('Exception while updating username.', e, stackTrace)),
        ),
        ProxyProvider<Settings, Scrobbler?>(
          lazy: false,
          create: (_) => Scrobbler(userAgent),
          update: (_, settings, scrobbler) => scrobbler?..updateSessionKey(settings.lastfmSessionKey),
        ),
        ChangeNotifierProxyProvider<Settings, BluOS?>(
          create: (_) => BluOS(),
          update: (_, settings, bluos) => bluos
            ?..updateMonitorAddress(settings.bluOSMonitorAddress)
            ..refresh(),
        ),
        ChangeNotifierProvider<Playlist>(create: (_) => Playlist()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Scrobbler',
        theme: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: primaryColor,
            secondary: secondaryColor,
          ),
          primaryColor: primaryColor,
          disabledColor: disabledColor,
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            circularTrackColor: primaryColor,
            color: secondaryColor,
            linearTrackColor: disabledColor,
            refreshBackgroundColor: secondaryColor,
          ),
          tooltipTheme: const TooltipThemeData(waitDuration: Duration(milliseconds: 700)),
        ),
        home: const StartPage(),
        routes: <String, WidgetBuilder>{
          '/playlist': (_) => const PlaylistPage(),
        },
        navigatorObservers: [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
        scaffoldMessengerKey: scrobblerScaffoldMessengerKey,
      ),
    );
  }
}

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<Settings>(context);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 1000),
        child: (settings.discogsUsername != null || settings.isSkipped) ? const HomePage() : const OnboardingPage(),
      ),
    );
  }
}
