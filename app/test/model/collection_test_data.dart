const jsonForCollectionPageOneWithTwoAlbums = '''{
  "pagination": {
    "per_page": 2,
    "items": 5,
    "page": 1,
    "urls": {
      "last": "https://api.discogs.com/users/test_user/collection/folders/0/releases?sort=added&per_page=2&sort_order=desc&page=3",
      "next": "https://api.discogs.com/users/test_user/collection/folders/0/releases?sort=added&per_page=2&sort_order=desc&page=2"
    },
    "pages": 3
  },
  "releases": [
    {
      "instance_id": 428475133,
      "date_added": "2020-01-10T03:26:47-08:00",
      "basic_information": {
        "labels": [
          {
            "name": "Analog Spark",
            "entity_type": "1",
            "catno": "AS00033",
            "resource_url": "https://api.discogs.com/labels/900641",
            "id": 900641,
            "entity_type_name": "Label"
          },
          {
            "name": "Universal Music Special Markets",
            "entity_type": "1",
            "catno": "B0025998-01",
            "resource_url": "https://api.discogs.com/labels/56128",
            "id": 56128,
            "entity_type_name": "Label"
          }
        ],
        "year": 2017,
        "master_url": "https://api.discogs.com/masters/51023",
        "artists": [
          {
            "join": "",
            "name": "The Cranberries",
            "anv": "",
            "tracks": "",
            "role": "",
            "resource_url": "https://api.discogs.com/artists/155833",
            "id": 155833
          }
        ],
        "id": 10485244,
        "thumb": "",
        "title": "Everybody Else Is Doing It, So Why Can't We?",
        "formats": [
          {
            "descriptions": [
              "LP",
              "Album",
              "Reissue"
            ],
            "text": "Gatefold, 180 Gram",
            "name": "Vinyl",
            "qty": "1"
          }
        ],
        "cover_image": "",
        "resource_url": "https://api.discogs.com/releases/10485244",
        "master_id": 51023
      },
      "id": 10485244,
      "rating": 0
    },
    {
      "instance_id": 426579199,
      "date_added": "2020-01-03T07:20:02-08:00",
      "basic_information": {
        "labels": [
          {
            "name": "Fader Label",
            "entity_type": "1",
            "catno": "9299184310",
            "resource_url": "https://api.discogs.com/labels/44882",
            "id": 44882,
            "entity_type_name": "Label"
          }
        ],
        "year": 2019,
        "master_url": "https://api.discogs.com/masters/1595350",
        "artists": [
          {
            "join": "",
            "name": "Clairo (2)",
            "anv": "",
            "tracks": "",
            "role": "",
            "resource_url": "https://api.discogs.com/artists/6512329",
            "id": 6512329
          }
        ],
        "id": 14225762,
        "thumb": "",
        "title": "Immunity",
        "formats": [
          {
            "descriptions": [
              "LP",
              "Album"
            ],
            "name": "Vinyl",
            "qty": "1"
          }
        ],
        "cover_image": "",
        "resource_url": "https://api.discogs.com/releases/14225762",
        "master_id": 1595350
      },
      "id": 14225762,
      "rating": 0
    }
  ]
}''';

