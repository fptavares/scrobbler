import 'package:drs_app/model/playlist.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
            tooltip: 'Clear',
            onPressed: (playlist.isNotEmpty) ? playlist.clearAlbums : null,
          ),
        ],
      ),
      body: PlaylistList(playlist: playlist),
      floatingActionButton: ScrobbleFloatingButton(),
    );
  }
}

class PlaylistList extends StatelessWidget {
  const PlaylistList({
    Key key,
    @required this.playlist,
  }) : super(key: key);

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final items = playlist.getPlaylistItems();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      child: (playlist.isEmpty)
          ? EmptyState(
              imagePath: 'assets/empty_playlist.png',
              headline: 'The sound of silence',
              subhead: 'There is nothing in your playlist at the moment',
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                final item = items[index];
                return Dismissible(
                  key: ValueKey(item.album.releaseId),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => playlist.removeAlbum(item.album),
                  background: Container(
                    color: Colors.red,
                    child: Icon(Icons.delete),
                  ),
                  child: ListTile(
                    leading: Image.network(item.album.thumbURL),
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
            ),
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
    return ValueListenableProvider.value(
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
