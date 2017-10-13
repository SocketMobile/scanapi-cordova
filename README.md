Socket Mobile ScanAPI Cordova Plugin
====================================

Introduction
------------
This Socket Mobile ScanAPI Cordova plugin allows to use Socket Mobile
barcode scanners with a Cordova application.

This Cordova plugin supports only iOS at this time.

IT DOES REQUIRE THE SOCKET MOBILE SCANAPI SDK THAT IS AVAILABLE FOR
DOWNLOAD FROM SOCKET MOBILE DEVELOPER PORTAL.

Installation
------------
Clone this repository:
`git clone git@github.com:SocketMobile/scanapi-cordova.git`

Download the Socket Mobile ScanAPI SDK for iOS.
Unzip the SDK.

Update the ScanAPI Cordova plugin with the ScanAPI SDK files:
```
cd scanapi-cordova
node updateSdk.js <ScanAPI Cordova plugin dir> <ScanAPI SDK dir>
```

For example if the ScanAPI SDK has been unzipped under the same directory where the ScanAPI Cordova plugin has been cloned you may have something similar to this:
```
ls
=> scanapi-cordova   ScanApiSDK-10.3.93
cd scanapi-cordova
node updateSdk.js . ../ScanApiSDK-10.3.93
```

Once the ScanAPI Cordova plugin has been updated with the ScanAPI files then the plugin is now ready to be added to your Cordova application:

```
cordova plugin add /Users/me/documents/dev/github/scanapi-cordova
```

To remove the plugin from your Cordova application:

```
cordova plugin remove com-socketmobile-scanapi-cordova
```


Using the SDK in a Cordova application
--------------------------------------

This current version of the ScanAPI SDK for Cordova is limited to notifications coming from the Socket Mobile barcode scanner.

The first thing is to set the callback function that will receive the ScanAPI SDK events:

```
SocketScanApi.useScanApi('', scanApiNotification);
```

And the `scanApiNotification` might look like this:
```
const scanApiNotification = (event) => {
  try {
    event = JSON.parse(event);
    if (event.type) {
        console.log('receive an event: ', event.type);
        if (event.type === 'decodedData') {
          let decodedData = event.decodedData.map(c => String.fromCharCode(c)).join('');
          console.log('decodedData: ', decodedData);
        }
    }
  } catch(e) {
    console.log('event received: ', event);
  }
}
```

Possible events received from ScanAPI
-------------------------------------

#### Device Arrival
Each time a scanner is connected and ready to be used then the device arrival event is generated to let the application know a new scanner is ready.

This event contains the information about the scanner such as its type and the friendly name associated to the scanner.
The device handle identifies the scanner in a unique fashion and changes each time the scanner connects.

Here is the json data received in the ScanApi callback:
```
{
  "type" : "deviceArrival",
  "deviceType" : 196618,
  "deviceHandle" : "7517305712",
  "deviceName" : "Socket D750 [81FBF9]"
}
```

#### Device Removal
The device removal event occurs each time the scanner disconnects from the host.
It holds the information about the scanner that has just disconnected.

```
{
  "type" : "deviceRemoval",
  "deviceType" : 196618,
  "deviceHandle" : "7517305712",
  "deviceName" : "Socket D750 [81FBF9]"
}
```

#### Decoded Data
Each time the scanner successfully scans a barcode, the decoded data event is generated holding the decoded data, the symbology ID and the symbology name as well as the scanner information from which the decoded data came from.

```
{
 "type" : "decodedData",
 "deviceHandle" : "7517305712",
 "deviceName" : "Socket D750 [81FBF9]",
 "deviceType" : 196618,
 "decodedData" : [48,55,56,54,49,54,50,51,51,56,48,48,54,13],
 "symbologyName" : "Ean 13",
 "symbologyId" : 19
}
```

If the type of the decoded data is UTF8 based a simple conversion can reformat the decoded data as a string like this:
```
if (event.type === 'decodedData') {
  const decodedData = event.decodedData.map(c => String.fromCharCode(c)).join('');
  console.log('decodedData: ', decodedData);
}
```

#### ScanAPI initialize Complete
When ScanAPI is initialized for the first time, an event is generated to confirm the result of the initialization.

```
{
  "type" : "initializeComplete",
  "result" : 0
}
```

#### ScanAPI Terminated
When ScanAPI is shutting down, a terminate event is sent to indicate to the application that it won't receive anymore notifications from ScanAPI.

```
{
  "type" : "scanApiTerminated"
}
```

#### Error
If an error occurs, ScanAPI will send an event that includes the error code.

```
{
  "type" : "error",
  "name" : "onError",
  "result" : -27
}
```
