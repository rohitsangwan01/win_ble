# WinBle

[![win_ble version](https://img.shields.io/pub/v/win_ble?label=win_ble)](https://pub.dev/packages/win_ble)

WinBle Plugin to use Bluetooth Low Energy in Flutter Windows

## Getting Started

add this package to pubspec.yaml file

```dart
win_ble: ^0.0.4
```

requires Windows version >= 10.0.15014

Make Sure to Add this code in your project's =>

`/windows/runner/main.cpp` file , otherwise Windows Console will open on running Application

```c++
if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()){
CreateAndAttachConsole();
}
// Add this Code
// <------- From Here --------- >
else{
    STARTUPINFO si = {0};
    si.cb = sizeof(si);
    si.dwFlags = STARTF_USESHOWWINDOW;
    si.wShowWindow = SW_HIDE;

    PROCESS_INFORMATION pi = {0};
    WCHAR lpszCmd[MAX_PATH] = L"cmd.exe";
    if (::CreateProcess(NULL, lpszCmd, NULL, NULL, FALSE, CREATE_NEW_CONSOLE | CREATE_NO_WINDOW, NULL, NULL, &si, &pi))
    {
      do
      {
        if (::AttachConsole(pi.dwProcessId))
        {
          ::TerminateProcess(pi.hProcess, 0);
          break;
        }
      } while (ERROR_INVALID_HANDLE == GetLastError());
      ::CloseHandle(pi.hProcess);
      ::CloseHandle(pi.hThread);
    }
}
// <------- UpTo Here --------- >
```

## Usage

First initialize WinBle by Calling this Method

```dart
 WinBle.initialize();
```

Dispose WinBle after using , by Calling

```dart
 WinBle.dispose();
```

To Get Bluetooth Status , Call

```dart
  WinBle.bleState.listen((BleState state) {
    // Get BleState (On, Off, Unknown, Disabled, Unsupported)
  });
```


To Start Scan , Call

```dart
 WinBle.startScanning();
 StreamSubscription? scanStream = WinBle.scanStream.listen((event) {
  // Get Devices Here
 });
```

To Stop Scan , Call

```dart
  WinBle.stopScanning();
  scanStream?.cancel();
```

To Connect 
```dart
// To Connect
  await WinBle.connect(address);

// Get Connection Updates Here
  StreamSubscription  _connectionStream =
        WinBle.connectionStreamOf(device.address).listen((event) {
      // event will be a boolean , in which
      // true => Connected
      // false => Disconnected
    });
```

To Disconnect
```dart
  await WinBle.disconnect(address);
```

Pairing Options
```dart
  // To Pair
  await WinBle.pair(address);

  // To UnPair
  await WinBle.unPair(address);

  // To Check if Device can be Paired
  bool canPair = await WinBle.canPair(address);

  // To Check if Device is Already Paired
  bool isPaired = await WinBle.isPaired(address);
```
Rest All Methods are
```dart
// To Get Services
  var services = await WinBle.discoverServices(address);

// To Get Characteristic
  List<BleCharacteristic> bleCharacteristics = await WinBle.discoverCharacteristics(address: address, serviceId: serviceID);

// To Read Characteristic
  List<int> data = await WinBle.read(address: address, serviceId: serviceID, characteristicId: charID);

// To Write Characteristic
  await WinBle.write( address: address, service: serviceID,  characteristic: charID,  data: data, writeWithResponse: writeWithResponse);

// To Start Subscription
  await WinBle.subscribeToCharacteristic(address: address, serviceId: serviceID, characteristicId: charID);

// To Stop Subscription
  await WinBle.unSubscribeFromCharacteristic(address: address, serviceId: serviceID, characteristicId: charID);

// Get Characteristic Value Updates Here
   StreamSubscription _characteristicValueStream =
        WinBle.characteristicValueStream.listen((event) {
     // Here We will Receive All Characteristic Events
    });

```

## Additional information
Thanks to [noble-winrt](https://github.com/urish/noble-winrt) for initial BleServer Code

This is Just The Initial Version feel free to Contribute or Report any Bug!
