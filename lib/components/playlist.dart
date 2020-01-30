import 'package:drs_app/model/discogs.dart';
import 'package:drs_app/model/playlist.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlaylistPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final playlist = Provider.of<Playlist>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Playlist'),
      ),
      body: FutureBuilder<List<AlbumDetails>>(
        future: playlist.getAlbums(),
        builder: (_, AsyncSnapshot<List<AlbumDetails>> snapshot) {
          if (snapshot.hasData) {
            List<AlbumDetails> albums = snapshot.data;

            return Consumer<Playlist>(
              builder: (_, playlist, __) => ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: entries.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    child: Text(albums[index].title),
                  );
                },
              ),
            );
          } else if (snapshot.hasError) {
            return Column(
              children: <Widget>[
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text('Error: ${snapshot.error}'),
                )
              ],
            );
          } else {
            return Column(
              children: <Widget>[
                SizedBox(
                  child: CircularProgressIndicator(),
                  width: 60,
                  height: 60,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('Awaiting result...'),
                )
              ],
            );
          }
        },
      ),
    );
  }
}