const jsonForCollectionPageTwoWithTwoAlbums =
    r'{"pagination": {"per_page": 2, "items": 5, "page": 2, "urls": {"next": "https://api.discogs.com/users/test_user/collection/folders/0/releases?sort=added&per_page=2&sort_order=desc&page=3", "prev": "https://api.discogs.com/users/test_user/collection/folders/0/releases?sort=added&per_page=2&sort_order=desc&page=1", "last": "https://api.discogs.com/users/test_user/collection/folders/0/releases?sort=added&per_page=2&sort_order=desc&page=3", "first": "https://api.discogs.com/users/test_user/collection/folders/0/releases?sort=added&per_page=2&sort_order=desc&page=1"}, "pages": 3}, "releases": [{"instance_id": 426578531, "date_added": "2020-01-03T07:17:36-08:00", "basic_information": {"labels": [{"name": "Reprise Records", "entity_type": "1", "catno": "MS 2038", "resource_url": "https://api.discogs.com/labels/157", "id": 157, "entity_type_name": "Label"}, {"name": "Reprise Records", "entity_type": "1", "catno": "7599 27199-1", "resource_url": "https://api.discogs.com/labels/157", "id": 157, "entity_type_name": "Label"}, {"name": "Reprise Records", "entity_type": "1", "catno": "REP 44 128", "resource_url": "https://api.discogs.com/labels/157", "id": 157, "entity_type_name": "Label"}], "year": 0, "master_url": "https://api.discogs.com/masters/47744", "artists": [{"join": "", "name": "Joni Mitchell", "anv": "", "tracks": "", "role": "", "resource_url": "https://api.discogs.com/artists/90233", "id": 90233}], "id": 4509162, "thumb": "", "title": "Blue", "formats": [{"descriptions": ["LP", "Album", "Reissue"], "text": "180g", "name": "Vinyl", "qty": "1"}], "cover_image": "", "resource_url": "https://api.discogs.com/releases/4509162", "master_id": 47744}, "id": 4509162, "rating": 4}, {"instance_id": 373770067, "date_added": "2019-05-07T09:37:21-07:00", "basic_information": {"styles": ["Impressionist"], "labels": [{"name": "La Voix De Son Ma\u00eetre", "entity_type": "1", "catno": "2C 069-10239", "resource_url": "https://api.discogs.com/labels/63488", "id": 63488, "entity_type_name": "Label"}, {"name": "La Voix De Son Ma\u00eetre", "entity_type": "1", "catno": "2C 069-10.239", "resource_url": "https://api.discogs.com/labels/63488", "id": 63488, "entity_type_name": "Label"}], "year": 0, "master_url": "https://api.discogs.com/masters/420813", "artists": [{"join": "\u2013", "name": "Maurice Ravel", "anv": "Ravel", "tracks": "", "role": "", "resource_url": "https://api.discogs.com/artists/216140", "id": 216140}, {"join": ",", "name": "Charles Munch", "anv": "", "tracks": "", "role": "", "resource_url": "https://api.discogs.com/artists/406273", "id": 406273}, {"join": "", "name": "Orchestre De Paris", "anv": "", "tracks": "", "role": "", "resource_url": "https://api.discogs.com/artists/744724", "id": 744724}], "id": 1287017, "genres": ["Classical"], "thumb": "", "title": "Bolero, Rapsodie Espagnole, Pavane Pour Une Infante D\u00e9funte, Daphnis Et Chlo\u00e9, Suite N\u00b0 2", "formats": [{"descriptions": ["LP", "Reissue", "Stereo"], "name": "Vinyl", "qty": "1"}], "cover_image": "", "resource_url": "https://api.discogs.com/releases/1287017", "master_id": 420813}, "id": 1287017, "rating": 0}]}';

const jsonForCollectionLastPageWithOneAlbum =
    '{"pagination": {"per_page": 2, "items": 5, "page": 3, "urls": {"prev": "https://api.discogs.com/users/test_user/collection/folders/0/releases?sort=added&per_page=2&sort_order=desc&page=235", "first": "https://api.discogs.com/users/test_user/collection/folders/0/releases?sort=added&per_page=2&sort_order=desc&page=1"}, "pages": 3}, "releases": [{"instance_id": 32925711, "date_added": "2013-01-17T13:44:29-08:00", "basic_information": {"labels": [{"name": "Warp Records", "entity_type": "1", "catno": "WARPLP182R", "resource_url": "https://api.discogs.com/labels/23528", "id": 23528, "entity_type_name": "Label"}], "year": 2012, "master_url": "https://api.discogs.com/masters/107989", "artists": [{"join": "", "name": "Grizzly Bear", "anv": "", "tracks": "", "role": "", "resource_url": "https://api.discogs.com/artists/385924", "id": 385924}], "id": 3852834, "thumb": "", "title": "Veckatimest", "formats": [{"descriptions": ["Album", "Reissue", "LP"], "text": "180gram", "name": "Vinyl", "qty": "2"}], "cover_image": "", "resource_url": "https://api.discogs.com/releases/3852834", "master_id": 107989}, "id": 3852834, "rating": 0}]}';

