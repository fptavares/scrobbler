import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../model/discogs.dart';
import '../model/playlist.dart';
import 'accounts.dart';
import 'collection.dart';
import 'error.dart';
import 'scrobble.dart';
import 'search.dart';

class HomePage extends StatelessWidget {
  HomePage({Key key}) : super(key: key);

  final Logger log = Logger('HomePage');

  @override
  Widget build(BuildContext context) {
    final collection = Provider.of<Collection>(context, listen: false);

    return Scaffold(
      drawer: const HomeDrawer(),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            if (collection.isNotLoading) {
              handleFutureError(collection.loadMoreAlbums(), context, log,
                  error: 'Failed to load collection!');
            }
          }
          return true;
        },
        child: ValueListenableProvider<LoadingStatus>.value(
          value: collection.loadingNotifier,
          child: Center(
            child: RefreshIndicator(
              onRefresh: () => collection.isLoading
                  ? null
                  : handleFutureError(collection.reload(), context, log,
                      error: 'Failed to reload collection!'),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                //AlwaysScrollableScrollPhysics
                slivers: <Widget>[
                  HomeAppBar(),
                  CollectionGrid(),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    fillOverscroll: true,
                    child: Consumer<LoadingStatus>(
                      builder: (_, loading, __) => Container(
                        height: 160,
                        child: loading == LoadingStatus.loading
                            ? const Center(
                                child: SizedBox(
                                  height: 60,
                                  width: 60,
                                  child: CircularProgressIndicator(),
                                ),
                              )
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

class HomeAppBar extends StatelessWidget {
  final Logger log = Logger('HomeAppBar');

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      stretch: true,
      pinned: true,
      forceElevated: true,
      expandedHeight: 150.0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const <StretchMode>[
          StretchMode.zoomBackground,
          //StretchMode.blurBackground,
          StretchMode.fadeTitle,
        ],
        centerTitle: true,
        title: const Text('Record Scrobbler'),
        background: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset(
              'assets/logo.svg',
              semanticsLabel: 'Logo',
              color: Theme.of(context).accentColor,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      actions: <Widget>[
        Consumer<Playlist>(
          builder: (context, playlist, _) => IconButton(
            icon: const Icon(Icons.playlist_play),
            tooltip: 'Playlist',
            onPressed: playlist.isNotEmpty
                ? () => Navigator.pushNamed(context, '/playlist')
                : null,
          ),
        ),
        Consumer<Collection>(
          builder: (context, collection, _) => IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: (collection.isNotEmpty)
                ? () {
                    showSearch(context: context, delegate: AlbumSearch());
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

class HomeDrawer extends StatelessWidget {
  const HomeDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Account Settings'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        backgroundColor: Colors.transparent,
        body: AccountsForm(),
      ),
    );
  }
}
