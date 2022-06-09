// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:win_ble/win_ble.dart';
import 'package:win_ble_example/device_info.dart';

void main() {
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? scanStream;
  StreamSubscription? connectionStream;

  bool isScanning = false;

  @override
  void initState() {
    WinBle.initialize(enableLog: true);
    // call winBLe.dispose() when done
    connectionStream = WinBle.connectionStream.listen((event) {
      print("Connection Event : " + event.toString());
    });

    // Listen to Scan Stream , we can cancel in onDispose()
    scanStream = WinBle.scanStream.listen((event) {
      setState(() {
        if (!devices.any((element) => element.address == event.address)) {
          devices.add(event);
        }
      });
    });
    super.initState();
  }

  String bleStatus = "";
  String bleError = "";

  List<BleDevice> devices = <BleDevice>[];

  /// Main Methods
  startScanning() {
    WinBle.startScanning();
    setState(() {
      isScanning = true;
    });
  }

  stopScanning() {
    WinBle.stopScanning();
    setState(() {
      isScanning = false;
    });
  }

  onDeviceTap(BleDevice device) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => DeviceInfo(
                device: device,
              )),
    );
  }

  @override
  void dispose() {
    scanStream?.cancel();
    connectionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Win BLe"),
          centerTitle: true,
        ),
        body: SizedBox(
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
                  kButton("Start", () {
                    startScanning();
                  }),
                  kButton("Stop", () {
                    stopScanning();
                  }),
                ],
              ),
              const Divider(),
              Column(
                children: [
                  Text(bleStatus),
                  Text(bleError),
                ],
              ),

              Expanded(
                child: devices.isEmpty
                    ? noDeviceFoundWidget()
                    : ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (BuildContext context, int index) {
                          BleDevice device = devices[index];
                          return InkWell(
                            onTap: () {
                              stopScanning();

                              onDeviceTap(device);
                            },
                            child: Card(
                              child: ListTile(
                                  leading: Text(device.name.isEmpty
                                      ? "N/A"
                                      : device.name),
                                  title: Text(device.address),
                                  // trailing: Text(device.manufacturerData.toString()),
                                  subtitle: Text(
                                      "rssi : ${device.rssi} | AdvTpe : ${device.advType}")),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ));
  }

  Widget kButton(String txt, onTap) {
    return ElevatedButton(
      onPressed: onTap,
      child: Text(
        txt,
        style: const TextStyle(fontSize: 20),
      ),
    );
  }

  Widget noDeviceFoundWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        isScanning
            ? const CircularProgressIndicator()
            : InkWell(
                onTap: () {
                  startScanning();
                },
                child: const Icon(
                  Icons.bluetooth,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
        const SizedBox(
          height: 10,
        ),
        Text(isScanning ? "Scanning Devices ... " : "Click to start scanning")
      ],
    );
  }
}
