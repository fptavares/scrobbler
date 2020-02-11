import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/discogs.dart';
import '../model/playlist.dart';
import 'playlist.dart';

class AlbumButton extends StatelessWidget {
  const AlbumButton(this.album, {Key key}) : super(key: key);

  final CollectionAlbum album;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        key: ValueKey<int>(album.id),
        margin: const EdgeInsets.all(4),
        child: Consumer<Playlist>(
          child: CachedAlbumImage(album),
          builder: (context, playlist, image) {
            final item = playlist.getPlaylistItem(album);

            return GestureDetector(
              onTap: () => playlist.addAlbum(album),
              child: Stack(
                children: <Widget>[
                  image,
                  if (item != null && item.count > 0)
                    Positioned(
                      top: 3.0,
                      right: 3.0,
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
      ),
    );
  }
}

class CachedAlbumImage extends StatelessWidget {
  const CachedAlbumImage(this.album, {Key key}) : super(key: key);

  final CollectionAlbum album;

  BoxDecoration get boxDecoration => const BoxDecoration(
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x88000000),
            blurRadius: 5.0, // has the effect of softening the shadow
            spreadRadius: -3, // has the effect of extending the shadow
            offset: Offset(2, 2),
          )
        ],
      );

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: album.thumbUrl,
      imageBuilder: (context, imageProvider) => Container(
        decoration: boxDecoration,
        child: Image(image: imageProvider),
      ),
      placeholder: (context, url) => const AspectRatio(
        aspectRatio: 1,
        child: SizedBox(
          width: 150,
          height: 150,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0x55000000)),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: boxDecoration,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _defaultImage,
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Text(
                          album.artist,
                          style: Theme.of(context).textTheme.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Text(
                          album.title,
                          style: Theme.of(context).textTheme.subhead,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final _defaultImage = () {
    return const Image(image: AssetImage('assets/record_sleeve.png'));
  }();
}
