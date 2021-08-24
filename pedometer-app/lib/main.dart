import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:pref/pref.dart';

import 'package:flutter/material.dart';
import 'package:pedometer_app/ped.dart';
import 'package:pedometer_app/bluetooth.dart';
import 'package:pedometer_app/accelerometer.dart';

const int MAX_SENS = 10;
const int WALK_SENS = 8;
const int STOP_SENS = 6;
const double MOVE_THRESHOLD = 3.5;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final service = await PrefServiceShared.init(
    defaults: {
      'sensor': 'pedometer',
      'walk_sensitivity': WALK_SENS,
      'stop_sensitivity': STOP_SENS,
      'move_threshold': MOVE_THRESHOLD,
      'ui_theme': 'system',
    },
  );

  runApp(
    PrefService(
      service: service,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late String _sensor, _theme;
  late int _walkSens, _stopSens;
  late double _moveThreshold;

  bool _refreshState = true;

  ThemeMode _getTheme() {
    switch (_theme) {
      case 'system':
        return ThemeMode.system;
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void _updateState(BuildContext context) {
    setState(() {
      _sensor = PrefService.of(context).get('sensor') ?? 'pedometer';
      _theme = PrefService.of(context).get('ui_theme') ?? 'system';
      _walkSens = PrefService.of(context).get('walkSens') ?? WALK_SENS;
      _stopSens = PrefService.of(context).get('stopSens') ?? STOP_SENS;
      _moveThreshold =
          PrefService.of(context).get('moveThreshold') ?? MOVE_THRESHOLD;
    });
  }

  void _refresh() {
    setState(() {
      _refreshState = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_refreshState) {
      _updateState(context);
      _refreshState = false;
    }

    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _getTheme(),
      home: MainPage(
          sensor: _sensor,
          walkSens: _walkSens,
          stopSens: _stopSens,
          moveThreshold: _moveThreshold,
          onDrawerClose: _refresh),
    );
  }
}

class MainPage extends StatefulWidget {
  final String sensor;
  final int walkSens, stopSens;
  final double moveThreshold;
  final VoidCallback onDrawerClose;

  const MainPage(
      {required this.sensor,
      required this.walkSens,
      required this.stopSens,
      required this.moveThreshold,
      required this.onDrawerClose});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<BluetoothConnection> _connections = [];
  bool _walking = false;

  void _sendData() {
    print("Sending ${_walking ? 1 : 0}");
    for (BluetoothConnection conn in _connections) {
      conn.output.add(Uint8List.fromList([_walking ? 1 : 0]));
    }
  }

  void _addConnection(BluetoothConnection conn) {
    setState(() {
      _connections.add(conn);
    });
  }

  void _walkStatus(bool status) {
    setState(() {
      _walking = status;
    });
    _sendData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Preferences(),
      onDrawerChanged: (bool open) {
        if (!open) {
          widget.onDrawerClose();
        }
      },
      appBar: AppBar(
        title:
            Text(widget.sensor[0].toUpperCase() + widget.sensor.substring(1)),
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
      body: widget.sensor == 'pedometer'
          ? PedometerPage(onStatusChange: _walkStatus)
          : AccelerometerPage(
              onStatusChange: _walkStatus,
              walkSens: MAX_SENS - widget.walkSens,
              stopSens: MAX_SENS - widget.stopSens,
              moveThreshold: widget.moveThreshold,
            ),
    );
  }
}

class Preferences extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: PrefPage(children: [
        PrefTitle(title: const Text('Settings')),
        PrefTitle(title: const Text('Sensor')),
        PrefRadio(
          title: Text('Pedometer'),
          subtitle: Text('More accurate, but slower'),
          pref: 'sensor',
          value: 'pedometer',
        ),
        PrefRadio(
          title: Text('Accelerometer'),
          subtitle: Text('Less accurate, but faster'),
          pref: 'sensor',
          value: 'accelerometer',
        ),
        PrefTitle(title: const Text('Accelerometer Settings')),
        PrefSlider<double>(
          title: Text('Threshold'),
          pref: 'move_threshold',
          trailing: (num v) => Text('$v m/s^2'),
          divisions: 11,
          min: 0.5,
          max: 6,
        ),
        PrefSlider<int>(
          title: Text('Walk Sensitivity'),
          pref: 'walk_sensitivity',
          trailing: (num v) => Text(v.toString()),
          min: 0,
          max: 10,
        ),
        PrefSlider<int>(
          title: Text('Stop Sensitivity'),
          pref: 'stop_sensitivity',
          trailing: (num v) => Text(v.toString()),
          min: 0,
          max: 10,
        ),
        PrefTitle(title: const Text('Theme')),
        PrefRadio(
          title: Text('System Theme'),
          value: 'system',
          pref: 'ui_theme',
        ),
        PrefRadio(
          title: Text('Light Theme'),
          value: 'light',
          pref: 'ui_theme',
        ),
        PrefRadio(
          title: Text('Dark Theme'),
          value: 'dark',
          pref: 'ui_theme',
        ),
      ]),
    );
  }
}
