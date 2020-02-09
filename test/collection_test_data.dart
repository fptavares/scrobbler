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

const jsonForCollectionPageTwoWithTwoAlbums = '{"pagination": {"per_page": 2, "items": 5, "page": 2, "urls": {"next": "https://api.discogs.com/users/test_user/collection/folders/0/releases?sort=added&per_page=2&sort_order=desc&page=3", "prev": "https://api.discogs.com/users/test_user/collection/folders/0/releases?sort=added&per_page=2&sort_order=desc&page=1", "last": "https://api.discogs.com/users/test_user/collection/folders/0/releases?sort=added&per_page=2&sort_order=desc&page=3", "first": "https://api.discogs.com/users/test_user/collection/folders/0/releases?sort=added&per_page=2&sort_order=desc&page=1"}, "pages": 3}, "releases": [{"instance_id": 426578531, "date_added": "2020-01-03T07:17:36-08:00", "basic_information": {"labels": [{"name": "Reprise Records", "entity_type": "1", "catno": "MS 2038", "resource_url": "https://api.discogs.com/labels/157", "id": 157, "entity_type_name": "Label"}, {"name": "Reprise Records", "entity_type": "1", "catno": "7599 27199-1", "resource_url": "https://api.discogs.com/labels/157", "id": 157, "entity_type_name": "Label"}, {"name": "Reprise Records", "entity_type": "1", "catno": "REP 44 128", "resource_url": "https://api.discogs.com/labels/157", "id": 157, "entity_type_name": "Label"}], "year": 0, "master_url": "https://api.discogs.com/masters/47744", "artists": [{"join": "", "name": "Joni Mitchell", "anv": "", "tracks": "", "role": "", "resource_url": "https://api.discogs.com/artists/90233", "id": 90233}], "id": 4509162, "thumb": "", "title": "Blue", "formats": [{"descriptions": ["LP", "Album", "Reissue"], "text": "180g", "name": "Vinyl", "qty": "1"}], "cover_image": "", "resource_url": "https://api.discogs.com/releases/4509162", "master_id": 47744}, "id": 4509162, "rating": 4}, {"instance_id": 426572305, "date_added": "2020-01-03T06:55:18-08:00", "basic_information": {"labels": [{"name": "Virgin", "entity_type": "1", "catno": "7243 8 49253 1 4", "resource_url": "https://api.discogs.com/labels/750", "id": 750, "entity_type_name": "Label"}], "year": 2008, "master_url": "https://api.discogs.com/masters/20866", "artists": [{"join": "", "name": "A Perfect Circle", "anv": "", "tracks": "", "role": "", "resource_url": "https://api.discogs.com/artists/242802", "id": 242802}], "id": 1450554, "thumb": "", "title": "Mer De Noms", "formats": [{"descriptions": ["LP", "Album", "Limited Edition", "Reissue"], "text": "Gatefold, 180 gram", "name": "Vinyl", "qty": "2"}], "cover_image": "", "resource_url": "https://api.discogs.com/releases/1450554", "master_id": 20866}, "id": 1450554, "rating": 0}]}';

const jsonForCollectionLastPageWithOneAlbum = '{"pagination": {"per_page": 2, "items": 5, "page": 3, "urls": {"prev": "https://api.discogs.com/users/test_user/collection/folders/0/releases?sort=added&per_page=2&sort_order=desc&page=235", "first": "https://api.discogs.com/users/test_user/collection/folders/0/releases?sort=added&per_page=2&sort_order=desc&page=1"}, "pages": 3}, "releases": [{"instance_id": 32925711, "date_added": "2013-01-17T13:44:29-08:00", "basic_information": {"labels": [{"name": "Warp Records", "entity_type": "1", "catno": "WARPLP182R", "resource_url": "https://api.discogs.com/labels/23528", "id": 23528, "entity_type_name": "Label"}], "year": 2012, "master_url": "https://api.discogs.com/masters/107989", "artists": [{"join": "", "name": "Grizzly Bear", "anv": "", "tracks": "", "role": "", "resource_url": "https://api.discogs.com/artists/385924", "id": 385924}], "id": 3852834, "thumb": "", "title": "Veckatimest", "formats": [{"descriptions": ["Album", "Reissue", "LP"], "text": "180gram", "name": "Vinyl", "qty": "2"}], "cover_image": "", "resource_url": "https://api.discogs.com/releases/3852834", "master_id": 107989}, "id": 3852834, "rating": 0}]}';

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