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

    analytics.logScrobbling(numberOfAlbums: playlist.numberOfItems);

    try {
      await for (int accepted in playlist.scrobble(scrobbler, collection,
          (albums) => showPlaylistOptionsDialog(context, albums))) {
        displaySuccess(context, 'Scrobbled $accepted tracks successfuly.');
      }
    } on Exception catch (e, stackTrace) {
      displayAndLogError(context, log, e, stackTrace);
    }
  }

  static Future<Map<int, Map<int, bool>>> showPlaylistOptionsDialog(
      BuildContext context, List<AlbumDetails> albums) async {
    return showModalBottomSheet<Map<int, Map<int, bool>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => DraggableScrollableSheet(
        //initialChildSize: 0.3,
        maxChildSize: 0.9,
        minChildSize: 0.2,
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
}

class _ScrobblePlaylistEditorState extends State<ScrobblePlaylistEditor> {
  final Map<int, Map<int, bool>> _includeMask = {};

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
      //crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        AppBar(
          leading: const CloseButton(),
          title: Text('Scrobbling ${widget.albums.length} albums'),
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
        ListTile(
          title: FlatButton(
            color: Theme.of(context).accentColor,
            child: const Text('Submit'),
            onPressed: () => Navigator.pop(context, _includeMask),
          ),
        ),
      ],
    );
  }

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
}
