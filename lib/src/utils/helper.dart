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

int fromBytesToInt32(int b3, int b2, int b1, int b0) {
  final int8List = new Int8List(4)
    ..[3] = b3
    ..[2] = b2
    ..[1] = b1
    ..[0] = b0;
  return int8List.buffer.asByteData().getInt32(0);
}

List<dynamic> dataParser(event) {
  var data = String.fromCharCodes(event);
  List<dynamic> list = [];
  var cursor = 0;
  while (cursor < data.length) {
    var length = fromBytesToInt32(
      event[cursor + 0],
      event[cursor + 1],
      event[cursor + 2],
      event[cursor + 3]
    );
    cursor += 4;

    String payload = data.substring(cursor, cursor + length);
    cursor += length;
    
    var jsonData = json.decode(payload);
    list.add(jsonData);
  }
  if (cursor != data.length) {
    return [];
  }

  return list;
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
