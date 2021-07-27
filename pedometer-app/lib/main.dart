import 'package:flutter/material.dart';
import 'package:pedometer_app/ped.dart';
import 'package:pedometer_app/bluetooth.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: PedometerPage(),
      routes: <String, WidgetBuilder>{
        "/bluetooth": (BuildContext context) => BluetoothPage(),
      },
    );
  }
}
