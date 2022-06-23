import 'package:scrobbler_bluos_monitor/src/playlist.dart';

const track1Xml = spotifyConnectXml;
final track1Expected = spotifyConnectExpected;
final track1ExpectedState = spotifyConnectExpectedState;

const track2Xml = radioParadiseXml;
final track2Expected = radioParadiseExpected;
final track2ExpectedState = radioParadiseExpectedState;

const track3Xml = tidalXml;
final track3Expected = tidalExpected;
final track3ExpectedState = tidalExpectedState;

const radioParadiseXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<status etag="4a946635b01af97de8ffa7129b0ad5ab">
	<actions>
		<action name="back"/>
		<action name="skip" url="/Action?service=RadioParadise&amp;next=2282807"/>
		<action icon="/images/loveban/love.png" name="love" state="-1" text="Love" type="thumbs" url="/Action?service=RadioParadise&amp;love=43704&amp;reset=0"/>
		<action icon="/images/loveban/ban.png" name="ban" state="-1" text="Ban" type="thumbs" url="/Action?service=RadioParadise&amp;ban=43704&amp;reset=0"/>
		<action name="shop" url="/Action?service=RadioParadise&amp;getBuyUrl=https%3A%2F%2Fassoc-redirect.amazon.com%2Fg%2Fr%2Fhttps%3A%2F%2Fwww.amazon.com%2Fdp%2FB00H5G4Y68%3Ftag%3Dradioparadise-20"/>
	</actions>
	<album>The Secret Life Of Walter Mitty (Soundtrack)</album>
	<artist>José González</artist>
	<canMovePlayback>true</canMovePlayback>
	<canSeek>0</canSeek>
	<currentImage>https://img.radioparadise.com/covers/l/B00GG429KS.jpg</currentImage>
	<cursor>184</cursor>
	<db>0</db>
	<image>https://img.radioparadise.com/covers/l/B00GG429KS.jpg</image>
	<indexing>0</indexing>
	<inputId>RadioParadise</inputId>
	<lyricsid>43704</lyricsid>
	<mid>29</mid>
	<mode>1</mode>
	<mute>0</mute>
	<pid>270</pid>
	<prid>0</prid>
	<quality>cd</quality>
	<repeat>2</repeat>
	<schemaVersion>34</schemaVersion>
	<service>RadioParadise</service>
	<serviceIcon>/Sources/images/ParadiseRadioIcon.png</serviceIcon>
	<serviceName>Radio Paradise</serviceName>
	<shuffle>0</shuffle>
	<sid>4</sid>
	<sleep></sleep>
	<song>0</song>
	<state>stream</state>
	<stationImage>/Sources/images/ParadiseRadioIcon.png</stationImage>
	<streamFormat>FLAC 44100/16/2</streamFormat>
	<streamUrl>RadioParadise:/0:20</streamUrl>
	<syncStat>34</syncStat>
	<title1>Radio Paradise</title1>
	<title2>Stay Alive</title2>
	<title3>José González • The Secret Life Of Walter Mitty (Soundtrack)</title3>
	<volume>100</volume>
	<secs>3421</secs>
</status>
''';

final radioParadiseExpected = BluOSAPITrack(
  queuePosition: '0',
  artist: 'José González',
  title: 'Stay Alive',
  album: 'The Secret Life Of Walter Mitty (Soundtrack)',
  length: null,
  imageUrl: 'https://img.radioparadise.com/covers/l/B00GG429KS.jpg',
  initialPlaybackDuration: 3421,
);
final radioParadiseExpectedState = BluOSPlayerState('4a946635b01af97de8ffa7129b0ad5ab', 'stream', 3421);

const tidalXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<status etag="68330da5672aff2cf86a349955ced764">
	<album>And I'll Scratch Yours</album>
	<albumid>122121646</albumid>
	<artist>Elbow</artist>
	<artistid>3524691</artistid>
	<canMovePlayback>true</canMovePlayback>
	<canSeek>1</canSeek>
	<cursor>224</cursor>
	<db>0</db>
	<fn>Tidal:122121655</fn>
	<image>/Artwork?service=Tidal&amp;songid=Tidal%3A122121655</image>
	<indexing>0</indexing>
	<isFavourite>1</isFavourite>
	<mid>29</mid>
	<mode>1</mode>
	<mute>0</mute>
	<name>Mercy Street</name>
	<pid>271</pid>
	<prid>0</prid>
	<quality>hd</quality>
	<repeat>2</repeat>
	<replayGain>-8.86</replayGain>
	<service>Tidal</service>
	<serviceIcon>/Sources/images/TidalIcon.png</serviceIcon>
	<serviceName>TIDAL</serviceName>
	<shuffle>0</shuffle>
	<sid>4</sid>
	<similarstationid>Tidal:radio:artist/3524691</similarstationid>
	<sleep></sleep>
	<song>185</song>
	<songid>Tidal:122121655</songid>
	<state>play</state>
	<streamFormat>FLAC 44100/24/2</streamFormat>
	<syncStat>34</syncStat>
	<title1>Mercy Street</title1>
	<title2>Elbow</title2>
	<title3>And I'll Scratch Yours</title3>
	<totlen>339</totlen>
	<trackstationid>Tidal:radio:track/122121655</trackstationid>
	<volume>100</volume>
	<secs>0</secs>
</status>
''';

