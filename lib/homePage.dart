import 'package:flutter/material.dart';
import 'settingsPage.dart';
import 'game.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nodding Game"),
        bottom: TabBar(
          tabs: [
            Tab(text: "The Game"),
            Tab(text: "Settings"),
          ],
        ),
      ),
      body: TabBarView(children: [
        Game(),
        SettingsPage(),
      ],)
    );
  }
}
