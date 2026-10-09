import 'dart:convert';
import 'dart:typed_data';

Future<String> resizeImageToThumbnail(Uint8List bytes, {int maxDimension = 280}) async {
  if (bytes.length <= 400 * 1024) {
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }
  return '';
}
