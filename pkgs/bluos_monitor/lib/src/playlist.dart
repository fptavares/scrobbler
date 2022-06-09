import 'dart:math';

import 'package:clock/clock.dart';
import 'package:xml/xml.dart';

import 'parser.dart';

class BluOSPlaylistTracker {
  final List<BluOSAPITrack> _tracks = [];

  int _lastClearedTimestamp = 0;

  List<BluOSAPITrack> get tracks => _tracks;
  int get length => _tracks.length;

  void updateWith(BluOSAPITrack track) {
    if (track.timestamp <= _lastClearedTimestamp) return; // track should have been cleared already, so ignoring

    if (_tracks.isEmpty) {
      _tracks.add(track);
    } else {
      final lastTrack = _tracks.last;
      if (track != lastTrack) {
        lastTrack._fixPlaybackDurationAfterStop();
        if (lastTrack.isScrobbable) {
          _tracks.add(track); // add new track
        } else {
          _tracks.last = track; // replace previous track because it wasn't scrobbable
        }
      }
    }
  }

  void stop() {
    if (_tracks.isNotEmpty) {
      _tracks.last._fixPlaybackDurationAfterStop();

      if (!_tracks.last.isScrobbable) {
        _tracks.removeLast();
      }
    }
  }

  void clear(int timestamp) {
    _tracks.removeWhere((track) => track.timestamp <= timestamp);
    _lastClearedTimestamp = timestamp;
  }
}

abstract class BluOSTrack {
  BluOSTrack({
    required this.timestamp,
    required this.artist,
    this.album,
    required this.title,
    this.imageUrl,
  });

  final int timestamp;
  final String artist;
  final String title;
  final String? album;
  final String? imageUrl;

  bool get isScrobbable;
}

class BluOSAPITrack extends BluOSTrack {
  final String queuePosition;
  final double? length;

  final int _thresholdPlayingTime;
  int? _playDuration;

  int get _elapsedDuration => _playDuration ?? (BluOSAPITrack._nowTimestamp() - timestamp);

  @override
  bool get isScrobbable => length != null && length! <= 30 ? false : _elapsedDuration >= _thresholdPlayingTime;

  BluOSAPITrack({
    required this.queuePosition,
    required String artist,
    String? album,
    required String title,
    this.length,
    required String? imageUrl,
  })  : _thresholdPlayingTime = (length == null) ? 60 : min(4 * 60, length / 2).floor(),
        super(
          artist: artist,
          album: album,
          title: title,
          imageUrl: imageUrl,
          timestamp: BluOSAPITrack.timestampForNewTrack(),
        );
  // threshold = half of duration, no more than 4 minutes, default to 1 minute
  // https://www.last.fm/api/scrobbling#when-is-a-scrobble-a-scrobble

  factory BluOSAPITrack.fromXml(XmlDocument document, String authorityForRelativeImages) {
    try {
      final parser = BluOSStatusParser.fromDocument(document);
      final service = parser.getOptional(AttributeConfig.serviceConfig);
      final config = ServiceConfig.configFor(service);

      var image = parser.getOptional(config.image);
      if (image != null && image.startsWith('/')) {
        image = 'http://$authorityForRelativeImages$image';
      }
      return BluOSAPITrack(
        queuePosition: parser.getMandatory(config.queuePosition),
        artist: parser.getMandatory(config.artist),
        album: parser.getOptional(config.album),
        title: parser.getMandatory(config.title),
        length: parser.getDoubleOptional(config.length),
        imageUrl: image,
      );
    } on MissingMandatoryAttributeException catch (e) {
      throw UnknownTrackException(e);
    }
  }

  void _fixPlaybackDurationAfterStop() {
    _playDuration = _elapsedDuration;
  }

  @override
  bool operator ==(Object other) => hashCode == other.hashCode;

  @override
  int get hashCode => '$queuePosition.$artist.$title'.hashCode;

  /// visible for testing only!
  static int Function() timestampForNewTrack = _nowTimestamp;

  static int _nowTimestamp() => (clock.now().millisecondsSinceEpoch / 1000).floor();
}

class BluOSPlayerState {
  final String? etag;
  final String? playerState;
  final double? seconds;

  BluOSPlayerState([
    this.etag,
    this.playerState,
    this.seconds,
  ]);

  factory BluOSPlayerState.fromXml(XmlDocument document) {
    try {
      final parser = BluOSStatusParser.fromDocument(document);

      return BluOSPlayerState(
        parser.getEtag(),
        parser.getOptional(AttributeConfig.stateConfig),
        parser.getDoubleOptional(AttributeConfig.secondsConfig),
      );
    } on MissingMandatoryAttributeException catch (e) {
      throw UnknownTrackException(e);
    }
  }

  bool get isPlaying => const ['play', 'stream'].contains(playerState);
  bool get isStopped => playerState == 'stop';
  bool get isActive => isPlaying || playerState == 'pause';
}

class UnknownTrackException implements Exception {
  final String failedAttribute;

  UnknownTrackException(MissingMandatoryAttributeException e) : failedAttribute = e.missingAttribute;

  @override
  String toString() {
    return 'Could not process player status due to missing attribute: $failedAttribute.';
  }
}
