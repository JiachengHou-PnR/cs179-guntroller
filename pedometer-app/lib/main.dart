import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

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
      themeMode: ThemeMode.dark, // ThemeMode.system,
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

/*
const len = 100;
final duration = Duration(milliseconds: 500);

final zeros = Uint8List.fromList(List<int>.filled(len, 0, growable: false));
final ones = Uint8List.fromList(List<int>.filled(len, 255, growable: false));
*/

class _MainPageState extends State<MainPage> {
  List<BluetoothConnection> _connections = [];
  bool _walking = false;

  @override
  void initState() {
    super.initState();
/*
    Timer.periodic(duration, (Timer timer) {
      _sendData();
    });
*/
  }

  void _sendData() {
    print("Sending ${_walking ? 1 : 0}");
    for (BluetoothConnection conn in _connections) {
      // conn.output.add(_walking ? zeros : ones);
      conn.output.add(Uint8List.fromList([_walking ? 1 : 0]));
    }
  }

  void _addConnection(BluetoothConnection conn) {
    setState(() {
      _connections.add(conn);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedometer'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.bluetooth),
            tooltip: 'Bluetooth',
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          BluetoothPage(onConnect: _addConnection)));
            },
          ),
        ],
      ),
/*
      body: Center(
        child: Switch(
          value: _walking,
          onChanged: (val) {
            setState(() {
              _walking = val;
            });
          },
        ),
      ),
*/
      body: PedometerPage(onStatusChange: (status) {
        setState(() {
          _walking = status;
        });
        _sendData();
      }),
    );
  }
}