const jsonForRelease = r'''{
    "title": "Never Gonna Give You Up",
    "id": 249504,
    "artists": [
        {
            "anv": "",
            "id": 72872,
            "join": "",
            "name": "Rick Astley",
            "resource_url": "https://api.discogs.com/artists/72872",
            "role": "",
            "tracks": ""
        }
    ],
    "data_quality": "Correct",
    "thumb": "https://api-img.discogs.com/kAXVhuZuh_uat5NNr50zMjN7lho=/fit-in/300x300/filters:strip_icc():format(jpeg):mode_rgb()/discogs-images/R-249504-1334592212.jpeg.jpg",
    "community": {
        "contributors": [
            {
                "resource_url": "https://api.discogs.com/users/memory",
                "username": "memory"
            },
            {
                "resource_url": "https://api.discogs.com/users/_80_",
                "username": "_80_"
            }
        ],
        "data_quality": "Correct",
        "have": 252,
        "rating": {
            "average": 3.42,
            "count": 45
        },
        "status": "Accepted",
        "submitter": {
            "resource_url": "https://api.discogs.com/users/memory",
            "username": "memory"
        },
        "want": 42
    },
    "companies": [
        {
            "catno": "",
            "entity_type": "13",
            "entity_type_name": "Phonographic Copyright (p)",
            "id": 82835,
            "name": "BMG Records (UK) Ltd.",
            "resource_url": "https://api.discogs.com/labels/82835"
        },
        {
            "catno": "",
            "entity_type": "29",
            "entity_type_name": "Mastered At",
            "id": 266218,
            "name": "Utopia Studios",
            "resource_url": "https://api.discogs.com/labels/266218"
        }
    ],
    "country": "UK",
    "date_added": "2004-04-30T08:10:05-07:00",
    "date_changed": "2012-12-03T02:50:12-07:00",
    "estimated_weight": 60,
    "extraartists": [
        {
            "anv": "Me Co",
            "id": 547352,
            "join": "",
            "name": "Me Company",
            "resource_url": "https://api.discogs.com/artists/547352",
            "role": "Design",
            "tracks": ""
        },
        {
            "anv": "Stock / Aitken / Waterman",
            "id": 20942,
            "join": "",
            "name": "Stock, Aitken & Waterman",
            "resource_url": "https://api.discogs.com/artists/20942",
            "role": "Producer, Written-By",
            "tracks": ""
        }
    ],
    "format_quantity": 1,
    "formats": [
        {
            "descriptions": [
                "7\"",
                "Single",
                "45 RPM"
            ],
            "name": "Vinyl",
            "qty": "1"
        }
    ],
    "genres": [
        "Electronic",
        "Pop"
    ],
    "identifiers": [
        {
            "type": "Barcode",
            "value": "5012394144777"
        }
    ],
    "images": [
        {
            "height": 600,
            "resource_url": "https://api-img.discogs.com/z_u8yqxvDcwVnR4tX2HLNLaQO2Y=/fit-in/600x600/filters:strip_icc():format(jpeg):mode_rgb():quality(96)/discogs-images/R-249504-1334592212.jpeg.jpg",
            "type": "primary",
            "uri": "https://api-img.discogs.com/z_u8yqxvDcwVnR4tX2HLNLaQO2Y=/fit-in/600x600/filters:strip_icc():format(jpeg):mode_rgb():quality(96)/discogs-images/R-249504-1334592212.jpeg.jpg",
            "uri150": "https://api-img.discogs.com/0ZYgPR4X2HdUKA_jkhPJF4SN5mM=/fit-in/150x150/filters:strip_icc():format(jpeg):mode_rgb()/discogs-images/R-249504-1334592212.jpeg.jpg",
            "width": 600
        },
        {
            "height": 600,
            "resource_url": "https://api-img.discogs.com/EnQXaDOs5T6YI9zq-R5I_mT7hSk=/fit-in/600x600/filters:strip_icc():format(jpeg):mode_rgb():quality(96)/discogs-images/R-249504-1334592228.jpeg.jpg",
            "type": "secondary",
            "uri": "https://api-img.discogs.com/EnQXaDOs5T6YI9zq-R5I_mT7hSk=/fit-in/600x600/filters:strip_icc():format(jpeg):mode_rgb():quality(96)/discogs-images/R-249504-1334592228.jpeg.jpg",
            "uri150": "https://api-img.discogs.com/abk0FWgWsRDjU4bkCDwk0gyMKBo=/fit-in/150x150/filters:strip_icc():format(jpeg):mode_rgb()/discogs-images/R-249504-1334592228.jpeg.jpg",
            "width": 600
        }
    ],
    "labels": [
        {
            "catno": "PB 41447",
            "entity_type": "1",
            "id": 895,
            "name": "RCA",
            "resource_url": "https://api.discogs.com/labels/895"
        }
    ],
    "lowest_price": 0.63,
    "master_id": 96559,
    "master_url": "https://api.discogs.com/masters/96559",
    "notes": "UK Release has a black label with the text \"Manufactured In England\" printed on it.\r\n\r\nSleeve:\r\n\u2117 1987 \u2022 BMG Records (UK) Ltd. \u00a9 1987 \u2022 BMG Records (UK) Ltd.\r\nDistributed in the UK by BMG Records \u2022  Distribu\u00e9 en Europe par BMG/Ariola \u2022 Vertrieb en Europa d\u00fcrch BMG/Ariola.\r\n\r\nCenter labels:\r\n\u2117 1987 Pete Waterman Ltd.\r\nOriginal Sound Recording made by PWL.\r\nBMG Records (UK) Ltd. are the exclusive licensees for the world.\r\n\r\nDurations do not appear on the release.\r\n",
    "num_for_sale": 58,
    "released": "1987",
    "released_formatted": "1987",
    "resource_url": "https://api.discogs.com/releases/249504",
    "series": [],
    "status": "Accepted",
    "styles": [
        "Synth-pop"
    ],
    "tracklist": [
        {
            "duration": "3:32",
            "position": "A",
            "title": "Never Gonna Give You Up",
            "type_": "track"
        },
        {
            "duration": "3:30",
            "position": "B",
            "title": "Never Gonna Give You Up (Instrumental)",
            "type_": "track"
        }
    ],
    "uri": "http://www.discogs.com/Rick-Astley-Never-Gonna-Give-You-Up/release/249504",
    "videos": [
        {
            "description": "Rick Astley - Never Gonna Give You Up (Extended Version)",
            "duration": 330,
            "embed": true,
            "title": "Rick Astley - Never Gonna Give You Up (Extended Version)",
            "uri": "https://www.youtube.com/watch?v=te2jJncBVG4"
        }
    ],
    "year": 1987
}''';

