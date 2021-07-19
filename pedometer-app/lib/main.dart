import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pedometer/pedometer.dart';

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
