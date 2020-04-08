import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../model/analytics.dart';
import '../model/discogs.dart';
import '../model/lastfm.dart';
import '../model/playlist.dart';
import 'album.dart';
import 'error.dart';

class ScrobbleFloatingButton extends StatelessWidget {
  ScrobbleFloatingButton({
    Key key,
  }) : super(key: key);

  final Logger log = Logger('ScrobbleFloatingButton');

  @override
  Widget build(BuildContext context) {
    final playlist = Provider.of<Playlist>(context);

    if (playlist.isEmpty) {
      return Container();
    }

    return FloatingActionButton(
      onPressed: playlist.isScrobbling
          ? null
          : () => handleScrobble(context, playlist),
      tooltip: 'Scrobble',
      backgroundColor:
          playlist.isScrobbling ? Theme.of(context).primaryColor : null,
      child: playlist.isScrobblingPaused
          ? Container()
          : playlist.isScrobbling
              ? const CircularProgressIndicator()
              : Icon(Icons.play_arrow),
    );
  }

  Future<void> handleScrobble(BuildContext context, Playlist playlist) async {
    final scrobbler = Provider.of<Scrobbler>(context, listen: false);
    final collection = Provider.of<Collection>(context, listen: false);

    analytics.logScrobbleOptionsOpen(
        numberOfAlbums: playlist.numberOfItems,
        maxCount: playlist.maxItemCount());

    try {
      await for (int accepted in playlist.scrobble(scrobbler, collection,
          (albums) => showPlaylistOptionsDialog(context, albums))) {
        displaySuccess(context, 'Scrobbled $accepted tracks successfuly.');
      }
    } on Exception catch (e, stackTrace) {
      displayAndLogError(context, log, e, stackTrace);
    }
  }

  static Future<ScrobbleOptions> showPlaylistOptionsDialog(
      BuildContext context, List<AlbumDetails> albums) async {
    return showModalBottomSheet<ScrobbleOptions>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => DraggableScrollableSheet(
        //initialChildSize: 0.3,
        maxChildSize: 0.9,
        //minChildSize: 0.3,
        builder: (context, scrollController) {
          return Container(
            color: Colors.white,
            child: SafeArea(
              child: ScrobblePlaylistEditor(
                albums: albums,
                scrollController: scrollController,
              ),
            ),
          );
        },
      ),
    );
  }
}

class ScrobblePlaylistEditor extends StatefulWidget {
  const ScrobblePlaylistEditor({
    Key key,
    @required this.albums,
    @required this.scrollController,
  }) : super(key: key);

  final List<AlbumDetails> albums;
  final ScrollController scrollController;

  @override
  _ScrobblePlaylistEditorState createState() => _ScrobblePlaylistEditorState();

  @visibleForTesting
  static String whenTooltipMessage = 'When you finished listening to the albums';
}

class _ScrobblePlaylistEditorState extends State<ScrobblePlaylistEditor> {
  final Map<int, Map<int, bool>> _includeMask = {};
  int _timeOffsetIndex = 0;

  final _whenToolTipKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final positionStyle = Theme.of(context).textTheme.body2;
    final titleStyle = Theme.of(context).textTheme.body1;
    final excludedTitleStyle = Theme.of(context)
        .textTheme
        .body1
        .copyWith(decoration: TextDecoration.lineThrough);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppBar(
          leading: const CloseButton(),
          title: Text(
              'Scrobbling ${widget.albums.length} album${widget.albums.length == 1 ? '' : 's'}'),
        ),
        Flexible(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: widget.albums.length,
            itemBuilder: (context, albumIndex) {
              final album = widget.albums[albumIndex];
              return ExpansionTile(
                leading: CachedAlbumImage(album),
                title: Text(
                  album.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(album.artist),
                children: album.tracks
                    .asMap()
                    .entries
                    .map(
                      (track) => CheckboxListTile(
                        dense: true,
                        isThreeLine: false,
                        secondary: Text(track.value.position ?? '',
                            style: positionStyle),
                        title: Text(track.value.title,
                            style: _getMask(albumIndex, track.key)
                                ? titleStyle
                                : excludedTitleStyle),
                        value: _getMask(albumIndex, track.key),
                        onChanged: (value) =>
                            _setMask(albumIndex, track.key, value),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
        const Divider(),
        ListTile(
          dense: true,
          leading: GestureDetector(
            onTap: () {
              final dynamic tooltip = _whenToolTipKey.currentState;
              tooltip.ensureTooltipVisible();
            },
            child: Tooltip(
              key: _whenToolTipKey,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Text('When?'),
                  Icon(Icons.info_outline, size: 20, color: Colors.grey[300]),
                ],
              ),
              message: ScrobblePlaylistEditor.whenTooltipMessage,
            ),
          ),
          title: Slider(
            value: _timeOffsetIndex.toDouble(),
            onChanged: (newTime) =>
                setState(() => _timeOffsetIndex = newTime.round()),
            min: 0,
            max: (_timeOffsetValues.length - 1).toDouble(),
            divisions: _timeOffsetValues.length - 1,
            label: _timeOffsetLabels[_timeOffsetIndex],
          ),
        ),
        ListTile(
          title: FlatButton(
            color: Theme.of(context).accentColor,
            child: const Text('Submit'),
            onPressed: () => _handleSubmit(context),
          ),
        ),
      ],
    );
  }

  void _handleSubmit(BuildContext context) {
    final offsetInMinutes = _timeOffsetValues[_timeOffsetIndex];

    Navigator.pop(
      context,
      ScrobbleOptions(
        inclusionMask: _includeMask,
        offsetInSeconds: offsetInMinutes * 60,
      ),
    );

    analytics.logScrobbling(
        numberOfAlbums: widget.albums.length,
        numberOfExclusions: _numberOfExclusions(),
        offsetInMinutes: offsetInMinutes);
  }

  int _numberOfExclusions() => _includeMask.values.fold(
      0,
      (acc, albumMask) =>
          acc + albumMask.values.where((included) => !included).length);

  void _setMask(int albumIndex, int trackIndex, bool included) {
    setState(() {
      _includeMask[albumIndex] ??= {};
      _includeMask[albumIndex][trackIndex] = included;
    });
  }

  bool _getMask(int albumIndex, int trackIndex) {
    // include by default
    return (_includeMask[albumIndex] ?? const {})[trackIndex] ?? true;
  }

  static const _timeOffsetValues = [0, 15, 30, 60, 120, 240, 300];
  static const _timeOffsetLabels = [
    'Now',
    '15 minutes ago',
    '30 minutes ago',
    '1 hour ago',
    '2 hours ago',
    '4 hours ago',
    '6 hours ago',
  ];
}
