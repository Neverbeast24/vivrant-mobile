import 'package:http_parser/http_parser.dart';

MediaType imageMediaType(String filename) {
  final ext = filename.split('.').last.toLowerCase();
  switch (ext) {
    case 'png':
      return MediaType('image', 'png');
    case 'webp':
      return MediaType('image', 'webp');
    case 'gif':
      return MediaType('image', 'gif');
    default:
      return MediaType('image', 'jpeg');
  }
}
