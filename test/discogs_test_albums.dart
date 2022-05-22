import 'package:scrobbler/model/discogs.dart';

final CollectionAlbum testAlbum1 = CollectionAlbum(
  id: 123,
  releaseId: 456,
  artist: 'Radiohead',
  title: 'OK Computer',
  year: 1997,
  formats: [
    AlbumFormat(
        name: 'Vinyl',
        descriptions: ['LP', 'Album', 'Limited Edition', 'Reissue'],
        extraText: '180 gram',
        quantity: 2),
    AlbumFormat(name: 'CD', descriptions: [], extraText: null, quantity: 1)
  ],
  thumbUrl:
      'https://api-img.discogs.com/kAXVhuZuh_uat5NNr50zMjN7lho=/fit-in/300x300/filters:strip_icc():format(jpeg):mode_rgb()/discogs-images/R-249504-1334592212.jpeg.jpg',
  rating: 5,
  dateAdded: '2017-06-22T14:34:40-07:00',
);
final CollectionAlbum testAlbum2 = CollectionAlbum(
  id: 789,
  releaseId: 249504,
  artist: 'Rick Astley',
  title: 'Never Gonna Give You Up',
  year: 0,
  formats: [
    AlbumFormat(
        name: 'Vinyl', descriptions: ['7"', '45 RPM', 'Single'], quantity: 1)
  ],
  thumbUrl:
      'https://api-img.discogs.com/kAXVhuZuh_uat5NNr50zMjN7lho=/fit-in/300x300/filters:strip_icc():format(jpeg):mode_rgb()/discogs-images/R-249504-1334592212.jpeg.jpg',
  rating: 3,
  dateAdded: '2019-06-22T14:34:40-07:00',
);
final List<CollectionAlbum> testAlbums = [testAlbum1, testAlbum2];

const int testAlbumDetails1DurationInSeconds = 4 * 60 + 44 + 3 * 60;
final AlbumDetails testAlbumDetails1 = AlbumDetails(
  releaseId: 456,
  artist: 'Radiohead',
  title: 'OK Computer',
  thumbUrl:
      'https://api-img.discogs.com/kAXVhuZuh_uat5NNr50zMjN7lho=/fit-in/300x300/filters:strip_icc():format(jpeg):mode_rgb()/discogs-images/R-249504-1334592212.jpeg.jpg',
  tracks: [
    AlbumTrack(title: 'Airbag', duration: '4:44'),
    AlbumTrack(title: 'Paranoid Android', position: 'A2'),
    AlbumTrack(title: 'Subterranean Homesick Alien', subTracks: [
      AlbumTrack(title: 'Exit Music (For A Film)'),
      AlbumTrack(title: 'Let Down'),
    ]),
  ],
);
