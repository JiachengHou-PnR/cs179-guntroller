import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class AccelerometerPage extends StatefulWidget {
  final ValueChanged<bool> onStatusChange;
  final int walkSens;
  final int stopSens;
  final double moveThreshold;

  const AccelerometerPage(
      {required this.onStatusChange,
      required this.walkSens,
      required this.stopSens,
      required this.moveThreshold});

  @override
  _AccelerometerPageState createState() => _AccelerometerPageState();
}

class _AccelerometerPageState extends State<AccelerometerPage> {
  late StreamSubscription<UserAccelerometerEvent> _accelerometerStream;
  String _status = "stopped";
  double _x = 0, _y = 0, _z = 0;
  int _walkCount = 0, _stopCount = 0;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    _accelerometerStream.cancel();

    super.dispose();
  }

  void onMovement(UserAccelerometerEvent event) {
    print(event);
    String temp = _status;
    setState(() {
      _x = event.x;
      _y = event.y;
      _z = event.z;
      if ((_x.abs() > widget.moveThreshold ||
          _y.abs() > widget.moveThreshold ||
          _z.abs() > widget.moveThreshold)) {
        _walkCount++;
        _stopCount = 0;
        if (_walkCount > widget.walkSens) {
          _status = "walking";
          _walkCount = 0;
        }
      } else {
        _stopCount++;
        _walkCount = 0;
        if (_stopCount > widget.stopSens) {
          _status = "stopped";
          _stopCount = 0;
        }
      }
    });
    if (temp != _status) {
      widget.onStatusChange(_status == "walking");
    }
  }

  void onMovementError(error) {
    print('onMovementError: $error');
    setState(() {
      _status = "Status not available";
    });
  }

  void initPlatformState() {
    _accelerometerStream = userAccelerometerEvents.listen(onMovement);
    _accelerometerStream.onError(onMovementError);

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return AccelerometerDisplay(
      status: _status,
      x: _x,
      y: _y,
      z: _z,
    );
  }
}

class AccelerometerDisplay extends StatelessWidget {
  const AccelerometerDisplay({
    Key? key,
    required this.status,
    required this.x,
    required this.y,
    required this.z,
  }) : super(key: key);

  final String status;
  final double x, y, z;

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
                      'X:',
                      style: TextStyle(fontSize: 25),
                    ),
                    Text(
                      x.toStringAsFixed(2),
                      style: TextStyle(fontSize: 50),
                    ),
                  ]),
              Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Y:',
                      style: TextStyle(fontSize: 25),
                    ),
                    Text(
                      y.toStringAsFixed(2),
                      style: TextStyle(fontSize: 50),
                    ),
                  ]),
              Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Z:',
                      style: TextStyle(fontSize: 25),
                    ),
                    Text(
                      z.toStringAsFixed(2),
                      style: TextStyle(fontSize: 50),
                    ),
                  ]),
              Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Status:',
                      style: TextStyle(fontSize: 25),
                    ),
                    Icon(
                      status == 'walking'
                          ? Icons.directions_walk
                          : status == 'stopped'
                              ? Icons.accessibility_new
                              : Icons.error,
                      size: 100,
                    ),
                    Center(
                      child: Text(
                        status,
                        style: status == 'walking' || status == 'stopped'
                            ? TextStyle(fontSize: 25)
                            : TextStyle(fontSize: 15, color: Colors.red),
                      ),
                    )
                  ]),
            ],
          ),
        );
      },
    );
  }
}
