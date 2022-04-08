import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';

import '../model/discogs.dart';
import '../model/playlist.dart';
import 'playlist.dart';

class AlbumButton extends StatelessWidget {
  const AlbumButton(this.album, {Key? key, this.cacheManager}) : super(key: key);

  final CollectionAlbum album;
  final CacheManager? cacheManager;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        key: ValueKey<int>(album.id),
        margin: const EdgeInsets.all(4),
        child: Consumer<Playlist>(
          child: CachedAlbumImage(album, cacheManager: cacheManager),
          builder: (context, playlist, image) {
            final item = playlist.getPlaylistItem(album);

            return GestureDetector(
              onTap: () => playlist.addAlbum(album),
              child: Tooltip(
                message: '${album.title} by ${album.artist}',
                child: Stack(
                  children: <Widget>[
                    image!,
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
              ),
            );
          },
        ),
      ),
    );
  }
}

class CachedAlbumImage extends StatelessWidget {
  const CachedAlbumImage(this.album, {Key? key, this.cacheManager}) : super(key: key);

  final Album album;
  final CacheManager? cacheManager;

  @override
  Widget build(BuildContext context) {
    if (album.thumbUrl?.isEmpty ?? true) {
      return DefaultAlbumImage(
        decoration: _shadowDecoration,
        album: album,
      );
    }

    return CachedNetworkImage(
      imageUrl: album.thumbUrl ?? '',
      imageBuilder: (context, image) => AlbumImage(
        decoration: _shadowDecoration,
        image: image,
      ),
      placeholder: (context, url) => const AspectRatio(
        aspectRatio: 1,
        child: SizedBox(
          width: 150,
          height: 150,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0x11000000)),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => DefaultAlbumImage(
        decoration: _shadowDecoration,
        album: album,
      ),
      cacheManager: cacheManager,
    );
  }

  static const BoxDecoration _shadowDecoration = BoxDecoration(
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: Color(0x88000000),
        blurRadius: 5.0, // has the effect of softening the shadow
        spreadRadius: -3, // has the effect of extending the shadow
        offset: Offset(2, 2),
      )
    ],
  );
}

class AlbumImage extends StatelessWidget {
  const AlbumImage({
    Key? key,
    required this.decoration,
    required this.image,
  }) : super(key: key);

  final Decoration decoration;
  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration,
      child: imageBuilder(image),
    );
  }

  @visibleForTesting
  // ignore: prefer_function_declarations_over_variables
  static Widget Function(ImageProvider) imageBuilder = (image) => Image(image: image);
}

class DefaultAlbumImage extends StatelessWidget {
  const DefaultAlbumImage({
    Key? key,
    required this.decoration,
    required this.album,
  }) : super(key: key);

  final BoxDecoration decoration;
  final Album album;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: decoration,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const Image(image: _defaultImage),
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
                        style: Theme.of(context).textTheme.headline6,
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
                        style: Theme.of(context).textTheme.subtitle1,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _defaultImage = AssetImage('assets/record_sleeve.png');
}
