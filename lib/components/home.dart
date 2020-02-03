import 'package:drs_app/components/accounts.dart';
import 'package:drs_app/components/scrobble.dart';
import 'package:drs_app/model/discogs.dart';
import 'package:drs_app/model/playlist.dart';
import 'package:drs_app/model/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'collection.dart';
import 'search.dart';

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

class HomeAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      stretch: true,
      pinned: true,
      forceElevated: true,
      expandedHeight: 150.0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: <StretchMode>[
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
            SizedBox(height: 20),
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
        Consumer<DiscogsSettings>(
          builder: (context, settings, _) => IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () =>
                (settings.username != null) ? openSearch(context) : null,
          ),
        ),
      ],
    );
  }

  void openSearch(BuildContext context) {
    Provider.of<Collection>(context, listen: false).loadAllAlbums();
    showSearch(context: context, delegate: AlbumSearch());
  }
}

class HomeDrawer extends StatelessWidget {
  const HomeDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Account Settings'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        backgroundColor: Colors.transparent,
        body: AccountsForm(),
      ),
    );
  }
}
