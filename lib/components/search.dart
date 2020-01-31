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
    final playlist = Provider.of<Playlist>(context);

    final List<CollectionAlbum> albums = collection.search(query);

    if (albums.isEmpty) {
      return EmptyState(
        imagePath: 'assets/empty_search.png',
        headline: 'Nothing here',
        subhead: 'We couldn\'t find any matches',
      );
    }

    return ListView.builder(
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
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
