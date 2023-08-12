// ignore_for_file: avoid_print, prefer_final_fields, constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:win_ble/src/utils/helper.dart';

import 'models/ble_characteristic.dart';
import 'models/ble_device.dart';

class WinBle {
  /// [Private Variables]
  static Map _deviceMap = {};
  static int _requestId = 0;
  static Map<String, Map<String, String>> _subscriptions = {};
  static bool _showLog = false;
  static late Process _bleServer;
  static String _previousBleState = "";

  /// [Stream Controllers]
  static StreamController<BleDevice> _scanStreamController =
      StreamController.broadcast();
  static StreamController<Map<String, dynamic>> _responseStreamController =
      StreamController.broadcast();
  static StreamController<Map<String, dynamic>> _connectionStreamController =
      StreamController.broadcast();
  static StreamController _characteristicValueStreamController =
      StreamController.broadcast();
  static StreamController<BleState> _bleStateStreamController =
      StreamController.broadcast();

  /// [Stream Subscriptions]
  static StreamSubscription? _stdoutSubscription;
  static StreamSubscription? _stderrSubscription;

  /// enableLog in [initialize] method
  static void _printLog(log) {
    if (_showLog) {
      print(log);
    }
  }

  /// [initialize] WinBle with
  /// [showLog] : if true, print logs to console
  /// call [dispose] when Done

  static initialize({bool enableLog = false}) async {
    try {
      _showLog = enableLog;
      String bleServerExe = "packages/win_ble/assets/BLEServer.exe";
      File bleFile = await getFilePath(bleServerExe);
      _bleServer = await Process.start(bleFile.path, []);

      _stdoutSubscription = _bleServer.stdout.listen((event) {
        var listData = dataParser(event);
        for (var data in listData) {
          _printLog(data);
          _processMessage(data);
        }
      });

      _stderrSubscription = _bleServer.stderr.listen((event) {
        throw String.fromCharCodes(event);
      });
    } catch (e) {
      dispose();
      throw e.toString();
    }
  }

  /// call [dispose] method to close all resources
  static void dispose() {
    //Close Controllers
    _scanStreamController.close();
    _responseStreamController.close();
    _connectionStreamController.close();
    _characteristicValueStreamController.close();
    // cancel Streams
    _stderrSubscription?.cancel();
    _stdoutSubscription?.cancel();
    // kill process
    _bleServer.kill();
  }

  static _processMessage(message) {
    switch (message["_type"]) {
      case "Start":
        break;
      case "scanResult":
        BleDevice device = BleDevice.fromJson(message);
        _scanStreamController.add(device);
        break;
      case "ble_state":
        String state = message["state"];
        if (state == _previousBleState) return;
        _previousBleState = state;
        _bleStateStreamController.add(bleStateFromResponse(state));
        break;
      case "response":
        _responseStreamController.add({
          "id": message["_id"],
          "result": message["result"],
          "error": message["error"]
        });
        break;
      case "disconnectEvent":
        String device = message["device"];
        _connectionStreamController.add({
          "device": _getAddressFromDevice(device) ?? device,
          "connected": false,
        });
        break;
      case "valueChangedNotification":
        String subscriptionKey = message["subscriptionId"]?.toString() ?? "";
        Map<String, String>? data =
            _getDataFromSubscriptionKey(subscriptionKey);
        if (data != null) {
          var value = message["value"];
          var result = {};
          result.addAll(data);
          result.addAll({"value": value});
          _characteristicValueStreamController.add(result);
        } else {
          _printLog(
              "Received Unknown Data from SubscriptionKey : $subscriptionKey");
        }

        break;
    }
  }

  /// To [Start Scanning ]
  static void startScanning() {
    _sendMessage({"cmd": "scan"});
  }

  /// To [Stop Scanning]
  static void stopScanning() {
    _sendMessage({"cmd": "stopScan"});
  }

  /// [connect] will update a Stream of boolean [getConnectionStream]
  /// true if connected
  /// false if disconnected

