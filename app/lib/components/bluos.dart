import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:scrobbler_bluos_monitor/scrobbler_bluos_monitor.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/analytics.dart';
import '../model/bluos.dart';
import '../model/lastfm.dart';
import '../model/settings.dart';
import 'album.dart';
import 'emtpy.dart';
import 'error.dart';
import 'rating.dart';

class BluosFloatingButton extends StatelessWidget {
  const BluosFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<Settings>(context);
    final bluos = Provider.of<BluOS>(context);

    if (!settings.isBluOSEnabled) {
      return Container();
    }

    return FloatingActionButton(
      onPressed: () => _handleClick(context),
      tooltip: bluos.isPolling ? 'Listening on ${bluos.playerName ?? 'BluOS device'}' : 'BluOS',
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      shape: StadiumBorder(side: BorderSide(color: bluos.isPolling ? Colors.redAccent : Colors.amberAccent, width: 3)),
      heroTag: null,
      //child: const Icon(Icons.speaker_group, size: 28),
      child: const ClipOval(child: Image(image: AssetImage('assets/bluos_small.png'))),
    );
  }

  Future<void> _handleClick(BuildContext context) async {
    final bluos = Provider.of<BluOS>(context, listen: false);
    unawaited(bluos.refresh());

    Scaffold.of(context).openEndDrawer();
  }
}

class BluOSMonitorControl extends StatefulWidget {
  const BluOSMonitorControl({super.key});

  @override
  BluOSMonitorControlState createState() => BluOSMonitorControlState();

  static const noPlayerFoundErrorMessage = 'No BluOS players were found in your network.';
}

class BluOSMonitorControlState extends State<BluOSMonitorControl> with SingleTickerProviderStateMixin {
  static final Logger _log = Logger('BluosPlaylistEditor');

  final Map<int, bool> _includeMask = {};
  BluOSPlayer? _selectedPlayer;
  List<BluOSPlayer>? _availablePlayers;
  bool _isScanningPlayers = false;

  late AnimationController _refreshrotationController;

  @override
  void initState() {
    _refreshrotationController = AnimationController(duration: const Duration(seconds: 3), vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _refreshrotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<Settings>(context, listen: false);
    _selectedPlayer ??= settings.bluOSPlayer;

    return Consumer<BluOS>(
      builder: (context, bluos, _) {
        final playlist = bluos.playlist.reversed.toList();
        final toScrobbleCount = _getTracksToScrobble(playlist).length;
        final toClearCount = _getTracksToClear(playlist).length;

        if (!bluos.canReload && bluos.isPolling) {
          if (!_refreshrotationController.isAnimating) {
            _refreshrotationController.repeat();
          }
        } else {
          _refreshrotationController.reset();
        }

        return Scaffold(
          appBar: AppBar(
            leading: const CloseButton(),
            title: bluos.isPolling
                ? FittedBox(fit: BoxFit.fitWidth, child: Text('Listening on ${bluos.playerName ?? 'BluOS device'}'))
                : const Image(image: AssetImage('assets/bluos_small.png'), height: 45),
            actions: [
              RotationTransition(
                turns: Tween(begin: 0.0, end: 1.0).animate(_refreshrotationController),
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: bluos.canReload ? 'Refresh' : null,
                  onPressed:
                      bluos.canReload ? () => handleFutureError(bluos.refresh(), _log, trace: 'bluos_refresh') : null,
                ),
              )
            ],
          ),
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: bluos.isLoading
                      ? Center(child: CircularProgressIndicator(backgroundColor: Theme.of(context).primaryColor))
                      : !bluos.isPolling && playlist.isEmpty
                          ? const EmptyState(
                              imagePath: 'assets/empty_playlist.png',
                              subhead: 'Start monitoring a BluOS device to scrobble the tracks that are played there.',
                            )
                          : _createPlaylistEditor(context, playlist, toScrobbleCount),
                ),
                const Divider(),
                if (bluos.errorMessage != null && bluos.isPolling) _createErrorTile(context, bluos.errorMessage),
                if (!bluos.isPolling) _createPlayerSelector(context, bluos),
                _createControlButtonsTile(context, bluos, playlist, toScrobbleCount, toClearCount),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _createPlaylistEditor(BuildContext context, List<BluOSTrack> playlist, int toScrobbleCount) {
    return ListView(
      controller: ScrollController(),
      children: <Widget>[
        DataTable(
          horizontalMargin: 15,
          headingTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          columns: <DataColumn>[
            DataColumn(
              label: Text('Tracks to Scrobble ($toScrobbleCount)'),
            ),
            const DataColumn(label: Text('')),
          ],
          rows: List<DataRow>.generate(playlist.length, (index) {
            final track = playlist[index];

            return DataRow(
              color: MaterialStateProperty.resolveWith<Color?>((states) {
                // All rows will have the same selected color.
                if (states.contains(MaterialState.selected)) {
                  return Theme.of(context).colorScheme.primary.withOpacity(0.10);
                }
                // Even rows will have a grey color.
                if (index.isEven) {
                  return Colors.grey.withOpacity(0.1);
                }
                return null; // Use default value for other states and odd rows.
              }),
              cells: <DataCell>[
                DataCell(Text('${track.artist} - ${track.title}')),
                DataCell((track.imageUrl != null)
                    ? CachedNetworkImage(
                        imageUrl: track.imageUrl!,
                        height: 35,
                        width: 35,
                        imageBuilder: (context, image) => Tooltip(
                          message: track.album ?? '',
                          child: AlbumImage(image: image),
                        ),
                      )
                    : Container())
              ],
              selected: _isIncluded(track),
              onSelectChanged: track.isScrobbable ? (value) => _setIncluded(track, value) : null,
            );
          }),
        ),
      ],
    );
  }

  Widget _createErrorTile(BuildContext context, String? message) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.error, color: Colors.red),
      title: Text(message ?? ''),
    );
  }

