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