const jsonForReleaseWithSubtracks =
    r'{"styles": ["Impressionist"], "series": [], "labels": [{"name": "La Voix De Son Ma\u00eetre", "entity_type": "1", "catno": "2C 069-10239", "resource_url": "https://api.discogs.com/labels/63488", "id": 63488, "entity_type_name": "Label"}, {"name": "La Voix De Son Ma\u00eetre", "entity_type": "1", "catno": "2C 069-10.239", "resource_url": "https://api.discogs.com/labels/63488", "id": 63488, "entity_type_name": "Label"}], "year": 0, "community": {"status": "Accepted", "rating": {"count": 9, "average": 4.11}, "have": 199, "contributors": [{"username": "pyratek", "resource_url": "https://api.discogs.com/users/pyratek"}, {"username": "Villars", "resource_url": "https://api.discogs.com/users/Villars"}, {"username": "Ktrump5", "resource_url": "https://api.discogs.com/users/Ktrump5"}, {"username": "IbLeo", "resource_url": "https://api.discogs.com/users/IbLeo"}, {"username": "grave_auch", "resource_url": "https://api.discogs.com/users/grave_auch"}, {"username": "jeroenpeys", "resource_url": "https://api.discogs.com/users/jeroenpeys"}, {"username": "9kqzxu3", "resource_url": "https://api.discogs.com/users/9kqzxu3"}, {"username": "vivaldi55", "resource_url": "https://api.discogs.com/users/vivaldi55"}, {"username": "alfredpinetree", "resource_url": "https://api.discogs.com/users/alfredpinetree"}], "want": 5, "submitter": {"username": "pyratek", "resource_url": "https://api.discogs.com/users/pyratek"}, "data_quality": "Needs Vote"}, "artists": [{"join": "\u2013", "name": "Maurice Ravel", "anv": "Ravel", "tracks": "", "role": "", "resource_url": "https://api.discogs.com/artists/216140", "id": 216140}, {"join": ",", "name": "Charles Munch", "anv": "", "tracks": "", "role": "", "resource_url": "https://api.discogs.com/artists/406273", "id": 406273}, {"join": "", "name": "Orchestre De Paris", "anv": "", "tracks": "", "role": "", "resource_url": "https://api.discogs.com/artists/744724", "id": 744724}], "images": [{"uri": "", "height": 592, "width": 600, "resource_url": "", "type": "primary", "uri150": ""}, {"uri": "", "height": 450, "width": 600, "resource_url": "", "type": "secondary", "uri150": ""}, {"uri": "", "height": 450, "width": 600, "resource_url": "", "type": "secondary", "uri150": ""}, {"uri": "", "height": 450, "width": 600, "resource_url": "", "type": "secondary", "uri150": ""}, {"uri": "", "height": 450, "width": 600, "resource_url": "", "type": "secondary", "uri150": ""}, {"uri": "", "height": 573, "width": 600, "resource_url": "", "type": "secondary", "uri150": ""}, {"uri": "", "height": 450, "width": 600, "resource_url": "", "type": "secondary", "uri150": ""}, {"uri": "", "height": 496, "width": 600, "resource_url": "", "type": "secondary", "uri150": ""}, {"uri": "", "height": 450, "width": 600, "resource_url": "", "type": "secondary", "uri150": ""}, {"uri": "", "height": 450, "width": 600, "resource_url": "", "type": "secondary", "uri150": ""}], "format_quantity": 1, "id": 1287017, "artists_sort": "Maurice Ravel \u2013 Charles Munch, Orchestre De Paris", "genres": ["Classical"], "thumb": "", "num_for_sale": 22, "title": "Bolero, Rapsodie Espagnole, Pavane Pour Une Infante D\u00e9funte, Daphnis Et Chlo\u00e9, Suite N\u00b0 2", "date_changed": "2019-06-28T15:45:00-07:00", "master_id": 420813, "lowest_price": 3.26, "status": "Accepted", "estimated_weight": 230, "master_url": "https://api.discogs.com/masters/420813", "date_added": "2009-02-24T00:13:59-08:00", "tracklist": [{"duration": "17:05", "position": "A1", "type_": "track", "title": "Bol\u00e9ro"}, {"duration": "6:43", "position": "A2", "type_": "track", "title": "Pavane Pour Une Infante D\u00e9funte"}, {"duration": "15:31", "position": "", "type_": "index", "sub_tracks": [{"duration": "4:56", "position": "A3", "type_": "track", "title": "Pr\u00e9lude \u00c0 La Nuit"}, {"duration": "2:01", "position": "B1", "type_": "track", "title": "Malague\u00f1a"}, {"duration": "2:49", "position": "B2", "type_": "track", "title": "Haba\u00f1era"}, {"duration": "6:25", "position": "B3", "type_": "track", "title": "Feria"}], "title": "Rapsodie Espagnole"}, {"duration": "18:05", "position": "", "type_": "index", "sub_tracks": [{"duration": "", "position": "B4.1", "type_": "track", "title": "Lever Du Jour"}, {"duration": "", "position": "B4.2", "type_": "track", "title": "Pantomime"}, {"duration": "", "position": "B4.3", "type_": "track", "title": "Danse G\u00e9n\u00e9rale"}], "title": "Daphnis Et Chlo\u00e9 - Ballet En Un Acte - Fragments Symphoniques (Deuxi\u00e8me S\u00e9rie)"}], "extraartists": [{"join": "", "name": "Maurice Ravel", "anv": "", "tracks": "", "role": "Composed By", "resource_url": "https://api.discogs.com/artists/216140", "id": 216140}, {"join": "", "name": "Charles Munch", "anv": "", "tracks": "", "role": "Conductor", "resource_url": "https://api.discogs.com/artists/406273", "id": 406273}, {"join": "", "name": "Pierre Hi\u00e9gel", "anv": "", "tracks": "", "role": "Liner Notes [French only about Munch]", "resource_url": "https://api.discogs.com/artists/547872", "id": 547872}, {"join": "", "name": "Marcel Schneider (2)", "anv": "", "tracks": "", "role": "Liner Notes [French only about Ravel]", "resource_url": "https://api.discogs.com/artists/1849384", "id": 1849384}, {"join": "", "name": "Orchestre De Paris", "anv": "", "tracks": "", "role": "Orchestra", "resource_url": "https://api.discogs.com/artists/744724", "id": 744724}, {"join": "", "name": "J.-F. Guitton", "anv": "", "tracks": "", "role": "Photography By", "resource_url": "https://api.discogs.com/artists/2251209", "id": 2251209}], "country": "France", "notes": "\u2117 1969 Path\u00e9 Marconi EMI\nMade in France\nSt\u00e9r\u00e9o enregistrement d\u2019origine St\u00e9r\u00e9o\n\u00c9ditions Durand.\n\nFrame red\nComes in a gatefold sleeve.\n", "identifiers": [{"type": "Matrix / Runout", "description": "Center Label A", "value": "C 069-10.239 A"}, {"type": "Matrix / Runout", "description": "Center Label B", "value": "C 069-10.239 B"}, {"type": "Matrix / Runout", "description": "Engraved Side A", "value": "10 239 A 21 F M6 328696 4"}, {"type": "Matrix / Runout", "description": "Engraved Side B ", "value": "10239 B 21 H  M6 329173 4"}, {"type": "Price Code", "value": "PM 371"}, {"type": "Rights Society", "value": "SACEM,SDRM,SACD, SGDL"}], "companies": [{"name": "EMI", "entity_type": "4", "catno": "", "resource_url": "https://api.discogs.com/labels/26126", "id": 26126, "entity_type_name": "Record Company"}, {"name": "Path\u00e9 Marconi EMI", "entity_type": "16", "catno": "", "resource_url": "https://api.discogs.com/labels/27145", "id": 27145, "entity_type_name": "Made By"}, {"name": "Path\u00e9 Marconi EMI", "entity_type": "13", "catno": "", "resource_url": "https://api.discogs.com/labels/27145", "id": 27145, "entity_type_name": "Phonographic Copyright (p)"}, {"name": "Offset France", "entity_type": "19", "catno": "", "resource_url": "https://api.discogs.com/labels/272630", "id": 272630, "entity_type_name": "Printed By"}, {"name": "\u00c9ditions Durand", "entity_type": "21", "catno": "", "resource_url": "https://api.discogs.com/labels/434683", "id": 434683, "entity_type_name": "Published By"}, {"name": "\u00c9ditions Max Eschig", "entity_type": "21", "catno": "", "resource_url": "https://api.discogs.com/labels/323233", "id": 323233, "entity_type_name": "Published By"}, {"name": "Path\u00e9 Marconi EMI, Chatou", "entity_type": "17", "catno": "328696", "resource_url": "https://api.discogs.com/labels/407953", "id": 407953, "entity_type_name": "Pressed By"}, {"name": "Path\u00e9 Marconi EMI, Chatou", "entity_type": "17", "catno": "329173", "resource_url": "https://api.discogs.com/labels/407953", "id": 407953, "entity_type_name": "Pressed By"}], "uri": "https://www.discogs.com/Ravel-Charles-Munch-Orchestre-De-Paris-Bolero-Rapsodie-Espagnole-Pavane-Pour-Une-Infante-D%C3%A9funte-Da/release/1287017", "formats": [{"descriptions": ["LP", "Reissue", "Stereo"], "name": "Vinyl", "qty": "1"}], "resource_url": "https://api.discogs.com/releases/1287017", "data_quality": "Needs Vote"}';