final tidalExpected = BluOSAPITrack(
  queuePosition: '185',
  artist: 'Elbow',
  title: 'Mercy Street',
  album: 'And I\'ll Scratch Yours',
  length: 339,
  imageUrl: '/Artwork?service=Tidal&songid=Tidal%3A122121655',
  initialPlaybackDuration: 0,
);
final tidalExpectedState = BluOSPlayerState('68330da5672aff2cf86a349955ced764', 'play', 0);

const tidalRadioXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<status etag="505a07fd9013c2bd83a7ee7e4c56c89e">
  <actions>
    <action name="back" />
    <action name="skip" url="/Action?service=Tidal&amp;skip=2994336" />
  </actions>
  <album>Turn The Radio Off</album>
  <albumid>2994335</albumid>
  <artist>Reel Big Fish</artist>
  <artistid>5254</artistid>
  <canMovePlayback>true</canMovePlayback>
  <canSeek>1</canSeek>
  <currentImage>/Artwork?service=Tidal&amp;albumid=2994335</currentImage>
  <cursor>0</cursor>
  <db>0</db>
  <image>/Artwork?service=Tidal&amp;albumid=2994335</image>
  <indexing>0</indexing>
  <mid>29</mid>
  <mode>1</mode>
  <mute>0</mute>
  <pid>366</pid>
  <prid>0</prid>
  <quality>cd</quality>
  <repeat>2</repeat>
  <service>Tidal</service>
  <serviceIcon>/Sources/images/TidalIcon.png</serviceIcon>
  <serviceName>TIDAL</serviceName>
  <shuffle>0</shuffle>
  <sid>5</sid>
  <sleep></sleep>
  <song>0</song>
  <songid>Tidal:2994336</songid>
  <state>stream</state>
  <streamFormat>FLAC 44100/16/2</streamFormat>
  <streamUrl>Tidal:radio:track/62096431</streamUrl>
  <syncStat>45</syncStat>
  <title1>Wrong Way Radio</title1>
  <title2>Sell Out</title2>
  <title3>Reel Big Fish • Turn The Radio Off</title3>
  <totlen>227</totlen>
  <volume>100</volume>
  <secs>212</secs>
