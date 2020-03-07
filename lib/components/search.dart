import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../model/analytics.dart';
import '../model/discogs.dart';
import '../model/playlist.dart';
import 'album.dart';
import 'emtpy.dart';
import 'error.dart';
import 'playlist.dart';

class AlbumSearch extends SearchDelegate<CollectionAlbum> {
  AlbumSearch() : super(keyboardType: TextInputType.text) {
    analytics.setCurrentScreen(screenName: 'search');
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
        icon: Icon(Icons.clear),
        tooltip: 'Clear',
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
      tooltip: 'Back',
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _SearchResultsList(query: query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }

  @visibleForTesting
  static const emptyHeadlineMessage = 'Nothing here';
  @visibleForTesting
  static const emptySubheadMessage = 'We couldn\'t find any matches';
}

class _SearchResultsList extends StatelessWidget {
  _SearchResultsList({
    Key key,
    @required this.query,
  }) : super(key: key);

  final Logger log = Logger('AlbumSearch');

  final String query;

  @override
  Widget build(BuildContext context) {
    final collection = Provider.of<Collection>(context);
    // asynchronously load all albums
    if (query.isNotEmpty &&
        collection.isNotFullyLoaded &&
        collection.isNotLoading) {
      analytics.logLoadAllForSearch(amount: collection.totalItems);
      WidgetsBinding.instance.addPostFrameCallback((_) => handleFutureError(
          collection.loadAllAlbums(), context, log,
          error: 'Failed to load the full collection!'));
    }

    final albums = collection.search(query);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 50),
      child: (albums.isEmpty)
          ? const EmptyState(
              key: Key('empty_search'),
              imagePath: 'assets/empty_search.png',
              headline: AlbumSearch.emptyHeadlineMessage,
              subhead: AlbumSearch.emptySubheadMessage,
            )
          : Column(
              key: const Key('search_results'),
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ValueListenableProvider<LoadingStatus>.value(
                  value: collection.loadingNotifier,
                  child: Consumer<LoadingStatus>(
                    builder: (_, loading, __) =>
                        loading == LoadingStatus.loading
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
                          leading: CachedAlbumImage(album),
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
