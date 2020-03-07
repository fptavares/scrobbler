import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../model/analytics.dart';
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
            if (collection.isNotLoading && collection.hasMorePages) {
              analytics.logScrollToNextPage(page: collection.nextPage);

              handleFutureError(collection.loadMoreAlbums(), context, log,
                  error: 'Failed to load collection!', trace: 'load_more');
            }
          }
          return true;
        },
        child: ValueListenableProvider<LoadingStatus>.value(
          value: collection.loadingNotifier,
          child: RefreshIndicator(
            onRefresh: () {
              if (collection.isLoading) {
                return Future.value(null);
              }
              analytics.logPullToRefresh();

              return handleFutureError(collection.reload(), context, log,
                  error: 'Failed to reload collection!', trace: 'reload');
            },
            child: const HomeBody(),
          ),
        ),
      ),
      floatingActionButton: ScrobbleFloatingButton(),
    );
  }
}

class HomeBody extends StatelessWidget {
  const HomeBody();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: PrimaryScrollController.of(context),
      slivers: <Widget>[
        HomeAppBar(),
        CollectionGrid(),
        const CollectionLoadingStatus(),
      ],
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
      expandedHeight: 90.0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(top: 10.0, bottom: 5.0),
        stretchModes: const <StretchMode>[
          //StretchMode.zoomBackground,
          StretchMode.blurBackground,
          StretchMode.fadeTitle,
        ],
        title: GestureDetector(
          onTap: () => PrimaryScrollController.of(context).animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ).then((_) => analytics.logTapLogo()),
          child: SafeArea(
            key: const Key('logo'),
            child: Consumer<LoadingStatus>(
              builder: (_, status, __) => SvgPicture.asset(
                'assets/logo.svg',
                color: status == LoadingStatus.loading
                    ? Theme.of(context).accentColor.withAlpha(128)
                    : Theme.of(context).accentColor,
                width: 38,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
        background: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 10.0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Text('scrobbler.',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white60,
                        fontFamily: 'Quicksand',
                        fontSize: 24.0,
                      )),
                ),
                const SizedBox(width: 70),
                const Expanded(
                  flex: 1,
                  child: Text(''),
                ),
              ],
            ),
          ),
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
                ? () async {
                    await showSearch(context: context, delegate: AlbumSearch());
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