</status>
''';

final tidalRadioExpected = BluOSAPITrack(
  queuePosition: '0',
  artist: 'Reel Big Fish',
  title: 'Sell Out',
  album: 'Turn The Radio Off',
  length: 227,
  imageUrl: '/Artwork?service=Tidal&albumid=2994335',
);
final tidalRadioExpectedState = BluOSPlayerState('505a07fd9013c2bd83a7ee7e4c56c89e', 'stream', 212);

const spotifyConnectXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<status etag="3fb2a68d257147306d6a7df8fa893455">
  <actions>
    <action androidAction="android.intent.action.VIEW" androidPackage="com.spotify.music" desktopApp="spotify:open" desktopInstall="https://spotify.com/download" icon="/Sources/images/SpotifyIcon.png" iosApp="spotify:open" itunesUrl="https://itunes.apple.com/ex/app/spotify/id324684580" name="contextMenuItem" text="Open Spotify app" />
    <action name="back" url="/Action?service=Spotify&amp;action=Previous" />
    <action name="skip" url="/Action?service=Spotify&amp;action=Next" />
    <action displayName="Add preset" name="cmItem" type="preset" url="/Action?service=Spotify&amp;action=addPreset" />
  </actions>
  <album>This Fire</album>
  <artist>Paula Cole</artist>
  <canMovePlayback>true</canMovePlayback>
  <canSeek>1</canSeek>
  <currentImage>https://i.scdn.co/image/ab67616d0000b273954491b164ae0c6a4795fcd9</currentImage>
  <cursor>0</cursor>
  <db>0</db>
  <image>https://i.scdn.co/image/ab67616d0000b273954491b164ae0c6a4795fcd9</image>
  <indexing>0</indexing>
  <inputId>Spotify</inputId>
  <mid>29</mid>
  <mode>1</mode>
  <mute>0</mute>
  <noCoverBackground>true</noCoverBackground>
  <pid>369</pid>
  <prid>0</prid>
  <repeat>2</repeat>
  <service>Spotify</service>
  <serviceIcon>/Sources/images/SpotifyIcon.png</serviceIcon>
  <serviceName>Spotify</serviceName>
  <shuffle>0</shuffle>
  <sid>6</sid>
  <sleep></sleep>
  <song>0</song>
  <state>stream</state>
  <stationImage>/Sources/images/SpotifyIcon.png</stationImage>
  <streamUrl>Spotify:spotify_pcm01:pcm/44100/16/2/0</streamUrl>
  <syncStat>45</syncStat>
  <title1>I Don't Want to Wait</title1>
  <title2>Paula Cole</title2>
  <title3>This Fire</title3>
  <totlen>320.027</totlen>
  <volume>100</volume>
  <secs>263</secs>
</status>
''';

final spotifyConnectExpected = BluOSAPITrack(
  queuePosition: '0',
  artist: 'Paula Cole',
  title: 'I Don\'t Want to Wait',
  album: 'This Fire',
  length: 320.027,
  imageUrl: 'https://i.scdn.co/image/ab67616d0000b273954491b164ae0c6a4795fcd9',
);
final spotifyConnectExpectedState = BluOSPlayerState('3fb2a68d257147306d6a7df8fa893455', 'stream', 263);

const tuneInXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<status etag="feefbdaceaaf816bd6dfed953705c210">
  <canMovePlayback>true</canMovePlayback>
  <canSeek>0</canSeek>
  <cursor>0</cursor>
  <db>0</db>
  <image>https://cdn-profiles.tunein.com/s51203/images/logoq.jpg?t=637078683440000000</image>
  <indexing>0</indexing>
  <mid>29</mid>
  <mode>1</mode>
  <mute>0</mute>
  <pid>366</pid>
  <preset_id>s51203</preset_id>
  <preset_name>88.5 | XPN2</preset_name>
  <prid>0</prid>
  <quality>128000</quality>
  <repeat>2</repeat>
  <schemaVersion>34</schemaVersion>
  <service>TuneIn</service>
  <serviceIcon>/Sources/images/TuneInIcon.png</serviceIcon>
  <serviceName>TuneIn</serviceName>
  <shuffle>0</shuffle>
  <sid>5</sid>
  <sleep></sleep>
  <song>0</song>
  <state>stream</state>
  <stationImage>https://cdn-profiles.tunein.com/s51203/images/logoq.jpg?t=637078683440000000</stationImage>
  <streamFormat>MP3 128 kb/s</streamFormat>
  <streamUrl>TuneIn:s51203/http://opml.radiotime.com/Tune.ashx?id=s51203&amp;formats=wma,mp3,aac,ogg,hls&amp;partnerId=8OeGua6y&amp;serial=B0:E4:D5:7D:C7:08</streamUrl>
  <syncStat>45</syncStat>
  <title1>XPoNential Radio</title1>
  <title2>James Blake - Retrograde</title2>
  <title3>XPN2 88.5</title3>
  <totlen>21600</totlen>
  <volume>100</volume>
  <secs>809</secs>
