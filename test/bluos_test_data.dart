import 'package:scrobbler/model/bluos.dart';

typedef JsonObject = Map<String, dynamic>;
typedef JsonList = List<JsonObject>;

mixin BluOSTestData {
  static const JsonList _playlistTracks = <JsonObject>[
    {
      'timestamp': 1653146546,
      'artist': 'Radiohead',
      'title': 'Fake Plastic Trees',
      'album': 'The Bends',
      'image': 'http://resources.tidal.com/images/5cea9f34/bd72/4d8e/8fdc/a49565924f3e/320x320.jpg'
    },
    {
      'timestamp': 1653146838,
      'artist': 'Jeff Buckley',
      'title': "Lover, You Should've Come Over",
      'album': 'Grace',
      'image': 'http://resources.tidal.com/images/e51b3909/9c52/4c3e/857a/95a2a9ec2e70/320x320.jpg'
    },
    {
      'timestamp': 1653147241,
      'artist': 'Blur',
      'title': 'No Distance Left to Run',
      'album': 'Blur: The Best Of',
      'image': 'http://resources.tidal.com/images/a37156c1/bd9c/4b00/8804/06a27ce29f7b/320x320.jpg',
      'isScrobbable': false
    }
  ];

  static const JsonObject pollingWithPlaylist = {
    'isPolling': true,
    'playlist': _playlistTracks,
    'playerName': 'Living Room',
    'playerState': 'stream',
  };

  static const JsonObject pollingWithPlaylistAndError = {
    'isPolling': true,
    'playlist': _playlistTracks,
    'playerName': 'Living Room',
    'playerState': 'stream',
    'errorMessage': 'There was an error',
  };

  static const JsonObject notPollingWithPlaylist = {
    'isPolling': false,
    'playlist': _playlistTracks,
    'playerName': 'Living Room',
    'playerState': 'pause',
  };

  static const JsonObject pollingEmptyPlaylist = {
    'isPolling': true,
    'playlist': [],
    'playerName': 'Living Room',
    'playerState': 'stop',
  };

  static const JsonObject notPollingEmptyPlaylist = {
    'isPolling': false,
    'playlist': [],
  };

  static final listOfBluOSMonitorTracks = <BluOSMonitorTrack>[
    BluOSMonitorTrack(
      timestamp: 123456789,
      artist: 'Radiohead',
      album: 'OK Computer',
      title: 'Paranoid Android',
      imageUrl: 'http://resources.tidal.com/images/e51b3909/9c52/4c3e/857a/95a2a9ec2e70/320x320.jpg',
      isScrobbable: true,
    ),
    BluOSMonitorTrack(
      timestamp: 223456789,
      artist: 'Peter Gabriel',
      album: 'So',
      title: 'Mercy Street',
      isScrobbable: true,
    ),
    BluOSMonitorTrack(
      timestamp: 323456789,
      artist: 'Jeff Buckley',
      album: 'Grace',
      title: 'Last Goodbye',
      imageUrl: 'http://resources.tidal.com/images/e51b3909/9c52/4c3e/857a/95a2a9ec2e70/320x320.jpg',
      isScrobbable: false,
    ),
  ];
}
