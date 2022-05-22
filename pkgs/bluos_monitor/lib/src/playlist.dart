import 'dart:math';

import 'package:xml/xml.dart';

import 'parser.dart';

class BluOSPlaylistTracker {
  final List<BluOSAPITrack> _tracks = [];

  int _lastClearedTimestamp = 0;

  List<BluOSAPITrack> get tracks => _tracks;
  int get length => _tracks.length;

  void addTrack(BluOSAPITrack track) {
    if (track.timestamp <= _lastClearedTimestamp) return; // track should have been cleared already, so ignoring

    if (_tracks.isEmpty) {
      _tracks.add(track);
    } else {
      final lastTrack = _tracks.last;
      if (track == lastTrack) {
        _tracks.last = track; // replace same track to update state and other data
      } else {
        lastTrack.updatePlaybackDurationAfterPlayed();
        if (lastTrack.isScrobbable) {
          _tracks.add(track);
        } else {
          _tracks.last = track; // replace previous track because it wasn't scrobbable
        }
      }
    }
  }

  void stop() {
    if (_tracks.isNotEmpty) {
      _tracks.last.updatePlaybackDurationAfterPlayed();

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
  final String playId;
  final int? length;
  final BluOSTrackState state;

  final double _thresholdPlayingTime;

  @override
  bool get isScrobbable => state.seconds >= _thresholdPlayingTime;

  BluOSAPITrack({
    required this.playId,
    required super.artist,
    super.album,
    required super.title,
    required this.length,
    required super.timestamp,
    required super.imageUrl,
    required this.state,
  }) : _thresholdPlayingTime = (length == null) ? 60 : min(4 * 60, max(length / 2, 15));
  // threshold = half of duration, no more than 4 minutes, no less than 15 seconds, default to 1 minute

  factory BluOSAPITrack.fromXml(XmlDocument document, BluOSTrackState state, String authorityForRelativeImages) {
    try {
      final parser = BluOSStatusParser.fromDocument(document);
      final service = parser.getOptional(AttributeConfig.serviceConfig);
      final config = ServiceConfig.configFor(service);

      var image = parser.getOptional(config.image);
      if (image != null && image.startsWith('/')) {
        image = 'http://$authorityForRelativeImages$image';
      }
      return BluOSAPITrack(
        playId: parser.getMandatory(config.playId),
        artist: parser.getMandatory(config.artist),
        album: parser.getOptional(config.album),
        title: parser.getMandatory(config.title),
        length: parser.getIntOptional(config.length),
        timestamp: BluOSAPITrack._nowTimestamp() - state.seconds,
        imageUrl: image,
        state: state,
      );
    } on MissingMandatoryAttributeException catch (e) {
      throw UnknownTrackException(e);
    }
  }

  void updatePlaybackDurationAfterPlayed() {
    state.seconds = state.isPlaying ? BluOSAPITrack._nowTimestamp() - timestamp : state.seconds;
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'artist': artist,
      'title': title,
      'album': album,
      'image': imageUrl,
      if (!isScrobbable) 'isScrobbable': isScrobbable,
    }..removeWhere((key, value) => value == null);
  }

  @override
  bool operator ==(Object other) => hashCode == other.hashCode;

  @override
  int get hashCode => '$playId$artist$title'.hashCode;

  static int _nowTimestamp() => (DateTime.now().millisecondsSinceEpoch / 1000).floor();
}

class BluOSTrackState {
  final String? etag;
  final String? playerState;
  int seconds;

  BluOSTrackState([
    this.etag,
    this.playerState,
    this.seconds = 0,
  ]);

  factory BluOSTrackState.fromXml(XmlDocument document) {
    try {
      final parser = BluOSStatusParser.fromDocument(document);

      return BluOSTrackState(
        parser.getEtag(),
        parser.getOptional(AttributeConfig.stateConfig),
        parser.getIntOptional(AttributeConfig.secondsConfig) ?? 0,
      );
    } on MissingMandatoryAttributeException catch (e) {
      throw UnknownTrackException(e);
    }
  }

  bool get isPlaying => const ['play', 'stream'].contains(playerState);
  bool get isConnecting => playerState == 'connecting';
  bool get isStopped => playerState == 'stop';
  bool get isActive => !isConnecting && !isStopped;
}

class UnknownTrackException implements Exception {
  final String failedAttribute;

  UnknownTrackException(MissingMandatoryAttributeException e) : failedAttribute = e.missingAttribute;
}