</status>
''';

final tuneInExpected = BluOSAPITrack(
  queuePosition: '0',
  artist: 'James Blake',
  title: 'Retrograde',
  length: 21600,
  imageUrl: 'https://cdn-profiles.tunein.com/s51203/images/logoq.jpg?t=637078683440000000',
);
final tuneInExpectedState = BluOSPlayerState('feefbdaceaaf816bd6dfed953705c210', 'stream', 809);

const qobuzXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<status etag="d05b7e614658609dacb2522988f50381">
  <album>Arvo Pärt: Passacaglia</album>
  <albumReplayGain>-3.86</albumReplayGain>
  <albumid>0822189027896</albumid>
  <artist>Arvo Pärt</artist>
  <artistid>543</artistid>
  <canMovePlayback>true</canMovePlayback>
  <canSeek>1</canSeek>
  <cursor>8</cursor>
  <db>0</db>
  <fn>Qobuz:26865565</fn>
  <image>/Artwork?service=Qobuz&amp;songid=Qobuz%3A26865565</image>
  <indexing>0</indexing>
  <mid>29</mid>
  <mode>1</mode>
  <mute>0</mute>
  <name>Credo</name>
  <pid>367</pid>
  <prid>0</prid>
  <quality>cd</quality>
  <repeat>2</repeat>
  <replayGain>-3.86</replayGain>
  <service>Qobuz</service>
  <serviceIcon>/Sources/images/QobuzIcon.png</serviceIcon>
  <serviceName>Qobuz</serviceName>
  <shuffle>0</shuffle>
  <sid>6</sid>
  <sleep></sleep>
  <song>0</song>
  <songid>Qobuz:26865565</songid>
  <state>play</state>
  <streamFormat>FLAC 44100/16/2</streamFormat>
  <syncStat>45</syncStat>
  <title1>Credo</title1>
  <title2>Arvo Pärt</title2>
  <title3>Arvo Pärt: Passacaglia</title3>
  <totlen>821</totlen>
  <volume>100</volume>
  <secs>30</secs>
</status>
''';

final qobuzExpected = BluOSAPITrack(
  queuePosition: '0',
  artist: 'Arvo Pärt',
  title: 'Credo',
  album: 'Arvo Pärt: Passacaglia',
  length: 821,
  imageUrl: '/Artwork?service=Qobuz&songid=Qobuz%3A26865565',
);
final qobuzExpectedState = BluOSPlayerState('d05b7e614658609dacb2522988f50381', 'play', 30);

const tidalConnectXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<status etag="613b75801562d1aa3d781e9b634c4e7c">
  <actions>
    <action name="back" url="/Action?service=TidalConnect&amp;action=Previous" />
    <action name="skip" url="/Action?service=TidalConnect&amp;action=Next" />
    <action androidAction="android.intent.action.VIEW" androidPackage="com.aspiro.tidal" desktopApp="tidal://" desktopInstall="https://tidal.com/download" icon="/Sources/images/TidalIcon.png" iosApp="tidal://" itunesUrl="https://apps.apple.com/us/app/tidal-music/id913943275" name="contextMenuItem" text="Open TIDAL Music app" />
  </actions>
  <album>Either/Or (Expanded Edition)</album>
  <artist>Elliott Smith</artist>
  <canMovePlayback>true</canMovePlayback>
  <canSeek>1</canSeek>
  <codecPrivateData></codecPrivateData>
  <currentImage>https://resources.tidal.com/images/ca0b0b28/1a3c/4c5e/b339/247101901f48/1280x1280.jpg</currentImage>
  <cursor>0</cursor>
  <db>0</db>
  <image>https://resources.tidal.com/images/ca0b0b28/1a3c/4c5e/b339/247101901f48/1280x1280.jpg</image>
  <indexing>0</indexing>
  <inputId>TidalConnect</inputId>
  <mid>29</mid>
  <mode>1</mode>
  <mute>0</mute>
  <pid>369</pid>
  <prid>0</prid>
  <quality>cd</quality>
  <repeat>2</repeat>
  <service>TidalConnect</service>
  <serviceIcon>/Sources/images/TidalIcon.png</serviceIcon>
  <serviceName>TIDAL connect</serviceName>
  <shuffle>0</shuffle>
  <sid>6</sid>
  <sleep></sleep>
  <song>0</song>
  <state>stream</state>
  <stationImage>/Sources/images/TidalIconNP_960.png</stationImage>
  <streamFormat>FLAC 44100/16/2</streamFormat>
  <streamUrl>TidalConnect:12:http://sp-pr-cf.audio.tidal.com/mediatracks/CAEaKRInNTM1YzhkZTYwMDU5MjRkNjllNWE5NjFjOTliMTFkMTBfNjEubXA0/0.flac?Expires=1653761848&amp;Signature=ko2KPomjL17xAv6ycRE6-VcNtKbESquaktlccQtbrySMDmxZrd8Cey80FxVFS8RE4Ko7ZKEQvJRDjvjJJheg9PTct7nLP6hWYiYxTAb~s2UmQFbl~vgSB3WQkk4VzkkimDUMh0Yps8qM3OwTS0h7qqbxOAirkEg-Tbqoz0GOwafEiHqnM2XV4F2nu5IQUFiQbArTPC9Sp0TfihlDZKD~gf7NHUaG7K7jYn-6MTBYjmGoBXRz5bAXERHOvaHKPIUzSNCcKksRtxDMLNQ98TkFf0CD~QT1ttJ8Fv46JImTyDORFnDpct5V3elJf07quV8rqaPPLIML1dt3LVij1gbK~Q__&amp;Key-Pair-Id=K14LZCZ9QUI4JL</streamUrl>
  <syncStat>45</syncStat>
  <title1>Between The Bars</title1>
  <title2>Elliott Smith</title2>
  <title3>Either/Or (Expanded Edition)</title3>
  <totlen>141</totlen>
  <volume>100</volume>
  <secs>10</secs>
