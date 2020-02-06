import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/discogs.dart';
import '../model/playlist.dart';
import 'playlist.dart';

class AlbumButton extends StatelessWidget {
  const AlbumButton(this.album);

  final CollectionAlbum album;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<int>(album.id),
      margin: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x88000000),
            blurRadius: 3.0, // has the effect of softening the shadow
            spreadRadius: 0, // has the effect of extending the shadow
            offset: Offset(1.0, 1.0),
          )
        ],
      ),
      child: Consumer<Playlist>(
        child: Image.network(album.thumbURL),
        builder: (context, playlist, image) {
          final item = playlist.getPlaylistItem(album);

          return GestureDetector(
            onTap: () => playlist.addAlbum(album),
            child: Stack(
              children: <Widget>[
                image,
                if (item != null && item.count > 0)
                  Align(
                    alignment: const Alignment(0.95, -0.95),
                    child: GestureDetector(
                      onTap: () => playlist.removeAlbum(album),
                      child: PlaylistCountIndicator(item: item),
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
