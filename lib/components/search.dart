import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../model/discogs.dart';
import '../model/playlist.dart';
import 'emtpy.dart';
import 'error.dart';
import 'playlist.dart';

class AlbumSearch extends SearchDelegate<CollectionAlbum> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
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
    return SearchResultsList(query: query,);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}

class SearchResultsList extends StatelessWidget {
  SearchResultsList({
    Key key,
    @required this.query,
  }) : super(key: key);

  final Logger log = Logger('AlbumSearch');

  final String query;

  @override
  Widget build(BuildContext context) {
    final collection = Provider.of<Collection>(context);
    // asynchronously load all albums
    if (collection.isNotFullyLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => handleFutureError(
          collection.loadAllAlbums(), context, log,
          error: 'Failed to load the full collection!'));
    }

    final albums = collection.search(query);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 50),
      child: (albums.isEmpty)
          ? const EmptyState(
              key: ValueKey<int>(1),
              imagePath: 'assets/empty_search.png',
              headline: 'Nothing here',
              subhead: 'We couldn\'t find any matches',
            )
          : Column(
              key: const ValueKey<int>(2),
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ValueListenableProvider<LoadingStatus>.value(
                  value: collection.loadingNotifier,
                  child: Consumer<LoadingStatus>(
                    builder: (_, loading, __) => loading == LoadingStatus.loading
                        ? const LinearProgressIndicator()
                        : Container(),
                  ),
                ),
                Consumer<Playlist>(
                  builder: (_, playlist, __) => Flexible(
                    child: ListView.builder(
                      itemCount: albums.length,
                      itemBuilder: (context, index) {
                        final album = albums[index];
                        final item = playlist.getPlaylistItem(album);

                        return ListTile(
                          key: ValueKey<int>(album.id),
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
}
