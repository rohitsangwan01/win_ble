import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flutter/services.dart';

class WinServer {
  /// Get path of BleServer from library assets,
  ///  use this class in Flutter projects only, this class is not supported in pure Dart projects.
  static Future<String> get path async {
    String bleServerExe = "packages/win_ble/assets/BLEServer.exe";
    File file = await _getFilePath(bleServerExe);
    return file.path;
  }

  static Future<File> _getFilePath(String path) async {
    final byteData = await rootBundle.load(path);
    final buffer = byteData.buffer;
    String? tempPath = await _getTemporaryPath();
    if (tempPath == null) throw Exception("Could not get temporary path");
    var filePath = tempPath + '/file_01.tmp';
    return File(filePath).writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  }

  static Future<String?> _getTemporaryPath() async {
    final Pointer<Utf16> buffer = calloc<Uint16>(MAX_PATH + 1).cast<Utf16>();
    String path;
    try {
      final int length = GetTempPath(MAX_PATH, buffer);
      if (length == 0) {
        final int error = GetLastError();
        throw WindowsException(error);
      } else {
        path = buffer.toDartString();
        if (path.endsWith(r'\')) path = path.substring(0, path.length - 1);
      }
      final Directory directory = Directory(path);
      if (!directory.existsSync()) await directory.create(recursive: true);
      return path;
    } finally {
      calloc.free(buffer);
    }
  }
}
