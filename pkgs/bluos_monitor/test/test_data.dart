import 'package:scrobbler_bluos_monitor/src/playlist.dart';

const testStatuses = [track1Status, track2Status, track3Status];

const track3Status = '''
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
	<secs>164</secs>
</status>
''';

final track3Expected = BluOSAPITrack(
  playId: '271',
  artist: 'Elbow',
  title: 'Mercy Street',
  album: 'And I\'ll Scratch Yours',
  length: 339,
  timestamp: 0,
  imageUrl: '/Artwork?service=Tidal&amp;songid=Tidal%3A122121655',
  state: BluOSTrackState('68330da5672aff2cf86a349955ced764', 'play', 164),
);

const track2Status = '''
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
	<secs>100</secs>
</status>
''';

final track2Expected = BluOSAPITrack(
  playId: '270',
  artist: 'José González',
  title: 'Stay Alive',
  album: 'The Secret Life Of Walter Mitty (Soundtrack)',
  length: null,
  timestamp: 0,
  imageUrl: 'https://img.radioparadise.com/covers/l/B00GG429KS.jpg',
  state: BluOSTrackState('4a946635b01af97de8ffa7129b0ad5ab', 'stream', 100),
);

const track1Status = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<status etag="aa51e35b9fe43f3b47bcccc676f16457">
	<actions>
		<action name="back"/>
		<action name="skip" url="/Action?service=RadioParadise&amp;next=2282805"/>
		<action icon="/images/loveban/love.png" name="love" state="-1" text="Love" type="thumbs" url="/Action?service=RadioParadise&amp;love=34211&amp;reset=0"/>
		<action icon="/images/loveban/ban.png" name="ban" state="-1" text="Ban" type="thumbs" url="/Action?service=RadioParadise&amp;ban=34211&amp;reset=0"/>
		<action name="shop" url="/Action?service=RadioParadise&amp;getBuyUrl=https%3A%2F%2Fassoc-redirect.amazon.com%2Fg%2Fr%2Fhttps%3A%2F%2Fwww.amazon.com%2Fdp%2FB000V6MT0C%3Ftag%3Dradioparadise-20"/>
	</actions>
	<album>Des Visages des Figures</album>
	<artist>Noir Désir</artist>
	<canMovePlayback>true</canMovePlayback>
	<canSeek>0</canSeek>
	<currentImage>https://img.radioparadise.com/covers/l/B00005NVAP.jpg</currentImage>
	<cursor>184</cursor>
	<db>0</db>
	<image>https://img.radioparadise.com/covers/l/B00005NVAP.jpg</image>
	<indexing>0</indexing>
	<inputId>RadioParadise</inputId>
	<lyricsid>34211</lyricsid>
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
	<title2>L' Enfant Roi</title2>
	<title3>Noir Désir • Des Visages des Figures</title3>
	<volume>100</volume>
	<secs>1038</secs>
</status>
''';

final track1Expected = BluOSAPITrack(
  playId: '270',
  artist: 'Noir Désir',
  title: 'L\' Enfant Roi',
  album: 'Des Visages des Figures',
  length: null,
  timestamp: 0,
  imageUrl: 'https://img.radioparadise.com/covers/l/B00005NVAP.jpg',
  state: BluOSTrackState('aa51e35b9fe43f3b47bcccc676f16457', 'stream', 1038),
);
