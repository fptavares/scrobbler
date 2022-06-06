import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:scrobbler/components/bluos.dart';
import 'package:scrobbler/components/error.dart';
import 'package:scrobbler/model/bluos.dart';
import 'package:scrobbler/model/lastfm.dart';
import 'package:scrobbler/model/settings.dart';
import 'package:scrobbler_bluos_monitor/scrobbler_bluos_monitor.dart';

import '../bluos_test_data.dart';
import '../mocks/firebase_mocks.dart';
import '../mocks/model_mocks.dart';

void main() {
  MockBluOS initBluOS() {
    final bluos = createMockBluOSMonitor();
    when(bluos.isExternal).thenReturn(true);
    return bluos;
  }

  MockScrobbler initScrobbler() {
    return createMockScrobbler();
  }

  setUpAll(() {
    replaceFirebaseWithMocks();
  });

  group('BluOS button', () {
    Future<Settings> pumpButton(WidgetTester tester, BluOS bluos, Scrobbler scrobbler, {bool? visible}) async {
      final settings = createMockSettings(isBluOSEnabled: visible ?? true);

      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<Scrobbler>.value(
            value: scrobbler,
          ),
          ChangeNotifierProvider<BluOS>.value(
            value: bluos,
          ),
          ChangeNotifierProvider<Settings>.value(
            value: settings,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Container(),
            floatingActionButton: const BluosFloatingButton(),
            endDrawer: const Text('End Drawer Here'),
          ),
          scaffoldMessengerKey: scrobblerScaffoldMessengerKey,
        ),
      ));

      return settings;
    }

    testWidgets('renders only if BluOS is enabled', (tester) async {
      final scrobbler = initScrobbler();
      final bluos = initBluOS();
      when(bluos.isPolling).thenReturn(false);

      await pumpButton(tester, bluos, scrobbler, visible: false);

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byType(Image), findsNothing);

      await pumpButton(tester, bluos, scrobbler, visible: true);

      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('triggers status refresh on tap', (tester) async {
      final scrobbler = initScrobbler();
      final bluos = initBluOS();
      when(bluos.canReload).thenReturn(true);
      when(bluos.isPolling).thenReturn(false);

      createMockSettings(isBluOSEnabled: true);

      await pumpButton(tester, bluos, scrobbler);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      verify(bluos.refresh()).called(1);
    });

    testWidgets('opens end drawer where the BluOS controls are located', (tester) async {
      final scrobbler = initScrobbler();
      final bluos = initBluOS();
      when(bluos.canReload).thenReturn(true);
      when(bluos.isPolling).thenReturn(false);

      await pumpButton(tester, bluos, scrobbler);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.text('End Drawer Here'), findsOneWidget);
    });
  });

  group('BluOS widget', () {
    Future<Settings> pumpBluOSWidget(WidgetTester tester, BluOS bluos, Scrobbler scrobbler,
        [Settings? mockSettings]) async {
      final settings = mockSettings ?? createMockSettings();

      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<Scrobbler>.value(
            value: scrobbler,
          ),
          ChangeNotifierProvider<BluOS>.value(
            value: bluos,
          ),
          ChangeNotifierProvider<Settings>.value(
            value: settings,
          ),
        ],
        child: MaterialApp(
          home: const Scaffold(
            body: BluOSMonitorControl(),
          ),
          scaffoldMessengerKey: scrobblerScaffoldMessengerKey,
        ),
      ));

      return settings;
    }

    testWidgets('renders properly', (tester) async {
      final scrobbler = initScrobbler();
      final bluos = initBluOS();
      when(bluos.canReload).thenReturn(true);
      when(bluos.isPolling).thenReturn(false);
      when(bluos.isLoading).thenReturn(false);
      when(bluos.errorMessage).thenReturn(null);
      when(bluos.playlist).thenReturn(BluOSTestData.listOfBluOSMonitorTracks);

      await pumpBluOSWidget(tester, bluos, scrobbler);

      expect(find.byType(BluOSMonitorControl), findsOneWidget);
      for (final track in BluOSTestData.listOfBluOSMonitorTracks) {
        expect(find.bluOSTrack(track), findsOneWidget);
      }
      expect(find.byType(CachedNetworkImage),
          findsNWidgets(BluOSTestData.listOfBluOSMonitorTracks.length - 1)); // one is missing the imageUrl

      expect(find.byType(CloseButton), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
    });

    testWidgets('scans the network for players and starts', (tester) async {
      final scrobbler = initScrobbler();
      final bluos = initBluOS();
      when(bluos.canReload).thenReturn(false);
      when(bluos.isPolling).thenReturn(false);
      when(bluos.isLoading).thenReturn(false);
      when(bluos.errorMessage).thenReturn(null);
      when(bluos.playlist).thenReturn([]);

      final players = List.generate(3, (index) => BluOSPlayer('Player$index', 'host$index', index));

      when(bluos.lookupBluOSPlayers()).thenAnswer((_) => Future.value(players));

      await pumpBluOSWidget(tester, bluos, scrobbler);

      await tester.tap(find.text('Start'));
      await tester.pump();

      verifyNever(bluos.start(any, any, any)); // button should be disabled

      expect(find.text('Scan for players'), findsOneWidget);

      await tester.tap(find.text('Scan'));
      await tester.pump();

      verify(bluos.lookupBluOSPlayers());

      for (final player in players) {
        expect(find.widgetWithText(DropdownMenuItem<BluOSPlayer>, player.name), findsOneWidget);
      }

      expect(find.text('Scan for players'), findsNothing);

      await tester.tap(find.byType(DropdownButton<BluOSPlayer>));
      await tester.pumpAndSettle();

      final lastPlayer = players.last;

      await tester.tap(find.widgetWithText(DropdownMenuItem<BluOSPlayer>, lastPlayer.name).last, warnIfMissed: false);
      await tester.pump();

      await tester.tap(find.text('Start'));
      await tester.pump();

      verify(bluos.start(lastPlayer.host, lastPlayer.port, lastPlayer.name));
    });

    testWidgets('prefills the last used BluOS player', (tester) async {
      final scrobbler = initScrobbler();
      final bluos = initBluOS();
      when(bluos.canReload).thenReturn(true);
      when(bluos.isPolling).thenReturn(false);
      when(bluos.isLoading).thenReturn(false);
      when(bluos.errorMessage).thenReturn(null);
      when(bluos.playlist).thenReturn([]);

      final settings = createMockSettings(
        bluOSPlayer: const BluOSPlayer('Player name', 'player', 1234),
        isBluOSWarningShown: true,
      );

      await pumpBluOSWidget(tester, bluos, scrobbler, settings);

      expect(find.text('Scan for players'), findsNothing);
      expect(find.text('Player name'), findsOneWidget);

      await tester.tap(find.text('Start'));
      await tester.pump();

      verify(bluos.start('player', 1234, 'Player name'));
    });

    testWidgets('shows warning before starting the first time', (tester) async {
      final scrobbler = initScrobbler();
      final bluos = initBluOS();
      when(bluos.canReload).thenReturn(false);
      when(bluos.isPolling).thenReturn(false);
      when(bluos.isLoading).thenReturn(false);
      when(bluos.errorMessage).thenReturn(null);
      when(bluos.playlist).thenReturn([]);

      when(bluos.isExternal).thenReturn(false);

      final settings = createMockSettings(
        bluOSPlayer: const BluOSPlayer('Player name', 'player', 1234),
      );

      await pumpBluOSWidget(tester, bluos, scrobbler, settings);

      expect(settings.isBluOSWarningShown, isFalse);

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('github.com/fptavares/scrobbler/wiki/BluOS', findRichText: true), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'OK'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'OK'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verify(settings.isBluOSWarningShown = true);
    });

    testWidgets('does not show warning before starting the next time', (tester) async {
      final scrobbler = initScrobbler();
      final bluos = initBluOS();
      when(bluos.canReload).thenReturn(false);
      when(bluos.isPolling).thenReturn(false);
      when(bluos.isLoading).thenReturn(false);
      when(bluos.errorMessage).thenReturn(null);
      when(bluos.playlist).thenReturn([]);

      when(bluos.isExternal).thenReturn(false);

      final settings = createMockSettings(
        bluOSPlayer: const BluOSPlayer('Player name', 'player', 1234),
        isBluOSWarningShown: true,
      );

      await pumpBluOSWidget(tester, bluos, scrobbler, settings);

      expect(settings.isBluOSWarningShown, isTrue);

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('github.com/fptavares/scrobbler/wiki/BluOS', findRichText: true), findsNothing);

      expect(settings.isBluOSWarningShown, isTrue);

      verify(bluos.start('player', 1234, 'Player name'));
    });

    testWidgets('show error when no players are found in the network', (tester) async {
      final scrobbler = initScrobbler();
      final bluos = initBluOS();
      when(bluos.canReload).thenReturn(false);
      when(bluos.isPolling).thenReturn(false);
      when(bluos.isLoading).thenReturn(false);
      when(bluos.errorMessage).thenReturn(null);
      when(bluos.playlist).thenReturn([]);

      when(bluos.lookupBluOSPlayers()).thenAnswer((_) => Future.value([]));

      await pumpBluOSWidget(tester, bluos, scrobbler);

      expect(find.text('Scan for players'), findsOneWidget);

      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();

      expect(find.text(BluOSMonitorControl.noPlayerFoundErrorMessage), findsOneWidget);

      verify(bluos.lookupBluOSPlayers());
    });

    testWidgets('show error when returned by the monitor', (tester) async {
      final scrobbler = initScrobbler();
      final bluos = initBluOS();
      when(bluos.canReload).thenReturn(false);
      when(bluos.isPolling).thenReturn(true);
      when(bluos.isLoading).thenReturn(false);
      when(bluos.playerName).thenReturn('Player name');
      const errorMessage = 'My test error message!';
      when(bluos.errorMessage).thenReturn(errorMessage);
      when(bluos.playlist).thenReturn([]);

      when(bluos.lookupBluOSPlayers()).thenAnswer((_) => Future.value([]));

      await pumpBluOSWidget(tester, bluos, scrobbler);

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('allows status refresh for extenal monitors', (tester) async {
      final scrobbler = initScrobbler();
      final bluos = initBluOS();
      when(bluos.isPolling).thenReturn(true);
      when(bluos.isLoading).thenReturn(false);
      when(bluos.playerName).thenReturn('Player name');
      when(bluos.errorMessage).thenReturn(null);
      when(bluos.playlist).thenReturn(BluOSTestData.listOfBluOSMonitorTracks);

      when(bluos.canReload).thenReturn(true);

      await pumpBluOSWidget(tester, bluos, scrobbler);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      verify(bluos.refresh());
    });

    testWidgets('doesn\'t allow status refresh for API client', (tester) async {
      final scrobbler = initScrobbler();
      final bluos = initBluOS();
      when(bluos.isPolling).thenReturn(true);
      when(bluos.isLoading).thenReturn(false);
      when(bluos.playerName).thenReturn('Player name');
      when(bluos.errorMessage).thenReturn(null);
      when(bluos.playlist).thenReturn(BluOSTestData.listOfBluOSMonitorTracks);

      when(bluos.canReload).thenReturn(false);

      await pumpBluOSWidget(tester, bluos, scrobbler);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      verifyNever(bluos.refresh());
    });

    testWidgets('allows scrobbling selected tracks', (tester) async {
      final scrobbler = initScrobbler();
      final bluos = initBluOS();
      when(bluos.canReload).thenReturn(true);
      when(bluos.isPolling).thenReturn(true);
      when(bluos.isLoading).thenReturn(false);
      when(bluos.playerName).thenReturn('Player name');
      when(bluos.errorMessage).thenReturn(null);
      when(scrobbler.scrobbleBluOSTracks(any)).thenAnswer((_) => Stream.value(1));

      final playlist = BluOSTestData.listOfBluOSMonitorTracks;
      when(bluos.playlist).thenReturn(playlist);

      await pumpBluOSWidget(tester, bluos, scrobbler);

      for (final track in playlist) {
        expect(find.bluOSTrack(track), findsOneWidget);
      }

      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
      expect(find.text('Start'), findsNothing);
      expect(find.text('Scan'), findsNothing);

      await tester.tap(find.text('Submit'));
      await tester.pump();

      verify(scrobbler.scrobbleBluOSTracks(playlist.sublist(0, 2))); // third track is not scrobbable

      await tester.tap(find.bluOSTrack(playlist.first));
      await tester.pump();

      await tester.tap(find.bluOSTrack(playlist.last));
      await tester.pump();

      await tester.tap(find.text('Submit'));
      await tester.pump();

      verify(scrobbler.scrobbleBluOSTracks([playlist[1]])); // only middle (second) track remained selected
    });
  });
}

extension BluOSFinders on CommonFinders {
  Finder bluOSTrack(BluOSTrack track) => text('${track.artist} - ${track.title}');
}
