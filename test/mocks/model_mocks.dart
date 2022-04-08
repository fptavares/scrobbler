import 'package:mockito/annotations.dart';
import 'package:scrobbler/model/discogs.dart';
import 'package:scrobbler/model/lastfm.dart';
import 'package:scrobbler/model/playlist.dart';

import 'model_mocks.mocks.dart';

export 'model_mocks.mocks.dart';

@GenerateMocks([Scrobbler, Collection, Playlist])
MockCollection createMockCollection() => MockCollection();
MockScrobbler createMockScrobbler() => MockScrobbler();
MockPlaylist createMockPlaylist() => MockPlaylist();
