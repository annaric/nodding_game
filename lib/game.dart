import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:math';

class Game extends StatefulWidget {
  @override
  _GameState createState() => _GameState();
}
class _GameState extends State<Game> {
  int counter = 0;
  String currentArrow = "left";
  var rng = new Random();
  var icon = Icon(Icons.arrow_back_rounded);
  int timeLeft = 60;
  bool started = false;
  Timer _timer;

  void startTimer() {
    timeLeft = 60;
    counter = 0;
    started = true;
    if(_timer != null) {
      _timer.cancel();
    }
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          _timer.cancel();
          started = false;
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
          counter--;
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
          icon = Icon(Icons.arrow_back_rounded);
        }
        break;
      case 1:
        {
        currentArrow = "up";
        icon = Icon(Icons.arrow_upward_rounded);
        }
      break;
      case 2:
        {
          currentArrow = "down";
          icon = Icon(Icons.arrow_downward_rounded);
        }
        break;
      case 3:
        {
          currentArrow = "right";
          icon = Icon(Icons.arrow_forward_rounded);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      body: Column(
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
                      ? Center( child:IconButton(icon: icon, color: Colors.black, iconSize:150))
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