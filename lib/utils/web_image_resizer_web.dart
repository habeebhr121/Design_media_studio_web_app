// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<String> resizeImageToThumbnail(Uint8List bytes, {int maxDimension = 280}) async {
  try {
    final blob = html.Blob([bytes]);
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);
    final img = html.ImageElement();
    img.src = blobUrl;

    final completer = Completer<String>();
    img.onLoad.listen((_) {
      try {
        int width = img.naturalWidth;
        int height = img.naturalHeight;
        if (width <= 0) width = img.width ?? maxDimension;
        if (height <= 0) height = img.height ?? maxDimension;

        if (width > maxDimension || height > maxDimension) {
          if (width > height) {
            height = (height * maxDimension / width).round();
            width = maxDimension;
          } else {
            width = (width * maxDimension / height).round();
            height = maxDimension;
          }
        }

        final canvas = html.CanvasElement(width: width, height: height);
        final ctx = canvas.context2D;
        ctx.drawImageScaled(img, 0, 0, width, height);
        final dataUrl = canvas.toDataUrl('image/jpeg', 0.75);
        html.Url.revokeObjectUrl(blobUrl);
        completer.complete(dataUrl);
      } catch (_) {
        html.Url.revokeObjectUrl(blobUrl);
        completer.complete('');
      }
    });

    img.onError.listen((_) {
      html.Url.revokeObjectUrl(blobUrl);
      completer.complete('');
    });

    return await completer.future;
  } catch (_) {
    return '';
  }
}