  static Future<void> connect(String address) async {
    try {
      var result = await _sendRequest(
          {"cmd": "connect", "address": address.replaceAll(":", "")});
      _deviceMap[address] = result;
      // we have to perform an operation on device in order to make a connection
      var services = await discoverServices(address);
      bool connectionFailed = services == null || services.isEmpty;
      _connectionStreamController.add({
        "device": address,
        "connected": !connectionFailed,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// [canPair] will return a boolean
  static Future<bool> canPair(String address) async {
    try {
      var result = await _sendRequest(
          {"cmd": "canPair", "device": _getDeviceFromAddress(address)});
      return result != null && result;
    } catch (e) {
      rethrow;
    }
  }

  /// [isPaired] will return a boolean
  static Future<bool> isPaired(String address) async {
    try {
      var result = await _sendRequest(
          {"cmd": "isPaired", "device": _getDeviceFromAddress(address)});
      return result != null && result;
    } catch (e) {
      rethrow;
    }
  }

  /// [pair] will send a pairing command
  /// it will be completed on Successful Pairing
  /// or it will throw Error on Unsuccessful Pairing
  static Future<void> pair(String address) async {
    try {
      var result = await _sendRequest(
          {"cmd": "pair", "device": _getDeviceFromAddress(address)});
      if (result == null || result != "Paired") {
        throw result;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// [unPair] will try to Un-pair
  static Future<void> unPair(String address) async {
    try {
      var result = await _sendRequest(
          {"cmd": "unPair", "device": _getDeviceFromAddress(address)});
      if (result == null || result != "Unpaired") {
        throw result;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// [disconnect] will update a Stream of boolean [getConnectionStream]
  /// and also ignore if that device is already disconnected
  static Future<void> disconnect(address) async {
    // this will get a Void Callback
    try {
      await _sendRequest(
          {"cmd": "disconnect", "device": _getDeviceFromAddress(address)});
      _connectionStreamController.add({
        "device": address,
        "connected": false,
      });
      _deviceMap[address] = null;
    } catch (e) {
      if (e.toString().contains("not found")) {
        // ignore for now
      } else {
        rethrow;
      }
    }
  }

  /// [discoverServices] will return a list of services List
  static Future<List<String>> discoverServices(address) async {
    List? services = await _sendRequest(
        {"cmd": "services", "device": _getDeviceFromAddress(address)});
    return services?.map((e) => fromWindowsUuid(e)).toList() ?? [];
  }

  /// [discoverCharacteristics] will return a list of [BleCharacteristic]
  static Future<List<BleCharacteristic>> discoverCharacteristics(
      {required String address, required String serviceId}) async {
    var data = await _sendRequest({
      "cmd": "characteristics",
      "device": _getDeviceFromAddress(address),
      "service": toWindowsUuid(serviceId),
    });
    return List<BleCharacteristic>.from(
        data.map((e) => BleCharacteristic.fromJson(e)));
  }

  /// [read] will read characteristic value and returns a List<int>
  static Future<List<int>> read(
      {required String address,
      required String serviceId,
      required String characteristicId}) async {
    var data = await _sendRequest({
      "cmd": "read",
      "device": _getDeviceFromAddress(address),
      "service": toWindowsUuid(serviceId),
      "characteristic": toWindowsUuid(characteristicId),
    });
    return List<int>.from(data);
  }

  /// [write] will write characteristic value and returns error if something is wrong
  /// wrap in try catch to capture error
  static Future<void> write(
      {required String address,
      required String service,
      required String characteristic,
      required Uint8List data,
      required bool writeWithResponse}) async {
    await _sendRequest({
      "cmd": "write",
      "device": _getDeviceFromAddress(address),
      "service": toWindowsUuid(service),
      "characteristic": toWindowsUuid(characteristic),
      "value": data,
      "writeWithResponse": writeWithResponse
    });
  }

  /// [subscribeToCharacteristic] will subscribe to characteristic and
  /// we can get update on [connectionStream]
  /// call [connectionStreamOf] to get value of specific characteristic
  static Future<void> subscribeToCharacteristic(
      {required String address,
      required String serviceId,
      required String characteristicId}) async {
    await _sendRequest({
      "cmd": "subscribe",
      "device": _getDeviceFromAddress(address),
      "service": toWindowsUuid(serviceId),
      "characteristic": toWindowsUuid(characteristicId),
    }).then((result) {
      _subscriptions[result.toString()] = {
        "address": address,
        "serviceId": serviceId,
        "characteristicId": characteristicId
      };
    });
  }

  /// [unsubscribeFromCharacteristic] will unsubscribe from characteristic , throws error if this characteristic is not subscribed
  static Future<void> unSubscribeFromCharacteristic(
      {required String address,
      required String serviceId,
      required String characteristicId}) async {
    await _sendRequest({
      "cmd": "unsubscribe",
      "device": _getDeviceFromAddress(address),
      "service": toWindowsUuid(serviceId),
      "characteristic": toWindowsUuid(characteristicId),
    }).then((result) {
      _subscriptions.remove(result.toString());
    });
  }

  /// All Streams
  /// we can get [connectionStream] to get update on connection
  static Stream<Map<String, dynamic>> get connectionStream =>
      _connectionStreamController.stream;
  static Stream<BleDevice> get scanStream => _scanStreamController.stream;

  /// [bleState] is a stream to get current Ble Status
  static Stream<BleState> get bleState => _bleStateStreamController.stream;

  /// to get [connection update] for a specific device
  static Stream<bool> connectionStreamOf(String address) =>
      _connectionStreamController.stream
          .where((event) => event["device"] == address)
          .map((event) => event["connected"]);

  /// to get update of [all characteristic] data
  static Stream get characteristicValueStream =>
      _characteristicValueStreamController.stream;

  /// to get update of a [specific characteristic]
  static Stream characteristicValueStreamOf(
          {required String address,
          required String serviceId,
          required String characteristicId}) =>
      _characteristicValueStreamController.stream
          .where((event) =>
              event["address"] == address &&
              event["serviceId"] == serviceId &&
              event["characteristicId"] == characteristicId)
          .map((event) => event["value"]);

  // Helper Methods
  static Map<String, String>? _getDataFromSubscriptionKey(subscriptionKey) {
    try {
      Map<String, String> data = {};
      if (_subscriptions.isEmpty) return null;
      _subscriptions.forEach((key, value) {
        if (key == subscriptionKey) {
          data = value;
        }
      });
      return data.isEmpty ? null : data;
    } catch (e) {
      _printLog("Error in _getSubscriptionKey :  $e");
      return null;
    }
  }

  static String _getDeviceFromAddress(String address) {
    if (_deviceMap[address] == null) {
      throw "Device not found !";
    } else {
      return _deviceMap[address];
    }
  }

  static String? _getAddressFromDevice(String device) {
    String? address;
    _deviceMap.forEach((key, value) {
      if (value == device) {
        address = key;
      }
    });
    return address;
  }

  static _sendRequest(message) async {
    var result = {};
    int uniqID = _requestId++;
    result.addAll(message);
    result.addAll({"_id": uniqID});
    _sendMessage(result);
    var data = await _responseStreamController.stream
        .firstWhere((element) => element["id"] == uniqID);
    if (data["error"] != null) {
      throw data["error"];
    }
    return data['result'];
  }

  static void _sendMessage(message) {
    String data = json.encode(message);
    List<int> dataBufInt = utf8.encode(data);
    List<int> lenBufInt = createUInt32LE(dataBufInt.length);
    _bleServer.stdin.add(lenBufInt);
    _bleServer.stdin.add(dataBufInt);
  }
}

/// [BleState] is an Enum to represent current state of BLE
enum BleState { On, Off, Unknown, Disabled, Unsupported }
