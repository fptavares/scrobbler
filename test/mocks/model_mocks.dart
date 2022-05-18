import 'package:mockito/annotations.dart';
import 'package:scrobbler/model/bluos.dart';
import 'package:scrobbler/model/discogs.dart';
import 'package:scrobbler/model/lastfm.dart';
import 'package:scrobbler/model/playlist.dart';

import 'model_mocks.mocks.dart';

export 'model_mocks.mocks.dart';

@GenerateMocks([Scrobbler, Collection, Playlist, BluOS])
MockCollection createMockCollection() => MockCollection();
MockScrobbler createMockScrobbler() => MockScrobbler();
MockPlaylist createMockPlaylist() => MockPlaylist();
MockBluOS createMockBluOSMonitor() => MockBluOS();
