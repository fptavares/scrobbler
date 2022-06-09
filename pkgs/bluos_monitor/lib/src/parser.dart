import 'package:xml/xml.dart';

class BluOSStatusParser {
  final XmlElement status;

  BluOSStatusParser(this.status);

  factory BluOSStatusParser.fromDocument(XmlDocument document) {
    final status = document.getElement('status');
    if (status == null) {
      // throw if <status/> is not there
      throw MissingMandatoryAttributeException('<status/>');
    }
    return BluOSStatusParser(status);
  }

  String getMandatory(AttributeConfig attribute) {
    final value = getOptional(attribute);
    if (value == null) {
      throw MissingMandatoryAttributeException(attribute.key);
    }
    return value;
  }

  String? getOptional(AttributeConfig attribute) {
    String? value = status.getElement(attribute.key)?.text.trim();
    if (value == null && attribute.alternativeKey != null) {
      value = status.getElement(attribute.alternativeKey!)?.text.trim();
    }
    if (attribute.regex != null && value != null) {
      value = attribute.regex!.firstMatch(value)?.group(1);
    }
    return value;
  }

  double? getDoubleOptional(AttributeConfig attribute) {
    return double.tryParse(getOptional(attribute) ?? '');
  }

  String? getEtag() {
    return status.getAttribute('etag');
  }
}

class AttributeConfig {
  final String key;
  final RegExp? regex;
  final String? alternativeKey;

  const AttributeConfig(this.key, {this.regex, this.alternativeKey});

  static const serviceConfig = AttributeConfig('service');
  static const stateConfig = AttributeConfig('state');
  static const secondsConfig = AttributeConfig('secs');
}

class ServiceConfig {
  final AttributeConfig queueId;
  final AttributeConfig queuePosition;
  final AttributeConfig artist;
  final AttributeConfig album;
  final AttributeConfig title;
  final AttributeConfig length;
  final AttributeConfig image;

  const ServiceConfig({
    this.queueId = const AttributeConfig('pid'),
    this.queuePosition = const AttributeConfig('song'),
    this.artist = const AttributeConfig('artist'),
    this.album = const AttributeConfig('album'),
    this.title = const AttributeConfig('name'),
    this.length = const AttributeConfig('totlen'),
    this.image = const AttributeConfig('image'),
  });

  static const defaultConfig = ServiceConfig();
  static final Map<String, ServiceConfig> serviceConfigs = {
    'LocalMusic': defaultConfig,
    'Qobuz': defaultConfig,
    'Tidal': const ServiceConfig(
      title: AttributeConfig('name', alternativeKey: 'title2'), // title2 used on radio instead of name
    ),
    'TidalConnect': const ServiceConfig(title: AttributeConfig('title1')),
    'Spotify': const ServiceConfig(title: AttributeConfig('title1')),
    'RadioParadise': const ServiceConfig(
      title: AttributeConfig('title2'),
    ),
    'TuneIn': ServiceConfig(
      artist: AttributeConfig('title2', regex: RegExp(r'^([^\-]*[^\-\s]+)\s+\-\s+.+$')),
      title: AttributeConfig('title2', regex: RegExp(r'^[^\-]*[^\-\s]+\s+\-\s+(.+)$')),
    ),
  };

  static ServiceConfig configFor(String? service) {
    return serviceConfigs[service] ?? defaultConfig;
  }
}

class MissingMandatoryAttributeException implements Exception {
  final String missingAttribute;

  MissingMandatoryAttributeException(this.missingAttribute);
}
