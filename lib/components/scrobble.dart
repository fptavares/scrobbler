import 'package:drs_app/model/discogs.dart';
import 'package:drs_app/model/lastfm.dart';
import 'package:drs_app/model/playlist.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScrobbleFloatingButton extends StatelessWidget {
  const ScrobbleFloatingButton({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Scrobbler scrobbler = Provider.of<Scrobbler>(context);
    Playlist playlist = Provider.of<Playlist>(context);
    Collection collection = Provider.of<Collection>(context);

    if (playlist.isEmpty) {
      return Container();
    }

    return FloatingActionButton(
      onPressed: (playlist.isScrobbling)
          ? null
          : () async {
        try {
          await for (var accepted in playlist.scrobble(scrobbler, collection)) {
            Scaffold.of(context).showSnackBar(SnackBar(
              content: Text('Scrobbled $accepted tracks successfuly.'),
              backgroundColor: Colors.green,
            ));
          }
        } catch (e, stacktrace) {
          print('Failed to scrobble to Last.fm: $e');
          print(stacktrace);
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ));
        }
      },
      tooltip: 'Scrobble',
      backgroundColor:
      (playlist.isScrobbling) ? Theme.of(context).primaryColor : null,
      child: (playlist.isScrobbling)
          ? CircularProgressIndicator()
          : Icon(Icons.play_arrow),
    );
  }
}
