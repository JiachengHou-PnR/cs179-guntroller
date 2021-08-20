import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:pref/pref.dart';

import 'package:flutter/material.dart';
import 'package:pedometer_app/ped.dart';
import 'package:pedometer_app/bluetooth.dart';
import 'package:pedometer_app/accelerometer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final service = await PrefServiceShared.init(
    defaults: {
      'sensor': 'accelerometer',
      'walk_sensitivity': 8,
      'stop_sensitivity': 6,
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

class MyApp extends StatelessWidget {
  ThemeMode getTheme(BuildContext context) {
    String? theme = PrefService.of(context).get('ui_theme');
    switch (theme) {
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: getTheme(context),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<BluetoothConnection> _connections = [];
  bool _walking = false;

  @override
  void initState() {
    super.initState();
  }

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
      body: PrefService.of(context).get('sensor') == 'pedometer'
          ? PedometerPage(onStatusChange: _walkStatus)
          : AccelerometerPage(
              onStatusChange: _walkStatus,
              walkSens: 10 -
                  (PrefService.of(context).get<int>('walk_sensitivity') ?? 8),
              stopSens: 10 -
                  (PrefService.of(context).get<int>('stop_sensitivity') ?? 6)),
    );
  }
}

class Preferences extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: PrefPage(children: [
        PrefTitle(
            title: const Text('Settings'),
            subtitle: const Text('Restart required to take effect')),
        PrefTitle(title: const Text('Sensor')),
        PrefRadio(
          title: Text('Accelerometer'),
          pref: 'sensor',
          value: 'accelerometer',
        ),
        PrefRadio(
          title: Text('Pedometer'),
          pref: 'sensor',
          value: 'pedometer',
        ),
        PrefTitle(title: const Text('Accelerometer Settings')),
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
