import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:scrobbler/model/bluos.dart';
import 'package:scrobbler/model/discogs.dart';
import 'package:scrobbler/model/lastfm.dart';
import 'package:scrobbler/model/playlist.dart';
import 'package:scrobbler/model/settings.dart';
import 'package:scrobbler_bluos_monitor/scrobbler_bluos_monitor.dart';

import 'model_mocks.mocks.dart';

export 'model_mocks.mocks.dart';

@GenerateMocks([Scrobbler, Collection, Playlist, BluOS, BluOSAPIMonitor, Settings])
MockCollection createMockCollection() => MockCollection();
MockScrobbler createMockScrobbler() => MockScrobbler();
MockPlaylist createMockPlaylist() => MockPlaylist();
MockBluOS createMockBluOSMonitor() => MockBluOS();
MockBluOSAPIMonitor createMockBluOSAPIMonitor() => MockBluOSAPIMonitor();
MockSettings createMockSettings({
  bool isBluOSEnabled = false,
  bool isBluOSWarningShown = false,
  bool isSkipped = false,
  String? bluOSMonitorAddress,
  BluOSPlayer? bluOSPlayer,
  String? discogsUsername,
  String? lastfmSessionKey,
  String? lastfmUsername,
}) {
  final settings = MockSettings();
  when(settings.isBluOSEnabled).thenReturn(isBluOSEnabled);
  when(settings.isBluOSWarningShown).thenReturn(isBluOSWarningShown);
  when(settings.isSkipped).thenReturn(isSkipped);
  when(settings.bluOSMonitorAddress).thenReturn(bluOSMonitorAddress);
  when(settings.bluOSPlayer).thenReturn(bluOSPlayer);
  when(settings.discogsUsername).thenReturn(discogsUsername);
  when(settings.lastfmSessionKey).thenReturn(lastfmSessionKey);
  when(settings.lastfmUsername).thenReturn(lastfmUsername);
  return settings;
}
