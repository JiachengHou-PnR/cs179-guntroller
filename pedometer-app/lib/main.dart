import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark, // ThemeMode.system,
      home: PedometerPage(),
      routes: <String, WidgetBuilder>{
        "/bluetooth": (BuildContext context) => BluetoothPage(),
      },
    );
  }
}

class PedometerPage extends StatefulWidget {
  @override
  _PedometerPageState createState() => _PedometerPageState();
}

class _PedometerPageState extends State<PedometerPage> {
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  String _status = '?', _steps = '?';
  int _count = 0, _base = 0;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  void onStepCount(StepCount event) {
    print(event);
    setState(() {
      _steps = event.steps.toString();
      _count = event.steps;
    });
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    print(event);
    setState(() {
      _status = event.status;
      if (_status == "walking") {
        _base = _count;
      }
    });
  }

  void onPedestrianStatusError(error) {
    print('onPedestrianStatusError: $error');
    setState(() {
      _status = 'Pedestrian Status not available';
    });
    print(_status);
  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
    setState(() {
      _steps = 'Step Count not available';
    });
  }

  void initPlatformState() {
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStream
        .listen(onPedestrianStatusChanged)
        .onError(onPedestrianStatusError);

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount).onError(onStepCountError);

    if (!mounted) return;
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
                Navigator.pushNamed(context, "/bluetooth");
              },
            ),
          ],
        ),
        body: PedometerDisplay(
          steps: _steps,
          currSteps: (_count - _base),
          pedStatus: _status,
        ),
    );
  }
}

class PedometerDisplay extends StatelessWidget {
  const PedometerDisplay({
    Key? key,
    required this.steps,
    required this.currSteps,
    required this.pedStatus,
  }) : super(key: key);

  final String steps;
  final String pedStatus;
  final int currSteps;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Center(
          child: Flex(
            direction: orientation == Orientation.portrait
                ? Axis.vertical
                : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Total Steps taken:',
                      style: TextStyle(fontSize: 25),
                    ),
                    Text(
                      steps,
                      style: TextStyle(fontSize: 50),
                    ),
                  ]),
              Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Steps taken:',
                      style: TextStyle(fontSize: 25),
                    ),
                    Text(
                      currSteps.toString(),
                      style: TextStyle(fontSize: 50),
                    ),
                  ]),
              Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Pedestrian status:',
                      style: TextStyle(fontSize: 25),
                    ),
                    Icon(
                      pedStatus == 'walking'
                          ? Icons.directions_walk
                          : pedStatus == 'stopped'
                              ? Icons.accessibility_new
                              : Icons.error,
                      size: 100,
                    ),
                    Center(
                      child: Text(
                        pedStatus,
                        style: pedStatus == 'walking' || pedStatus == 'stopped'
                            ? TextStyle(fontSize: 25)
                            : TextStyle(fontSize: 15, color: Colors.red),
                      ),
                    )
                  ])
            ],
          ),
        );
      },
    );
  }
}

class BluetoothPage extends StatefulWidget {
  BluetoothPage({Key? key}) : super(key: key);

  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = [];
//  final Map<Guid, List<int>> readValues = [];

  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

/*
class BluetoothPage extends StatelessWidget {
  const BluetoothPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth'),
      ),
      body: const Center(
        child: const Text(
          'Bluetooth Page',
          style: TextStyle(fontSize: 60),
        ),
      ),
    );
  }
}
*/

class _BluetoothPageState extends State<BluetoothPage> {
//  final _writeController = TextEditingController();
  List<BluetoothService> _services = [];
  bool _connected = false;
  Widget _screen = ListView();

  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      print("Found device ${device.name}(${device.id})");
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceTolist(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceTolist(result.device);
      }
    });
    widget.flutterBlue.startScan();
  }

  ListView _buildListViewOfDevices() {
    List<Container> containers = [];
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(
        Container(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(device.name == '' ? '(unknown device)' : device.name),
                    Text(device.id.toString()),
                  ],
                ),
              ),
              ElevatedButton(
                child: const Text(
                  'Connect',
                ),
                onPressed: () async {
                  widget.flutterBlue.stopScan();
                    await device.connect();
                    _services = await device.discoverServices();
                    _screen = DeviceScreen(device: device, services: _services);
                  setState(() {
                    _connected = true;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }
  
    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text("Bluetooth"),
    ),
    body: _connected ? _screen : _buildListViewOfDevices(),
  );
}

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({Key? key, required this.device, required this.services}) : super(key: key);

  final BluetoothDevice device;
  final List<BluetoothService> services;

  List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = [];
  
    if (characteristic.properties.read) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              color: Colors.blue,
              child: Text('READ', style: TextStyle(color: Colors.white)),
              onPressed: () {},
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.write) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              child: Text('WRITE', style: TextStyle(color: Colors.white)),
              onPressed: () {},
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.notify) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              child: Text('NOTIFY', style: TextStyle(color: Colors.white)),
              onPressed: () {},
            ),
          ),
        ),
      );
    }
  
    return buttons;
  }

  ListView _buildConnectDeviceView() {
    List<Container> containers = [];
    for (BluetoothService service in services) {
      List<Widget> characteristicsWidget = [];
     for (BluetoothCharacteristic characteristic in service.characteristics) {
       characteristic.value.listen((value) {
         print(value);
       });
       characteristicsWidget.add(
         Align(
           alignment: Alignment.centerLeft,
           child: Column(
             children: <Widget>[
               Row(
                 children: <Widget>[
                   Text(characteristic.uuid.toString(), style: TextStyle(fontWeight: FontWeight.bold)),
                 ],
               ),
               Row(
                 children: <Widget>[
                   ..._buildReadWriteNotifyButton(characteristic),
                 ],
               ),
               Divider(),
             ],
           ),
         ),
       );
     }
     containers.add(
       Container(
         child: ExpansionTile(
             title: Text(service.uuid.toString()),
             children: characteristicsWidget),
       ),
     );
   }
  
    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  @override
  Widget build(BuildContext context) => _buildConnectDeviceView();
}