  Widget _createPlayerSelector(BuildContext context, BluOS bluos) {
    return ListTile(
      dense: true,
      title: _isScanningPlayers
          ? const LinearProgressIndicator()
          : DropdownButton<BluOSPlayer>(
              hint: Text(_selectedPlayer != null ? _selectedPlayer!.name : 'Scan for players'),
              value: _selectedPlayer,
              icon: const Icon(Icons.speaker),
              isExpanded: true,
              onChanged: (newValue) {
                setState(() {
                  _selectedPlayer = newValue!;
                });
              },
              items: _availablePlayers?.map<DropdownMenuItem<BluOSPlayer>>((player) {
                return DropdownMenuItem<BluOSPlayer>(
                  value: player,
                  child: Text(player.name),
                );
              }).toList(),
            ),
      trailing: TextButton.icon(
        icon: const Icon(Icons.search),
        label: const Text('Scan'),
        onPressed: _isScanningPlayers ? null : () => _handleScan(context, bluos),
      ),
    );
  }

  Widget _createControlButtonsTile(
      BuildContext context, BluOS bluos, List<BluOSTrack> playlist, int toScrobbleCount, int toClearCount) {
    return ListTile(
      trailing: (bluos.isPolling)
          ? TextButton.icon(
              icon: const Icon(Icons.stop, size: 20),
              label: const Text('Stop'),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
              ),
              onPressed: bluos.isLoading ? null : () => _handleStop(bluos),
            )
          : TextButton.icon(
              icon: const Icon(Icons.start, size: 20),
              label: const Text('Start'),
              style: ButtonStyle(
                foregroundColor:
                    _selectedPlayer == null || bluos.isLoading ? null : MaterialStateProperty.all<Color>(Colors.white),
                backgroundColor: MaterialStateProperty.all<Color>(Colors.redAccent),
              ),
              onPressed: _selectedPlayer == null || bluos.isLoading
                  ? null
                  : () => _handleStart(context, bluos, _selectedPlayer!),
            ),
      title: TextButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.amberAccent),
        ),
        onPressed: bluos.isLoading || (toScrobbleCount == 0 && toClearCount == 0)
            ? null
            : () => _handleSubmit(context, bluos, playlist),
        child: toScrobbleCount > 0
            ? Text('Submit $toScrobbleCount track${toScrobbleCount == 1 ? '' : 's'}')
            : toClearCount > 0
                ? Text('Clear $toClearCount track${toClearCount == 1 ? '' : 's'}')
                : const Text('Submit'),
      ),
    );
  }

  Future<void> _handleStop(BluOS bluos) async {
    await handleFutureError(bluos.stop(), _log, trace: 'bluos_stop');
  }

  Future<void> _handleStart(BuildContext context, BluOS bluos, BluOSPlayer player) async {
    final settings = Provider.of<Settings>(context, listen: false);
    settings.bluOSPlayer = player;

    analytics.logStartBluOS(bluos.isExternal);

    // show warning for the first time, only if direct monitor
    if (!bluos.isExternal && !settings.isBluOSWarningShown) {
      await showAboutBluOSMonitor(context, settings);
    }

    await handleFutureError(bluos.start(player.host, player.port, player.name), _log, trace: 'bluos_start');
  }

  Future<void> _handleScan(BuildContext context, BluOS bluos) async {
    setState(() {
      _isScanningPlayers = true;
    });
    final players = await handleFutureError(bluos.lookupBluOSPlayers(), _log, trace: 'bluos_discovery');

    if (!mounted) return;

    setState(() {
      _isScanningPlayers = false;
      _availablePlayers = players;
      if (players != null && players.isNotEmpty) {
        _selectedPlayer = players.first;
      }
    });
    if (players != null && players.isEmpty) {
      displayError(BluOSMonitorControl.noPlayerFoundErrorMessage);
    }
  }

  Future<void> _handleSubmit(BuildContext context, BluOS bluos, List<BluOSTrack> playlist) async {
    final scrobbler = Provider.of<Scrobbler>(context, listen: false);

    try {
      var tracksWereScrobbled = false;
      final tracksToScrobble = _getTracksToScrobble(playlist).toList();

      if (tracksToScrobble.isNotEmpty) {
        analytics.logScrobbleBluOS(numberOfTracks: tracksToScrobble.length);

        await for (int accepted in scrobbler.scrobbleBluOSTracks(tracksToScrobble)) {
          displaySuccess('Scrobbled $accepted track${accepted != 1 ? 's' : ''} successfuly.');
          tracksWereScrobbled |= accepted > 0;
        }
      }

      final latestTimestamp = playlist
          .where((track) => track.isScrobbable)
          .fold<int>(0, (max, track) => track.timestamp > max ? track.timestamp : max);

      await bluos.clear(latestTimestamp);

      _resetIncluded();

      if (tracksWereScrobbled) {
        unawaited(ReviewRequester.instance.tryToAskForAppReview());
      }
    } catch (e, stackTrace) {
      displayAndLogError(_log, e, stackTrace, 'There was an error while trying to submit the tracks to Last.fm.');
    }
  }

  void _resetIncluded() {
    setState(() {
      _includeMask.clear();
    });
  }

  void _setIncluded(BluOSTrack track, bool? included) {
    setState(() {
      _includeMask[track.timestamp] = included ?? false;
    });
  }

  bool _isIncluded(BluOSTrack track) {
    return track.isScrobbable && (_includeMask[track.timestamp] ?? true); // include by default
  }

  bool _isExcluded(BluOSTrack track) {
    return track.isScrobbable && !(_includeMask[track.timestamp] ?? true); // include by default
  }

  Iterable<BluOSTrack> _getTracksToScrobble(List<BluOSTrack> tracks) {
    return tracks.where(_isIncluded);
  }

  Iterable<BluOSTrack> _getTracksToClear(List<BluOSTrack> tracks) {
    return tracks.where(_isExcluded);
  }
}

Future<void> showAboutBluOSMonitor(BuildContext context, Settings settings) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Monitoring BluOS players'),
        content: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                text:
                    'Unfortunately, the app by itself can only monitor what\'s being played on another device while the app is open.\n\n'
                    'So you\'ll need to keep the app open for it to receive updates from the BluOS player.\n\n'
                    'To monitor tracks played even if the app is closed, you can optionally run a separate server that will monitor the BluOS player independently of the app.\n\n'
                    'For more information, and instructions on how to install this, please go to ',
              ),
              TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blue),
                text: 'github.com/fptavares/scrobbler/wiki/BluOS',
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    final url = Uri.https('github.com', '/fptavares/scrobbler/wiki/BluOS');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      );
    },
  );
  settings.isBluOSWarningShown = true;
}
