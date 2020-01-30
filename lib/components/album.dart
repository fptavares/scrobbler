import 'package:drs_app/model/discogs.dart';
import 'package:drs_app/model/playlist.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlbumButton extends StatelessWidget {
  final CollectionAlbum album;

  AlbumButton(this.album);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(album.id),
      margin: EdgeInsets.all(4),
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0x88000000),
            blurRadius: 3.0, // has the effect of softening the shadow
            spreadRadius: 0, // has the effect of extending the shadow
            offset: Offset(1.0, 1.0),
          )
        ],
      ),
      child: Consumer<Playlist>(
        child: Image.network(album.thumbURL),
        builder: (context, playlist, image) {
          final inPlaylistCount = playlist.getCountForAlbum(album);

          return GestureDetector(
            onTap: () => playlist.addAlbum(album),
            child: Stack(
              children: [
                image,
                if (inPlaylistCount > 0)
                  Align(
                    alignment: Alignment(0.95, -0.95),
                    child: GestureDetector(
                      onTap: () => playlist.removeAlbum(album),
                      child: ClipOval(
                        child: Container(
                          color: Theme.of(context).accentColor,//Color(0xFFCF5C36),
                          height: 32.0, // height of the button
                          width: 32.0, // width of the button
                          child: Center(
                            child: Text(
                              inPlaylistCount.toString(),
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
