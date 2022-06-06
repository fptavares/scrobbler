import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/discogs.dart';
import 'album.dart';
import 'emtpy.dart';

class CollectionGrid extends StatelessWidget {
  const CollectionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(5),
      sliver: Consumer<Collection>(
        builder: (context, collection, _) {
          return SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return AlbumButton(collection.albums[index]);
              },
              childCount: collection.albums.length,
            ),
          );
        },
      ),
    );
  }
}

class CollectionLoadingStatus extends StatelessWidget {
  const CollectionLoadingStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      fillOverscroll: true,
      child: Consumer2<Collection, LoadingStatus>(
        builder: (_, collection, status, __) {
          if (collection.isUserEmpty) {
            return const EmptyState(
              imagePath: 'assets/empty_nothing.png',
              headline: 'Anyone out there?',
              subhead:
                  'Your Discogs collection will be displayed here, so that you can easily select which albums to scrobble.\n\nHave a Discogs account? Just open the account settings on the top left corner when you\'re ready.\nPlease note that this only works for public Discogs collections.',
            );
          }

          if (collection.isEmpty && collection.isNotLoading) {
            return collection.hasLoadingError
                ? EmptyState(
                    imagePath: 'assets/empty_error.png',
                    headline: 'Whoops!',
                    subhead: collection.errorMessage ??
                        'Could not connect to Discogs to get your collection. Please try again later.')
                : const EmptyState(
                    imagePath: 'assets/empty_home.png',
                    headline: 'Nothing here',
                    subhead:
                        'It appears that the configured user collection is either empty, or not publically accessible.',
                  );
          }

          return SizedBox(
            height: 80,
            child: Center(
              child: collection.isLoading
                  ? CircularProgressIndicator(backgroundColor: Theme.of(context).primaryColor)
                  : collection.isNotEmpty && collection.totalItems > 9
                      ? Text(
                          collection.isNotFullyLoaded
                              ? 'Showing ${collection.albums.length} of ${collection.totalItems} albums'
                              : '\u2014 and that is ${collection.totalItems} albums.',
                          style: TextStyle(color: Theme.of(context).hintColor, fontStyle: FontStyle.italic),
                        )
                      : Container(),
            ),
          );
        },
      ),
    );
  }
}
