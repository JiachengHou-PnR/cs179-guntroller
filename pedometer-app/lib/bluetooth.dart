import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

typedef void ConnectionCallback(BluetoothConnection conn);

class BluetoothPage extends StatefulWidget {
  final bool start;
  final ConnectionCallback onConnect;

  const BluetoothPage({required this.onConnect, this.start = true});

  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;
  List<BluetoothDiscoveryResult> results = [];
  bool isScanning = false;

  _BluetoothPageState();

  void _startScanning() {
    _streamSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        final existingIndex = results.indexWhere(
            (element) => element.device.address == r.device.address);
        if (existingIndex >= 0) {
          results[existingIndex] = r;
        } else {
          results.add(r);
        }
      });
    });

    _streamSubscription!.onDone(() {
      setState(() {
        isScanning = false;
      });
    });
  }

  Future<void> _restartScanning() async {
    setState(() {
      results.clear();
      isScanning = true;
    });

    _startScanning();
  }

  @override
  void initState() {
    super.initState();

    isScanning = widget.start;
    if (isScanning) {
      _startScanning();
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();

    super.dispose();
  }

  ListView _buildListViewOfDevices() {
    List<Container> containers = [];
    for (BluetoothDiscoveryResult result in results) {
      final device = result.device;
      final address = device.address;
      containers.add(
        Container(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(device.name == ''
                        ? '(unknown device)'
                        : device.name ?? '(unknown device)'),
                    Text(device.address),
                  ],
                ),
              ),
              device.isConnected
                  ? const Text("Connected")
                  : ElevatedButton(
                      child: const Text(
                        'Connect',
                      ),
                      onPressed: () async {
                        try {
                          print('Connecting to ${device.address}...');
                          BluetoothConnection conn =
                              await BluetoothConnection.toAddress(address);
                          widget.onConnect(conn);
                          print('Connected to ${device.address}');
                          setState(() {
                            results.remove(result);
                          });
                        } catch (e) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text(
                                    'Error occured while connecting'),
                                content: Text("${e.toString()}"),
                                actions: <Widget>[
                                  new TextButton(
                                    child: new Text("Close"),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        }
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

  ListView _buildView() {
    return _buildListViewOfDevices();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: isScanning
              ? const Text("Scanning for Devices")
              : const Text("Bluetooth Devices"),
          actions: <Widget>[
            isScanning
                ? FittedBox(
                    child: Container(
                      margin: new EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.replay),
                    onPressed: _restartScanning,
                  )
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _restartScanning,
          child: _buildView(),
        ),
      );
}
