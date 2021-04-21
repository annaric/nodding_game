import 'package:flutter/material.dart';
import 'package:esense_flutter/esense.dart';
import 'dart:async';


class SettingsPage extends StatefulWidget {

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _deviceName = 'Unknown';
  double _voltage = -1;
  String _deviceStatus = '';
  bool sampling = false;
  String _button = 'not pressed';
  String eSenseName = 'eSense-0020';
  String _xAxis = "null";
  String _yAxis = "null";
  String _zAxis = "null";
  Timer _timer;
  String _movement = "";
  bool movementNotLeftBefore= true;
  bool movementNotRightBefore= true;
  bool movementNotDownBefore= true;
  bool movementNotUpBefore= true;
  StreamSubscription subscription;

  void initState() {
    super.initState();
  }

  void _disconnectESense() {
    _deviceName = 'Unknown';
    _voltage = -1;
    _deviceStatus = '';
    sampling = false;
    ESenseManager.disconnect();
  }

  Future<void> _connectToESense() async {
    bool con = false;

    ESenseManager.connectionEvents.listen((event) {
      print('CONNECTION event: $event');

      if (event.type == ConnectionType.connected) _listenToESenseEvents();

      setState(() {
        switch (event.type) {
          case ConnectionType.connected:
            _deviceStatus = 'connected';
            break;
          case ConnectionType.unknown:
            _deviceStatus = 'unknown';
            break;
          case ConnectionType.disconnected:
            _deviceStatus = 'disconnected';
            break;
          case ConnectionType.device_found:
            _deviceStatus = 'device_found';
            break;
          case ConnectionType.device_not_found:
            _deviceStatus = 'device_not_found';
            break;
        }
      });
    });

    con = await ESenseManager.connect(eSenseName);

    setState(() {
      _deviceStatus = con ? 'connecting' : 'connection failed';
    });
  }

  void _listenToESenseEvents() async {
    ESenseManager.setSamplingRate(20);
    ESenseManager.eSenseEvents.listen((event) {
      print('ESENSE event: $event');

      setState(() {
        switch (event.runtimeType) {
          case DeviceNameRead:
            _deviceName = (event as DeviceNameRead).deviceName;
            break;
          case BatteryRead:
            _voltage = (event as BatteryRead).voltage;
            break;
          case ButtonEventChanged:
            _button = (event as ButtonEventChanged).pressed ? 'pressed' : 'not pressed';
            break;
          case AccelerometerOffsetRead:
            break;
          case AdvertisementAndConnectionIntervalRead:
            break;
          case SensorConfigRead:
            break;
        }
      });
    });

    _getESenseProperties();
  }

  void _getESenseProperties() async {
    if(_timer != null) {
      _timer.cancel();
    }
    _timer = Timer.periodic(Duration(seconds: 10), (timer) async => await ESenseManager.getBatteryVoltage());

    Timer(Duration(seconds: 2), () async => await ESenseManager.getDeviceName());
    Timer(Duration(seconds: 3), () async => await ESenseManager.getAccelerometerOffset());
    Timer(Duration(seconds: 4), () async => await ESenseManager.getAdvertisementAndConnectionInterval());
    Timer(Duration(seconds: 5), () async => await ESenseManager.getSensorConfig());
  }

  void _startListenToSensorEvents() async {
    print("got into start listening to sensor events");
    ESenseManager.setSamplingRate(20);
    var connected = ESenseManager.isConnected();
    connected.then((value) =>
    {
      subscription = ESenseManager.sensorEvents.listen(
            (event) {
          List<int> values = event.gyro;
          int x = values[0];
          int z = values[2];
          String movement = "";

          if (x < - 4000) {
            if (this.movementNotRightBefore && int.parse(_xAxis) > -4000) {
              movement = "right";
              this.movementNotLeftBefore = false;
            } else {
              this.movementNotRightBefore = true;
            }
          } else if (x > 4000) {
            if (this.movementNotLeftBefore && int.parse(_xAxis) < 4000) {
              movement = "left";
              this.movementNotRightBefore = false;
            } else {
              this.movementNotLeftBefore = true;
            }
          } else if (z > 4000) {
            if (this.movementNotUpBefore && int.parse(_zAxis) < 4000) {
              movement = "down";
              this.movementNotDownBefore = false;
            } else {
              this.movementNotUpBefore = true;
            }
          } else  if (z < -4000) {
            if (this.movementNotDownBefore && int.parse(_zAxis) > -4000) {
              movement = "up";
              this.movementNotUpBefore = false;
            } else {
              this.movementNotDownBefore = true;
            }
          }
          print(movement);
          setState(() {
            _xAxis = values[0].toString();
            _yAxis = values[1].toString();
            _zAxis = values[2].toString();
            if (movement != "") {
              _movement = movement;
            }
          });
        },
      )
    });
  }

