import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:win_ble/src/win_ble.dart';

List<int> createUInt32LE(
  int value,
) {
  final result = Uint8List(4);
  for (int i = 0; i < 4; i++, value >>= 8) {
    result[i] = value & 0xFF;
  }
  return result;
}

dataParser(event) {
  try {
    var data = String.fromCharCodes(event);
    String finalData =
        data.substring(data.indexOf("{"), data.lastIndexOf("}") + 1);
    var jsonData = json.decode(finalData);
    return jsonData;
  } catch (e) {
    return null;
  }
}

Future<File> getFilePath(String path) async {
  final byteData = await rootBundle.load(path);
  final buffer = byteData.buffer;
  Directory tempDir = await getTemporaryDirectory();
  String tempPath = tempDir.path;
  var filePath = tempPath + '/file_01.tmp';
  return File(filePath).writeAsBytes(
      buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
}

String toWindowsUuid(String uuid) {
  return "{$uuid}";
}

String fromWindowsUuid(String uuid) {
  var p0 = uuid.replaceAll("{", "");
  return p0.replaceAll("}", "");
}

BleState bleStateFromResponse(String state) {
  switch (state.toLowerCase()) {
    case "on":
      return BleState.On;
    case "off":
      return BleState.Off;
    case "disabled":
      return BleState.Disabled;
    case "unsupported":
      return BleState.Unsupported;
    default:
      return BleState.Unknown;
  }
}
