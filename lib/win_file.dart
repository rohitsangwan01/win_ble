import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flutter/services.dart';

class WinServer {
  /// Get path of BleServer from library assets,
  ///  use this class in Flutter projects only, this class is not supported in pure Dart projects.
  /// use [fileName] to avoid conflicts of using same file in different projects
  static Future<String> path({String? fileName}) async {
    String bleServerExe = "packages/win_ble/assets/BLEServer.exe";
    File file = await _getFilePath(bleServerExe, fileName);
    return file.path;
  }

  static Future<File> _getFilePath(String path, String? fileName) async {
    final byteData = await rootBundle.load(path);
    final buffer = byteData.buffer;
    String? tempPath = await _getTemporaryPath();
    if (tempPath == null) throw Exception("Could not get temporary path");
    var initPath = '$tempPath/${fileName ?? 'win_ble_server'}.exe';
    var filePath = initPath;

    //Prevent multiple applications and file being occupied, max 10
    for (int i = 1; i < 10; i++) {
      var file = File(filePath);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (e) {
          filePath = "$initPath$i";
          continue;
        }
        break;
      } else {
        break;
      }
    }

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