  void _pauseListenToSensorEvents() async {
    subscription.pause();
  }

  void dispose() {
    if (subscription != null) subscription.cancel();
    setState(() {
      sampling = false;
    });
    ESenseManager.disconnect();
    if (_timer != null) _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
            Container(margin: EdgeInsets.fromLTRB(20, 20, 20, 20), child: TextFormField(
              initialValue: eSenseName,
                onChanged: (text) {
                  eSenseName = text;
                },
                decoration: InputDecoration(
                    border: OutlineInputBorder(), labelText: 'Device name'),
              )),
              Text('eSense Data:', style: new TextStyle(fontSize:20.0, fontFamily: 'Roboto', color: Colors.black, fontWeight: FontWeight.bold)),
              Text('eSense Device Status: \t$_deviceStatus', style: new TextStyle(fontFamily: 'Roboto')),
              Text('eSense Device Name: \t$_deviceName', style: new TextStyle(fontFamily: 'Roboto')),
              Text('eSense Battery Level: \t$_voltage', style: new TextStyle(fontFamily: 'Roboto')),
              Text('eSense Button Event: \t$_button', style: new TextStyle(fontFamily: 'Roboto')),
               Container(margin: EdgeInsets.fromLTRB(0, 20, 0, 20), child:Center(
                child: (_deviceStatus != "connected")
                  ? new Text("To connect your device click the button below:", style: new TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Roboto'), textAlign: TextAlign.center)
                  : new Text("To disconnect your device click the button below:", style: new TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Roboto'), textAlign: TextAlign.center)
              )),
              Center(
                child: (_deviceStatus != "connected")
                ? IconButton(icon: const Icon(Icons.bluetooth_connected), onPressed: () => _connectToESense(), color: Colors.blueAccent, iconSize:70)
                : IconButton(icon: const Icon(Icons.bluetooth_disabled), onPressed: () => _disconnectESense(), color: Colors.blueAccent, iconSize:70)
              ),
              Container(margin: EdgeInsets.fromLTRB(0, 20, 0, 20), child:new Text("To start or stop listening to Sensor events, click the buttons below:", style: new TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Roboto'),  textAlign: TextAlign.center)),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                  RaisedButton(onPressed: ()=> _startListenToSensorEvents(), child: Text("Start", style: new TextStyle(fontSize:30.0)), color: Colors.greenAccent),
                  RaisedButton(onPressed: ()=> _pauseListenToSensorEvents(), child: Text("Stop", style: new TextStyle(fontSize:30.0)), color: Colors.redAccent)
                  ]
              ),
              Container(margin: EdgeInsets.fromLTRB(0, 20, 0, 20), child:Text('eSense Orientation Data:', style: new TextStyle(fontSize:20.0, fontFamily: 'Roboto', color: Colors.black, fontWeight: FontWeight.bold))),
              Text('eSense x Axis: \t$_xAxis', style: new TextStyle(fontFamily: 'Roboto')),
              Text('eSense y Axis: \t$_yAxis', style: new TextStyle(fontFamily: 'Roboto')),
              Text('eSense z Axis: \t$_zAxis', style: new TextStyle(fontFamily: 'Roboto')),
              Text('eSense movement: \t$_movement', style: new TextStyle(fontFamily: 'Roboto')),
    ]));
  }


}
