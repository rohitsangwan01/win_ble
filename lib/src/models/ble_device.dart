import 'dart:convert';

BleDevice bleDeviceFromJson(String str) => BleDevice.fromJson(json.decode(str));

String bleDeviceToJson(BleDevice data) => json.encode(data.toJson());

class BleDevice {
  BleDevice(
      {required this.address,
      required this.rssi,
      required this.timestamp,
      required this.advType,
      required this.name,
      required this.serviceUuids,
      this.adStructures,
      this.manufacturerData});

  String address;
  String name;
  String rssi;
  String timestamp;
  String advType;
  List<int>? manufacturerData;
  List<dynamic> serviceUuids;
  List<AdStructure>? adStructures;

  factory BleDevice.fromJson(Map<String, dynamic> json) => BleDevice(
        address: json["bluetoothAddress"] ?? "",
        rssi: json["rssi"]?.toString() ?? "",
        timestamp: json["timestamp"]?.toString() ?? "",
        advType: json["advType"] ?? "",
        name: json["localName"] ?? "N/A",
        serviceUuids: json["serviceUuids"],
        adStructures: json["adStructures"] == null
            ? null
            : List<AdStructure>.from(json["adStructures"].map((x) =>
                AdStructure(type: x["type"], data: List<int>.from(x["data"])))),
      );

  Map<String, dynamic> toJson() => {
        "bluetoothAddress": address,
        "rssi": rssi,
        "timestamp": timestamp,
        "advType": advType,
        "localName": name,
        "serviceUuids": serviceUuids.toString(),
        "manufacturerData": manufacturerData,
      };
}

class AdStructure {
  int type;
  List<int> data;
  AdStructure({required this.type, required this.data});
}
