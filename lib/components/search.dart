import 'package:drs_app/components/emtpy.dart';
import 'package:drs_app/model/discogs.dart';
import 'package:drs_app/model/playlist.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'playlist.dart';

class AlbumSearch extends SearchDelegate<CollectionAlbum> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final collection = Provider.of<Collection>(context);

    final List<CollectionAlbum> albums = collection.search(query);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 50),
      child: (albums.isEmpty)
          ? EmptyState(
              key: ValueKey(1),
              imagePath: 'assets/empty_search.png',
              headline: 'Nothing here',
              subhead: 'We couldn\'t find any matches',
            )
          : Column(
              key: ValueKey(2),
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ValueListenableProvider<bool>.value(
                  value: collection.loadingNotifier,
                  child: Consumer<bool>(
                    builder: (_, isLoading, __) =>
                        (isLoading) ? LinearProgressIndicator() : Container(),
                  ),
                ),
                Consumer<Playlist>(
                  builder: (_, playlist, __) => Flexible(
                    child: ListView.builder(
                      itemCount: albums.length,
                      itemBuilder: (BuildContext context, int index) {
                        final album = albums[index];
                        final item = playlist.getPlaylistItem(album);

                        return ListTile(
                          key: ValueKey(album.id),
                          leading: Image.network(album.thumbURL),
                          title: Text(
                            album.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(album.artist),
                          trailing: (item != null && item.count > 0)
                              ? GestureDetector(
                                  onTap: () => playlist.removeAlbum(album),
                                  child: PlaylistCountIndicator(item: item),
                                )
                              : null,
                          onTap: () => playlist.addAlbum(album),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
