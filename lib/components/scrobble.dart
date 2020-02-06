import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../model/discogs.dart';
import '../model/lastfm.dart';
import '../model/playlist.dart';
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
      (playlist.isScrobbling) ? Theme.of(context).primaryColor : null,
      child: playlist.isScrobbling
          ? const CircularProgressIndicator()
          : Icon(Icons.play_arrow),
    );
  }

  Future<void> handleScrobble(BuildContext context, Playlist playlist) async {
    final scrobbler = Provider.of<Scrobbler>(context, listen: false);
    final collection = Provider.of<Collection>(context, listen: false);

    try {
      await for (int accepted in playlist.scrobble(scrobbler, collection)) {
        displaySuccess(context, 'Scrobbled $accepted tracks successfuly.');
      }
    } on Exception catch (e, stackTrace) {
      displayAndLogError(context, log, e, stackTrace);
    }
  }
}
