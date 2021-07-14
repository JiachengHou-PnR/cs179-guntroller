import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pedometer/pedometer.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Pedometer app'),
        ),
        body: OrientationBuilder(
          builder: (context, orientation) {
            return Center(
              child: Flex(
                direction: orientation == Orientation.portrait
                    ? Axis.vertical
                    : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Total Steps taken:',
                          style: TextStyle(fontSize: 25),
                        ),
                        Text(
                          _steps,
                          style: TextStyle(fontSize: 50),
                        ),
                      ]),
                  orientation == Orientation.portrait
                      ? Divider(
                          height: 50,
                          thickness: 0,
                          color: Colors.transparent,
                        )
                      : VerticalDivider(
                          width: 20,
                          thickness: 0,
                          color: Colors.transparent,
                        ),
                  Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Steps taken:',
                          style: TextStyle(fontSize: 25),
                        ),
                        Text(
                          (_count - _base).toString(),
                          style: TextStyle(fontSize: 50),
                        ),
                      ]),
                  orientation == Orientation.portrait
                      ? Divider(
                          height: 50,
                          thickness: 0,
                          color: Colors.transparent,
                        )
                      : VerticalDivider(
                          width: 20,
                          thickness: 0,
                          color: Colors.transparent,
                        ),
                  Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Pedestrian status:',
                          style: TextStyle(fontSize: 25),
                        ),
                        Icon(
                          _status == 'walking'
                              ? Icons.directions_walk
                              : _status == 'stopped'
                                  ? Icons.accessibility_new
                                  : Icons.error,
                          size: 100,
                        ),
                        Center(
                          child: Text(
                            _status,
                            style: _status == 'walking' || _status == 'stopped'
                                ? TextStyle(fontSize: 25)
                                : TextStyle(fontSize: 15, color: Colors.red),
                          ),
                        )
                      ])
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
