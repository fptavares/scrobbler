import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../model/analytics.dart';
import '../model/discogs.dart';
import '../model/playlist.dart';
import 'accounts.dart';
import 'bluos.dart';
import 'collection.dart';
import 'error.dart';
import 'scrobble.dart';
import 'search.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static final Logger _log = Logger('HomePage');

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

                handleFutureError(collection.loadMoreAlbums(), _log,
                    error: 'Failed to load collection!', trace: 'load_more');
              }
            }
            return true;
          },
          child: ValueListenableProvider<LoadingStatus>.value(
            value: collection.loadingNotifier,
            child: RefreshIndicator(
              //backgroundColor: Theme.of(context).colorScheme.secondary,
              onRefresh: () {
                if (collection.isLoading) {
                  return Future.value(null);
                }
                analytics.logPullToRefresh();

                return handleFutureError(collection.reload(emptyCache: true), _log,
                    error: 'Failed to reload collection!', trace: 'reload');
              },
              child: const HomeBody(),
            ),
          ),
        ),
        floatingActionButton: const Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            BluosFloatingButton(),
            ScrobbleFloatingButton(),
          ],
        ),
        endDrawer: SizedBox(
          width: MediaQuery.of(context).size.width < 400 ? MediaQuery.of(context).size.width : 380,
          child: const Drawer(
            child: Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: BluOSMonitorControl(),
            ),
          ),
        ));
  }
}

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: PrimaryScrollController.of(context),
      slivers: const [
        HomeAppBar(),
        CollectionGrid(),
        CollectionLoadingStatus(),
      ],
    );
  }
}

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  static final Logger _log = Logger('HomeAppBar');

  @override
  Widget build(BuildContext context) {
    final collection = Provider.of<Collection>(context, listen: false);
    final platform = Theme.of(context).platform;

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
          onTap: () => PrimaryScrollController.of(context).animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut)
              .then((_) => analytics.logTapLogo()),
          child: SafeArea(
            key: const Key('logo'),
            child: Consumer<LoadingStatus>(
              builder: (_, status, __) => SvgPicture.asset(
                'assets/logo.svg',
                color: status == LoadingStatus.loading
                    ? Theme.of(context).colorScheme.secondary.withAlpha(128)
                    : Theme.of(context).colorScheme.secondary,
                width: 38,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
        background: const Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Text('scrobbler.',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.white60, fontFamily: 'Quicksand', fontSize: 24.0)),
                ),
                SizedBox(width: 70),
                Expanded(flex: 1, child: Text('')),
              ],
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        tooltip: 'Settings',
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
      actions: <Widget>[
        Consumer<Playlist>(
          builder: (context, playlist, _) => IconButton(
            icon: const Icon(Icons.playlist_play),
            tooltip: 'Playlist',
            onPressed: playlist.isNotEmpty ? () => Navigator.pushNamed(context, '/playlist') : null,
          ),
        ),
        Consumer<Collection>(
          builder: (context, collection, _) => IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: collection.isNotEmpty ? () => showSearch(context: context, delegate: AlbumSearch()) : null,
          ),
        ),
        if ([TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux].contains(platform))
          Consumer<LoadingStatus>(
            builder: (context, status, _) => IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reload collection',
              onPressed: collection.isNotLoading ? () => _handleReload(collection) : null,
            ),
          )
      ],
    );
  }

  Future<void> _handleReload(Collection collection) {
    analytics.logClickRefreshButton();
    return handleFutureError(collection.reload(emptyCache: true), _log,
        error: 'Failed to reload collection!', trace: 'reload');
  }
}

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        backgroundColor: Colors.transparent,
        body: const AccountsForm(),
      ),
    );
  }
}
