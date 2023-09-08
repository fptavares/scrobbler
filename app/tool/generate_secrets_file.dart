import 'dart:io';

void main() {
  final config = {
    'lastfmApiKey': Platform.environment['LASTFM_APIKEY'] ?? '',
    'lastfmSharedSecret': Platform.environment['LASTFM_SECRET'] ?? '',
    'discogsConsumerKey': Platform.environment['DISCOGS_APIKEY'] ?? '',
    'discogsConsumerSecret': Platform.environment['DISCOGS_SECRET'] ?? '',
  };

  final secretsFile = File('lib/secrets.dart');

  if (secretsFile.existsSync()) {
    // ignore: avoid_print
    print('The secrets file already exists at: ${secretsFile.path}');
    exit(1);
  }

  secretsFile.writeAsStringSync(
      config.entries.map((e) => "const ${e.key} = '${e.value.replaceAll('\'', '\\\'')}';").join('\n'));
}
