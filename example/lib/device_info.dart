// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:win_ble/win_ble.dart';

class DeviceInfo extends StatefulWidget {
  final BleDevice device;
  const DeviceInfo({Key? key, required this.device}) : super(key: key);

  @override
  State<DeviceInfo> createState() => _DeviceInfoState();
}

class _DeviceInfoState extends State<DeviceInfo> {
  late BleDevice device;

  TextEditingController serviceTxt = TextEditingController();
  TextEditingController characteristicTxt = TextEditingController();
  TextEditingController uint8DataTxt = TextEditingController();
  bool connected = false;
  List<String> services = [];
  List<BleCharacteristic> characteristics = [];
  String result = "";
  String error = "none";

  connect(String address) async {
    await WinBle.connect(address);
  }

  pair(String address) async {
    try {
      await WinBle.pair(address);
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  unPair(String address) async {
    try {
      await WinBle.unPair(address);
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  disconnect(address) {
    WinBle.disconnect(address);
  }

  discoverServices(address) async {
    try {
      var data = await WinBle.discoverServices(address);
      print(data);
      setState(() {
        services = data;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  discoverCharacteristic(address, serviceID) async {
    try {
      List<BleCharacteristic> bleChar = await WinBle.discoverCharacteristics(
          address: address, serviceId: serviceID);
      print(bleChar.map((e) => e.toJson()));
      setState(() {
        characteristics = bleChar;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  readCharacteristic(address, serviceID, charID) async {
    try {
      List<int> data = await WinBle.read(
          address: address, serviceId: serviceID, characteristicId: charID);
      print(String.fromCharCodes(data));
      setState(() {
        result =
            "Read => List<int> : $data    ,    ToString :  ${String.fromCharCodes(data)}   , Time : ${DateTime.now()}";
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  writeCharacteristic(String address, String serviceID, String charID,
      Uint8List data, bool writeWithResponse) async {
    try {
      await WinBle.write(
          address: address,
          service: serviceID,
          characteristic: charID,
          data: data,
          writeWithResponse: writeWithResponse);
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  subsCribeToCharacteristic(address, serviceID, charID) async {
    try {
      await WinBle.subscribeToCharacteristic(
          address: address, serviceId: serviceID, characteristicId: charID);
    } catch (e) {
      setState(() {
        error = e.toString() + " Date ${DateTime.now()}";
      });
    }
  }

  unSubscribeToCharacteristic(address, serviceID, charID) async {
    try {
      await WinBle.unSubscribeFromCharacteristic(
          address: address, serviceId: serviceID, characteristicId: charID);
    } catch (e) {
      setState(() {
        error = e.toString() + " Date ${DateTime.now()}";
      });
    }
  }

  StreamSubscription? _connectionStream;
  StreamSubscription? _characteristicValueStream;

  @override
  void initState() {
    device = widget.device;
    // subscribe to connection events
    _connectionStream =
        WinBle.connectionStreamOf(device.address).listen((event) {
      setState(() {
        connected = event;
      });
    });

    _characteristicValueStream =
        WinBle.characteristicValueStream.listen((event) {
      print("CharValue : $event");
    });
    super.initState();
  }

  @override
  void dispose() {
    _connectionStream?.cancel();
    _characteristicValueStream?.cancel();
    disconnect(device.address);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        centerTitle: true,
        actions: [
          Row(
            children: [
              Text(connected ? "Connected" : "Disconnected"),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.circle,
                  color: connected ? Colors.green : Colors.red,
                ),
              )
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Buttons
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                kButton("Connect", () {
                  connect(device.address);
                }),
                kButton("Pair", () {
                  pair(device.address);
                }),
                kButton("UnPair", () {
                  unPair(device.address);
                }),
                kButton("Discover Services", () {
                  discoverServices(device.address);
                }),
                kButton("Disconnect", () {
                  disconnect(device.address);
                }),
              ],
            ),
            // Service List
            kHeadingText("Services List"),
            ListView.builder(
              itemCount: services.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                return InkWell(
                  onTap: () {
                    serviceTxt.text = services[index];
                    discoverCharacteristic(device.address, services[index]);
                  },
                  child: Card(
                    child: ListTile(
                      title: Text(services[index]),
                    ),
                  ),
                );
              },
            ),

            kHeadingText("Characteristics List"),
            ListView.builder(
              itemCount: characteristics.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                BleCharacteristic characteristic = characteristics[index];
                return InkWell(
                  onTap: () {
                    characteristicTxt.text = characteristics[index].uuid;
                  },
                  child: Card(
                    child: ListTile(
                      title: Text(characteristic.uuid),
                      subtitle: Text(
                          "Properties : ${characteristic.properties.toJson()}"),
                    ),
                  ),
                );
              },
            ),

            kTextForm(
              "Enter Characteristic",
              characteristicTxt,
            ),

            kTextForm(
              "Enter List<int> Data",
              uint8DataTxt,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                kButton("Read Characteristics", () {
                  readCharacteristic(
                      device.address, serviceTxt.text, characteristicTxt.text);
                }),
                kButton("Write Characteristics", () {
                  if (uint8DataTxt.text == "") {
                    setState(() {
                      error = "Please Enter Data , Time : ${DateTime.now()}";
                    });
                    return;
                  }
                  Uint8List data = Uint8List.fromList(uint8DataTxt.text
                      .replaceAll("[", "")
                      .replaceAll("]", "")
                      .split(",")
                      .map((e) => int.parse(e.trim()))
                      .toList());
                  writeCharacteristic(device.address, serviceTxt.text,
                      characteristicTxt.text, data, true);
                }),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                kButton("Subscribe Characteristics", () {
                  subsCribeToCharacteristic(
                      device.address, serviceTxt.text, characteristicTxt.text);
                }),
                kButton("UnSubscribe Characteristics", () {
                  unSubscribeToCharacteristic(
                      device.address, serviceTxt.text, characteristicTxt.text);
                }),
              ],
            ),

            const SizedBox(height: 10),

            kHeadingText(result, shiftLeft: true),

            const SizedBox(height: 10),
            kHeadingText("Error : " + error, shiftLeft: true),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  kTextForm(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: hint,
        ),
      ),
    );
  }

  kButton(String txt, onTap) {
    return ElevatedButton(
      onPressed: onTap,
      child: Text(
        txt,
        style: const TextStyle(fontSize: 20),
      ),
    );
  }

  kHeadingText(String title, {bool shiftLeft = false}) {
    return Column(
      crossAxisAlignment:
          shiftLeft ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Text(title),
        ),
        const Divider(),
      ],
    );
  }
}