</status>
''';

final tidalConnectExpected = BluOSAPITrack(
  queuePosition: '0',
  artist: 'Elliott Smith',
  title: 'Between The Bars',
  album: 'Either/Or (Expanded Edition)',
  length: 141,
  imageUrl: 'https://resources.tidal.com/images/ca0b0b28/1a3c/4c5e/b339/247101901f48/1280x1280.jpg',
);
final tidalConnectExpectedState = BluOSPlayerState('613b75801562d1aa3d781e9b634c4e7c', 'stream', 10);

const localXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<status etag="3d71fa03d9ad59f244fddfbfd737c3cb">
  <album>Us</album>
  <artist>Peter Gabriel</artist>
  <autofill>1</autofill>
  <canMovePlayback>true</canMovePlayback>
  <canSeek>1</canSeek>
  <cursor>9</cursor>
  <db>0</db>
  <fn>/var/mnt/Peter Gabriel/US-reissue-WAV/01_Come Talk To Me.flac</fn>
  <image>/Artwork?service=LocalMusic&amp;fn=%2Fvar%2Fmnt%2FPeter%20Gabriel%2FUS-reissue-WAV%2F01_Come%20Talk%20To%20Me.flac</image>
  <indexing>0</indexing>
  <mid>29</mid>
  <mode>1</mode>
  <mute>0</mute>
  <name>Come Talk to Me</name>
  <pid>370</pid>
  <prid>0</prid>
  <quality>hd</quality>
  <repeat>2</repeat>
  <service>LocalMusic</service>
  <serviceIcon>/images/LibraryIcon.png</serviceIcon>
  <serviceName>Library</serviceName>
  <shuffle>0</shuffle>
  <sid>6</sid>
  <sleep></sleep>
  <song>0</song>
  <state>play</state>
  <syncStat>45</syncStat>
  <title1>Come Talk to Me</title1>
  <title2>Peter Gabriel</title2>
  <title3>Us</title3>
  <totlen>426</totlen>
  <volume>100</volume>
  <secs>22</secs>
</status>
''';

final localExpected = BluOSAPITrack(
  queuePosition: '0',
  artist: 'Peter Gabriel',
  title: 'Come Talk to Me',
  album: 'Us',
  length: 426,
  imageUrl:
      '/Artwork?service=LocalMusic&fn=%2Fvar%2Fmnt%2FPeter%20Gabriel%2FUS-reissue-WAV%2F01_Come%20Talk%20To%20Me.flac',
);
final localExpectedState = BluOSPlayerState('3d71fa03d9ad59f244fddfbfd737c3cb', 'play', 22);

const stoppedXml = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<status etag="19422d7bd3e7eed342f30484de66502f">
  <canMovePlayback>true</canMovePlayback>
  <cursor>0</cursor>
  <db>0</db>
  <indexing>0</indexing>
  <mid>29</mid>
  <mode>1</mode>
  <mute>0</mute>
  <pid>371</pid>
  <prid>0</prid>
  <repeat>2</repeat>
  <shuffle>0</shuffle>
  <sid>6</sid>
  <sleep></sleep>
  <song>0</song>
  <state>stop</state>
  <syncStat>45</syncStat>
  <volume>100</volume>
  <secs>0</secs>
</status>
''';
