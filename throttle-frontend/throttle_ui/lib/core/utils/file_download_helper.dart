import 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart' as platform;
import 'dart:typed_data';

void downloadBytes(Uint8List bytes, String fileName) {
  platform.downloadBytesWeb(bytes, fileName);
}
