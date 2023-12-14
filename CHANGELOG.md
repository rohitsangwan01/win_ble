## 1.0.2

- Add parameter to discover uncached services [#29](https://github.com/rohitsangwan01/win_ble/pull/29)
- Prevent multiple creations of win_ble_server.exe files [#32](https://github.com/rohitsangwan01/win_ble/pull/32)

## 1.0.1

- Added Bluetooth radio related Api : turn on/off programatically
- Added api to get maxMtuSize

## 1.0.0

- Added support for pure dart (Windows only)
- Fix: few events were missing
- BreakingChange: Initialize method now requires BleServer.exe path
- Improved apis and minor fixes

## 0.0.5

- Added BleState , to get status of Bluetooth Radio

## 0.0.4

- Fixed writeWithResponse
- breaking Change : startScan method is void now , to listen to scan result ,listen to WinBle.scanStream

## 0.0.2

- Added ManufacturerData
- Added Option to Pair/UnPair Ble Device
- Added ability to check ( canPair / isPaired ) Status
- minor Bug fixes

## 0.0.1

- initial Version
