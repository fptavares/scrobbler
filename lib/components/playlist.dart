import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/playlist.dart';
import 'album.dart';
import 'emtpy.dart';
import 'scrobble.dart';

class PlaylistPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final playlist = Provider.of<Playlist>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlist'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Remove all',
            onPressed: (playlist.isNotEmpty) ? playlist.clearAlbums : null,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: (playlist.isEmpty)
            ? const EmptyState(
                imagePath: 'assets/empty_playlist.png',
                headline: PlaylistPage.emptyHeadlineMessage,
                subhead: PlaylistPage.emptySubheadMessage,
              )
            : _PlaylistList(playlist: playlist),
      ),
      floatingActionButton: ScrobbleFloatingButton(),
    );
  }

  @visibleForTesting
  static const emptyHeadlineMessage = 'The sound of silence';
  @visibleForTesting
  static const emptySubheadMessage =
      'There is nothing in your playlist at the moment';
}

class _PlaylistList extends StatelessWidget {
  const _PlaylistList({
    Key key,
    @required this.playlist,
  }) : super(key: key);

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final items = playlist.getPlaylistItems();

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Dismissible(
          key: ValueKey<int>(item.album.releaseId),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => playlist.removeAlbum(item.album),
          background: Container(
            color: Colors.red,
            child: Icon(Icons.delete),
          ),
          child: ListTile(
            leading: CachedAlbumImage(item.album),
            title: Text(
              item.album.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(item.album.artist),
            trailing: GestureDetector(
              onTap: item.decrease,
              child: PlaylistCountIndicator(item: item),
            ),
            onTap: item.increase,
          ),
        );
      },
    );
  }
}

class PlaylistCountIndicator extends StatelessWidget {
  const PlaylistCountIndicator({
    Key key,
    @required this.item,
  }) : super(key: key);

  final PlaylistItem item;

  @override
  Widget build(BuildContext context) {
    return ValueListenableProvider<int>.value(
      value: item,
      child: ClipOval(
        child: Container(
          color: Theme.of(context).accentColor, //Color(0xFFCF5C36),
          height: 32.0, // height of the button
          width: 32.0, // width of the button
          child: Center(
            child: Consumer<int>(
              builder: (_, count, __) => Text(
                count.toString(),
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
