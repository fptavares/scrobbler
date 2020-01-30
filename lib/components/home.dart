import 'package:drs_app/components/accounts.dart';
import 'package:drs_app/components/album.dart';
import 'package:drs_app/components/playlist.dart';
import 'package:drs_app/model/discogs.dart';
import 'package:drs_app/model/lastfm.dart';
import 'package:drs_app/model/playlist.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatelessWidget {
  HomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final collection = Provider.of<Collection>(context, listen: false);

    return Scaffold(
      drawer: const HomeDrawer(),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            if (collection.isNotLoading) {
              collection.loadMoreAlbums();
            }
          }
          return true;
        },
        child: ValueListenableProvider<bool>.value(
          value: collection.loadingNotifier,
          child: Center(
            child: RefreshIndicator(
              onRefresh: () =>
                  (collection.isNotLoading) ? collection.reload() : null,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                //AlwaysScrollableScrollPhysics
                slivers: <Widget>[
                  HomeAppBar(),
                  CollectionGrid(),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    fillOverscroll: true,
                    child: Consumer<bool>(
                      builder: (context, isLoading, _) => Container(
                        height: 160,
                        child: (isLoading)
                            ? Center(child: CircularProgressIndicator())
                            : Container(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: ScrobbleFloatingButton(),
    );
  }
}

class ScrobbleFloatingButton extends StatelessWidget {
  const ScrobbleFloatingButton({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Scrobbler scrobbler = Provider.of<Scrobbler>(context);
    Playlist playlist = Provider.of<Playlist>(context);

    if (playlist.isEmpty) {
      return Container();
    }

    return FloatingActionButton(
      onPressed: (playlist.isScrobbling)
          ? null
          : () async {
              try {
                await for (var accepted in playlist.scrobble(scrobbler)) {
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text('Scrobbled $accepted tracks successfuly.'),
                    backgroundColor: Colors.green,
                  ));
                }
              } catch (e, stacktrace) {
                print('Failed to scrobble to Last.fm: $e');
                print(stacktrace);
                Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Colors.red,
                ));
              }
            },
      tooltip: 'Scrobble',
      backgroundColor:
          (playlist.isScrobbling) ? Theme.of(context).primaryColor : null,
      child: (playlist.isScrobbling)
          ? CircularProgressIndicator()
          : Icon(Icons.play_arrow),
    );
  }
}

class HomeDrawer extends StatelessWidget {
  const HomeDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Scaffold(
        backgroundColor:
            Theme.of(context).secondaryHeaderColor, //Colors.transparent,
        body: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            /*DrawerHeader(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: Center(child: Text('Settings')),/*SvgPicture.asset(
                'assets/logo.svg',
                semanticsLabel: 'Logo',
                color: Theme.of(context).primaryColor,
              ),*/
            ),*/
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: SvgPicture.asset(
                  'assets/logo.svg',
                  semanticsLabel: 'Logo',
                  color: Theme.of(context).primaryColor,
                  height: 80,
                ),
              ),
            ),
            AccountsForm(),
            /**
             * ListTile(
             *  leading: Icon(Icons.settings),
             *  title: Text('Settings'),
             * ),
             */
          ],
        ),
      ),
    );
  }
}

class HomeAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      stretch: true,
      pinned: true,
      expandedHeight: 150.0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: <StretchMode>[
          //StretchMode.zoomBackground,
          //StretchMode.blurBackground,
          StretchMode.fadeTitle,
        ],
        centerTitle: true,
        title: const Text('.record scrobbler.'),
        background: Row(
          children: <Widget>[
            const Spacer(),
            SvgPicture.asset(
              'assets/logo.svg',
              semanticsLabel: 'Logo',
              color: Theme.of(context).accentColor,
            ),
            //Image(image: AssetImage('assets/logo_white.png')),
            const Spacer(),
          ],
        ),
      ),
      actions: <Widget>[
        Consumer<Playlist>(
          builder: (context, playlist, _) => IconButton(
            icon: const Icon(Icons.playlist_play),
            tooltip: 'Playlist',
            onPressed: playlist.isNotEmpty ? () => Navigator.pushNamed(context, '/playlist') : null,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search',
          onPressed: () {},
        ),
      ],
    );
  }
}

class CollectionGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(5),
      sliver: Consumer<Collection>(
        builder: (context, collection, _) => SliverGrid(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 150,
            crossAxisSpacing: 0,
            mainAxisSpacing: 0,
          ),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              final album = collection.albums[index];
              /*return ChangeNotifierProvider<CollectionAlbum>.value(
                value: album,
                child: AlbumButton(),
                key: ValueKey(album.id),
              );*/
              return AlbumButton(album);
            },
            childCount: collection.albums.length,
          ),
        ),
      ),
    );
  }
}
