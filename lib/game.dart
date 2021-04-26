import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:math';
import 'settingsPage.dart';
import 'package:esense_flutter/esense.dart';

class Game extends StatefulWidget {
  @override
  _GameState createState() => _GameState();
}
class _GameState extends State<Game> {
  int counter = 0;
  String currentArrow = "left";
  var rng = new Random();
  var icon = IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => true, color: Colors.redAccent, iconSize:150);
  int timeLeft = 60;
  bool started = false;
  Timer _timer;
  SettingsPage settingsPage = new SettingsPage();
  String _deviceName = 'Unknown';
  double _voltage = -1;
  String _deviceStatus = '';
  bool sampling = false;
  String _button = 'not pressed';
  String eSenseName = 'eSense-0020';
  String _xAxis = "null";
  String _yAxis = "null";
  String _zAxis = "null";
  String _movement = "";
  bool movementNotLeftBefore= true;
  bool movementNotRightBefore= true;
  bool movementNotDownBefore= true;
  bool movementNotUpBefore= true;
  bool playWithoutHeadPhones = false;
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
    Timer.periodic(Duration(seconds: 10), (timer) async => await ESenseManager.getBatteryVoltage());

    Timer(Duration(seconds: 2), () async => await ESenseManager.getDeviceName());
    Timer(Duration(seconds: 3), () async => await ESenseManager.getAccelerometerOffset());
    Timer(Duration(seconds: 4), () async => await ESenseManager.getAdvertisementAndConnectionInterval());
    Timer(Duration(seconds: 5), () async => await ESenseManager.getSensorConfig());
  }

  void _startListenToSensorEvents() async {
    print("start listen to sensor events");
    ESenseManager.setSamplingRate(20);
    var connected = ESenseManager.isConnected();
    connected.then((value) =>
    {
      subscription = ESenseManager.sensorEvents.listen(
            (event) {
              print("sensor event listen");
          List<int> values = event.gyro;
          int x = values[0];
          int z = values[2];
          String movement = "";

          if (x < - 4000) {
            movement = "right";
          } else if (x > 4000) {
            movement = "left";
          } else if (z > 4000) {
            movement = "down";
          } else  if (z < -4000) {
            movement = "up";
          }
          checkArrowClick(movement);
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

  void startTimer() {
    timeLeft = 60;
    counter = 0;
    started = true;
    if(_timer != null) {
      _timer.cancel();
    }
    _startListenToSensorEvents();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          _timer.cancel();
          started = false;
          _pauseListenToSensorEvents();
        }
      });
    });
  }

  void checkArrowClick(String arrow) {
    if (started) {
      setState(() {
        if (arrow == currentArrow) {
          updateArrow();
          counter++;
        } else {
          //counter--;
        }
      });
    }
  }

  void updateArrow() {
    int i = rng.nextInt(4);
    switch (i) {
      case 0:
        {
          currentArrow = "left";
          icon = IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => true, color: Colors.redAccent, iconSize:150);
        }
        break;
      case 1:
        {
        currentArrow = "up";
        icon = IconButton(icon: const Icon(Icons.arrow_upward_rounded), onPressed: () => true, color: Colors.blueAccent, iconSize:150);
        }
      break;
      case 2:
        {
          currentArrow = "down";
          icon = IconButton(icon: const Icon(Icons.arrow_downward_rounded), onPressed: () => true, color: Colors.orangeAccent, iconSize:150);
        }
        break;
      case 3:
        {
          currentArrow = "right";
          icon = IconButton(icon: const Icon(Icons.arrow_forward_rounded), onPressed: () => true, color: Colors.greenAccent, iconSize:150);
        }
        break;
    }
  }

  setPlayWithoutHeadPhones() {
    setState(() {
      playWithoutHeadPhones = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      body:
      (_deviceStatus != "connected" && !playWithoutHeadPhones)
      ? Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            new Text("To connect your device to play click the button below:", style: new TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Roboto', fontSize:30.0), textAlign: TextAlign.center),
            Text('eSense Device Status: \t$_deviceStatus', style: new TextStyle(fontFamily: 'Roboto', fontSize:20.0)),
            Center(
                child: (_deviceStatus != "connected")
                    ? IconButton(icon: const Icon(Icons.bluetooth_connected), onPressed: () => _connectToESense(), color: Colors.blueAccent, iconSize:70)
                    : (_deviceStatus == "connecting")
                      ? FlatButton(onPressed: () => {}, child: CircularProgressIndicator(backgroundColor: Colors.blueAccent,))
                      : IconButton(icon: const Icon(Icons.bluetooth_disabled), onPressed: () => _disconnectESense(), color: Colors.blueAccent, iconSize:70)
            ),
            new Text("If you want to continue without the headphones, click here:", style: new TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Roboto', fontSize:20.0), textAlign: TextAlign.center),
            RaisedButton(onPressed: ()=> setPlayWithoutHeadPhones(), child: Text("Play without headphones", style: new TextStyle(fontSize:20.0)), color: Colors.greenAccent)
          ]
        )
      : Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column (
            children: <Widget>[
              Container(margin: EdgeInsets.fromLTRB(0, 20, 0, 0),child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  new Text("Score: $counter", style: new TextStyle(fontWeight: FontWeight.bold, fontSize:20.0, fontFamily: 'Roboto')),
                  new Text("Time Left: $timeLeft", style: new TextStyle(fontWeight: FontWeight.bold, fontSize:20.0, fontFamily: 'Roboto')),
                ]
              )),
              Container(margin: EdgeInsets.fromLTRB(0, 20, 0, 0), child:Center(
                child: (!started)
                    ?RaisedButton(onPressed: ()=> startTimer(), child: Text("Start", style: new TextStyle(fontSize:30.0)), color: Colors.greenAccent)
                    :RaisedButton(onPressed: ()=> startTimer(), child: Text("Restart", style: new TextStyle(fontSize:30.0)), color: Colors.greenAccent)
              )),
            ]),
          Center (
              child:
              (timeLeft > 0)
                  ? (started)
                      ? Center( child:icon)
                      : Center( child: new Text ("Click the start button to start the Game", style: new TextStyle(fontSize:20.0, fontFamily: 'Roboto', color: Colors.black)))
                  : Center(child: new Text ("Time is up! You reached the score $counter", textAlign: TextAlign.center, style: new TextStyle(fontWeight: FontWeight.bold, fontSize:40.0, fontFamily: 'Roboto', color: Colors.blueAccent)))
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => checkArrowClick("left"), color: Colors.redAccent, iconSize:70),
              IconButton(icon: const Icon(Icons.arrow_downward_rounded), onPressed: () => checkArrowClick("down"), color: Colors.orangeAccent, iconSize:70),
              IconButton(icon: const Icon(Icons.arrow_upward_rounded), onPressed: () => checkArrowClick("up"), color: Colors.blueAccent, iconSize:70),
              IconButton(icon: const Icon(Icons.arrow_forward_rounded), onPressed: () => checkArrowClick("right"), color: Colors.greenAccent, iconSize:70)
            ],
          ),
        ],
      ),
    );
  }
}