const jsonForReleaseWithTwoArtists = r'''
{
   "id":6895819,
   "status":"Accepted",
   "year":2015,
   "resource_url":"https://api.discogs.com/releases/6895819",
   "uri":"https://www.discogs.com/release/6895819-Former-Ghosts-Funeral-Advantage-Split",
   "artists":[
      {
         "name":"Former Ghosts",
         "anv":"",
         "join":",",
         "role":"",
         "tracks":"",
         "id":1617253,
         "resource_url":"https://api.discogs.com/artists/1617253"
      },
      {
         "name":"Funeral Advantage",
         "anv":"",
         "join":"",
         "role":"",
         "tracks":"",
         "id":3165217,
         "resource_url":"https://api.discogs.com/artists/3165217"
      }
   ],
   "artists_sort":"Former Ghosts, Funeral Advantage",
   "labels":[
      {
         "name":"The Native Sound",
         "catno":"NATIVE 011",
         "entity_type":"1",
         "entity_type_name":"Label",
         "id":573035,
         "resource_url":"https://api.discogs.com/labels/573035"
      }
   ],
   "series":[
      
   ],
   "companies":[
      
   ],
   "formats":[
      {
         "name":"Vinyl",
         "qty":"1",
         "text":"Translucent Red",
         "descriptions":[
            "7\"",
            "33 \u2153 RPM",
            "EP",
            "Limited Edition"
         ]
      }
   ],
   "data_quality":"Needs Vote",
   "community":{
      "have":34,
      "want":38,
      "rating":{
         "count":1,
         "average":5.0
      },
      "submitter":{
         "username":"Citizenihilist",
         "resource_url":"https://api.discogs.com/users/Citizenihilist"
      },
      "contributors":[
         {
            "username":"Citizenihilist",
            "resource_url":"https://api.discogs.com/users/Citizenihilist"
         },
         {
            "username":"45RPMenjoyer",
            "resource_url":"https://api.discogs.com/users/45RPMenjoyer"
         }
      ],
      "data_quality":"Needs Vote",
      "status":"Accepted"
   },
   "format_quantity":1,
   "date_added":"2015-04-13T19:35:06-07:00",
   "date_changed":"2015-07-04T18:41:50-07:00",
   "num_for_sale":0,
   "lowest_price":null,
   "master_id":856468,
   "master_url":"https://api.discogs.com/masters/856468",
   "title":"Split",
   "released":"2015-04-14",
   "notes":"Pressing history:\r\n100 \u2013 Translucent Red (THIS)\r\n200 \u2013 Black",
   "released_formatted":"14 Apr 2015",
   "identifiers":[
      
   ],
   "videos":[
      {
         "uri":"https://www.youtube.com/watch?v=2G2seXAC6pA",
         "title":"Funeral Advantage \u2013 Wedding (Audio)",
         "description":"Download Former Ghosts/ Funeral Advantage's Split EP on iTunes: https://itun.es/us/uE6a6  \n\nPick up Former Ghosts/ Funeral Advantage's Split EP on limited edition vinyl @ http://thenativesound.limitedrun.com/products/540546-former-ghosts-funeral-advantage",
         "duration":222,
         "embed":true
      },
      {
         "uri":"https://www.youtube.com/watch?v=Y6XMpFrhemg",
         "title":"I Know Him",
         "description":"Provided to YouTube by Ingrooves\n\nI Know Him \u00b7 Funeral Advantage\n\nSplit with Former Ghosts, Funeral Advantage\n\n\u2117 2015 The Native Sound\n\nReleased on: 2015-04-14\n\nWriter: Funeral Advantage\n\nAuto-generated by YouTube.",
         "duration":165,
         "embed":true
      },
      {
         "uri":"https://www.youtube.com/watch?v=NXxEi1XUoiI",
         "title":"Last Hour's Bow (feat. Yasmine Kittles)",
         "description":"Provided to YouTube by Ingrooves\n\nLast Hour's Bow (feat. Yasmine Kittles) \u00b7 Former Ghosts\n\nSplit with Former Ghosts, Funeral Advantage\n\n\u2117 2015 The Native Sound\n\nReleased on: 2015-04-14\n\nWriter: Former Ghosts\n\nAuto-generated by YouTube.",
         "duration":190,
         "embed":true
      },
      {
         "uri":"https://www.youtube.com/watch?v=YtFL5zMcPTs",
         "title":"Wedding",
         "description":"Provided to YouTube by Ingrooves\n\nWedding \u00b7 Funeral Advantage\n\nSplit with Former Ghosts, Funeral Advantage\n\n\u2117 2015 The Native Sound\n\nReleased on: 2015-04-14\n\nWriter: Funeral Advantage\n\nAuto-generated by YouTube.",
         "duration":222,
         "embed":true
      }
   ],
   "genres":[
      "Rock",
      "Pop"
   ],
   "styles":[
      "Shoegaze",
      "Indie Pop",
      "Post-Punk"
   ],
   "tracklist":[
      {
         "position":"A1",
         "type_":"track",
         "artists":[
            {
               "name":"Former Ghosts",
               "anv":"",
               "join":"",
               "role":"",
               "tracks":"",
               "id":1617253,
               "resource_url":"https://api.discogs.com/artists/1617253"
            }
         ],
         "title":"Last Hour's Bow",
         "duration":""
      },
      {
         "position":"A2",
         "type_":"track",
         "artists":[
            {
               "name":"Former Ghosts",
               "anv":"",
               "join":"",
               "role":"",
               "tracks":"",
               "id":1617253,
               "resource_url":"https://api.discogs.com/artists/1617253"
            }
         ],
         "title":"Past Selves",
         "duration":""
      },
      {
         "position":"B1",
         "type_":"track",
         "artists":[
            {
               "name":"Funeral Advantage",
               "anv":"",
               "join":"",
               "role":"",
               "tracks":"",
               "id":3165217,
               "resource_url":"https://api.discogs.com/artists/3165217"
            }
         ],
         "title":"Wedding",
         "duration":""
      },
      {
         "position":"B2",
         "type_":"track",
         "artists":[
            {
               "name":"Funeral Advantage",
               "anv":"",
               "join":"",
               "role":"",
               "tracks":"",
               "id":3165217,
               "resource_url":"https://api.discogs.com/artists/3165217"
            }
         ],
         "title":"I Know Him",
         "duration":""
      }
   ],
   "extraartists":[
      
   ],
   "images":[
      {
         "type":"primary",
         "uri":"",
         "resource_url":"",
         "uri150":"",
         "width":480,
         "height":480
      },
      {
         "type":"secondary",
         "uri":"",
         "resource_url":"",
         "uri150":"",
         "width":600,
         "height":600
      }
   ],
   "thumb":"",
   "estimated_weight":60,
   "blocked_from_sale":false
}
''';
