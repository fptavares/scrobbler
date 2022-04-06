// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/cache_store.dart';
import 'package:flutter_cache_manager/src/web/web_helper.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:http/http.dart';
import 'package:scrobbler/components/album.dart';
import 'package:scrobbler/main.dart';
import 'package:scrobbler/model/discogs.dart';
import 'package:scrobbler/model/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_collection.dart';

Future<void> main() async {
  // This line enables the extension.
  enableFlutterDriverExtension();

  WidgetsApp.debugAllowBannerOverride = false; // remove debug banner

  if (Platform.isIOS) {
    // Even though the images used are not eligible for copyright,
    // and thus considered public domain,
    // the iOS app store doesn't approve their use in app screenshots.
    // So on iOS this will hide them and overlay the explanation text.
    AlbumImage.imageBuilder = (image) => AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image(image: image),
              Center(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 10.0,
                      sigmaY: 10.0,
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      width: 150.0,
                      height: 150.0,
                      padding: const EdgeInsets.all(5.0),
                      child: const FittedBox(
                        fit: BoxFit.fitWidth,
                        child: Text(
                          'Image hidden\ndue to\ncopyright',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
  }

  SharedPreferences.setMockInitialValues({
    DiscogsSettings.discogsUsernameKey: 'someuser',
    DiscogsSettings.skippedKey: null,
    LastfmSettings.lastfmUsernameKey: 'someuser',
    LastfmSettings.sessionKeyKey: '',
  });
  final prefs = await SharedPreferences.getInstance();

  final config = Config('testCache');
  Collection.cache = CacheManager.custom(config,
      webHelper: WebHelper(CacheStore(config), HttpFileService(httpClient: StaticCollectionHttpClient())));
  Collection.cache.emptyCache();

  runApp(MyApp(prefs, 'ScrobblerDriverTest'));
}

class StaticCollectionHttpClient extends BaseClient {
  StaticCollectionHttpClient();

  final _client = Client();

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    if (request.url.path.contains('/collection/folders/0/releases')) {
      return StreamedResponse(
        Stream<List<int>>.fromIterable(<List<int>>[fakeCollectionData.codeUnits]),
        200,
      );
    } else {
      return await _client.send(request);
    }
  }
}
