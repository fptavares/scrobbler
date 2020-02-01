import 'package:drs_app/model/discogs.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'album.dart';
import 'emtpy.dart';

class CollectionGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(5),
      sliver: Consumer<Collection>(
        builder: (context, collection, _) {
          if (collection.isUserEmpty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: true,
              child: EmptyState(
                imagePath: 'assets/empty_nothing.png',
                headline: 'Anyone out there?',
                subhead: 'A Discogs account needs to be configured',
              ),
            );
          }
          if (collection.isEmpty && collection.isNotLoading) {
            return SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: true,
              child: EmptyState(
                imagePath: 'assets/empty_home.png',
                headline: 'Nothing here',
                subhead: 'It appears that the configured user collection is either empty, or not publically accessible.',
              ),
            );
          }

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
            ),
            delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
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
