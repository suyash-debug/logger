import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import './BackgroundCollectingTask.dart';
import './ChatPage.dart';
import './DiscoveryPage.dart';
import './SelectBondedDevicePage.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<MainPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _address = "...";
  String _name = "...";

  Timer? _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  BackgroundCollectingTask? _collectingTask;

  bool _autoAcceptPairingRequests = false;

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if ((await FlutterBluetoothSerial.instance.isEnabled) ?? false) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address!;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name!;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _collectingTask?.dispose();
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hyper Vision',
        ),
        backgroundColor: const Color(0xff764abc),
      ),
      drawer: Drawer(
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              // <-- SEE HERE
              decoration: BoxDecoration(color: const Color(0xff764abc)),
              accountName: Text(
                "Naxatra Labs",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                "suyash@naxatralabs.com",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              currentAccountPicture: FlutterLogo(),
            ),
            SwitchListTile(
              title: const Text('Enable Bluetooth'),
              value: _bluetoothState.isEnabled,
              onChanged: (bool value) {
                // Do the request and update with the true value then
                future() async {
                  // async lambda seems to not working
                  if (value)
                    await FlutterBluetoothSerial.instance.requestEnable();
                  else
                    await FlutterBluetoothSerial.instance.requestDisable();
                }

                future().then((_) {
                  setState(() {});
                });
              },
            ),
            ListTile(
              leading: Icon(
                Icons.bluetooth,
              ),
              title: const Text('Open Bluetooth Settings'),
              onTap: () {
                FlutterBluetoothSerial.instance.openSettings();
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(
                Icons.travel_explore,
              ),
              title: const Text('Explore discovered devices'),
              onTap: () async {
                final BluetoothDevice? selectedDevice =
                    await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return DiscoveryPage();
                    },
                  ),
                );

                if (selectedDevice != null) {
                  print('Discovery -> selected ' + selectedDevice.address);
                } else {
                  print('Discovery -> no device selected');
                }
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(
                Icons.bluetooth_connected,
              ),
              title: const Text('Connect to paired devices'),
              onTap: () async {
                final BluetoothDevice? selectedDevice =
                    await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return SelectBondedDevicePage(checkAvailability: false);
                    },
                  ),
                );

                if (selectedDevice != null) {
                  print('Connect -> selected ' + selectedDevice.address);
                  _startChat(context, selectedDevice);
                } else {
                  print('Connect -> no device selected');
                }
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          child: Stack(
            children: [
              Column(
                children: [
                  Divider(),
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 2.7,
                    width: MediaQuery.of(context).size.width,
                    child: Container(
                        child: SfRadialGauge(
                      title: GaugeTitle(
                        text: "Rpm",
                      ),
                      axes: <RadialAxis>[
                        RadialAxis(
                            minimum: 0,
                            maximum: 150,
                            ranges: <GaugeRange>[
                              GaugeRange(
                                  startValue: 0,
                                  endValue: 50,
                                  color: Colors.green),
                              GaugeRange(
                                  startValue: 50,
                                  endValue: 100,
                                  color: Colors.orange),
                              GaugeRange(
                                  startValue: 100,
                                  endValue: 150,
                                  color: Colors.red)
                            ],
                            pointers: <GaugePointer>[
                              NeedlePointer(value: 90)
                            ],
                            annotations: <GaugeAnnotation>[
                              GaugeAnnotation(
                                  widget: Container(
                                      child: Text('90.0',
                                          style: TextStyle(
                                              fontSize: 25,
                                              fontWeight: FontWeight.bold))),
                                  angle: 90,
                                  positionFactor: 0.5),
                            ]),
                      ],
                    )),
                  ),
                  Divider(),
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 2.7,
                    width: MediaQuery.of(context).size.width,
                    child: Container(
                        child: SfRadialGauge(
                      title: GaugeTitle(
                        text: "Voltage",
                      ),
                      axes: <RadialAxis>[
                        RadialAxis(
                            minimum: 0,
                            maximum: 150,
                            ranges: <GaugeRange>[
                              GaugeRange(
                                  startValue: 0,
                                  endValue: 50,
                                  color: Colors.green),
                              GaugeRange(
                                  startValue: 50,
                                  endValue: 100,
                                  color: Colors.orange),
                              GaugeRange(
                                  startValue: 100,
                                  endValue: 150,
                                  color: Colors.red)
                            ],
                            pointers: <GaugePointer>[
                              NeedlePointer(value: 90)
                            ],
                            annotations: <GaugeAnnotation>[
                              GaugeAnnotation(
                                  widget: Container(
                                      child: Text('90.0',
                                          style: TextStyle(
                                              fontSize: 25,
                                              fontWeight: FontWeight.bold))),
                                  angle: 90,
                                  positionFactor: 0.5),
                            ]),
                      ],
                    )),
                  ),
                ],
              ),
              Container(
                margin: EdgeInsets.only(top: 100, right: 280),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height / 1.5,
                  width: MediaQuery.of(context).size.width,
                  child: Center(
                    child: SfLinearGauge(
                      // labelPosition: LinearLabelPosition.outside,
                      markerPointers: [
                        LinearWidgetPointer(
                          value: 50,
                          position: LinearElementPosition.outside,
                          child: Container(
                            decoration: new BoxDecoration(
                              color: Colors.green.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "49",
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ],
                      barPointers: [
                        LinearBarPointer(
                            color: Colors.green,
                            thickness: 6,
                            value: 49,
                            animationDuration: 2000,
                            animationType: LinearAnimationType.bounceOut),
                      ],
                      // isAxisInversed: true,
                      isMirrored: true,
                      orientation: LinearGaugeOrientation.vertical,
                      ranges: [
                        //Applies linear gradient. The start and end values are 0 to 100 by default
                        LinearGaugeRange(
                          startWidth: 20,
                          midWidth: 5,
                          endWidth: 20,
                          // startWidth: 50,
                          shaderCallback: (bounds) => RadialGradient(
                            center: Alignment.topLeft,
                            radius: 5,
                            colors: [
                              // Colors.greenAccent,
                              Colors.red.shade700,
                              Colors.orange.shade600,
                            ],
                          ).createShader(bounds),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startChat(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ChatPage(server: server);
        },
      ),
    );
  }
}

class DrawTriangle extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.height, size.width);
    path.close();
    canvas.drawPath(path, Paint()..color = Colors.green);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
