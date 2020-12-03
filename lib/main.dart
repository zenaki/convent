import 'dart:async';
import 'dart:typed_data';
import 'dart:core';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// import 'package:flutter/services.dart';
// import 'package:flutter_scan_bluetooth/flutter_scan_bluetooth.dart' as fsBlue;

import './DiscoveryPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Convent v2',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(titles: 'Convent v2'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.titles}) : super(key: key);
  final String titles;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Initializing the Bluetooth connection state to be unknown
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  // Get the instance of the Bluetooth
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  // Track the Bluetooth connection with the remote device
  BluetoothConnection connection;

  // To track whether the device is still connected to Bluetooth
  bool get isConnected => connection != null && connection.isConnected;

  // This member variable will be used for tracking
  // the Bluetooth device connection state
  int _deviceState;

  // String _data = '';
  // bool _scanning = false;
  // fsBlue.FlutterScanBluetooth _scanBluetooth = fsBlue.FlutterScanBluetooth();

  @override
  void initState() {
    super.initState();

    timer =
        Timer.periodic(const Duration(milliseconds: 100), _updateDataSource);

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    _deviceState = 0; // neutral

    // If the Bluetooth of the device is not enabled,
    // then request permission to turn on Bluetooth
    // as the app starts up
    enableBluetooth();

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // For retrieving the paired devices list
        getPairedDevices();
      });
    });

    // _scanBluetooth.devices.listen((device) {
    //   print("-------------------------Get Device-------------------------");
    //   print("Device Name: ${device.name}, Address: ${device.address}");
    //   setState(() {
    //     _data += device.name + ' (${device.address})\n';
    //   });
    // });
    // _scanBluetooth.scanStopped.listen((device) {
    //   setState(() {
    //     _scanning = false;
    //     _data += 'scan stopped\n';
    //   });
    // });
  }

  Timer timer;
  List<_ChartData> chartData = <_ChartData>[
    _ChartData(0, 0),
    _ChartData(1, 0),
    _ChartData(2, 0),
    _ChartData(3, 0),
    _ChartData(4, 0),
    _ChartData(5, 0),
    _ChartData(6, 0),
    _ChartData(7, 0),
    _ChartData(8, 0),
    _ChartData(9, 0),
    _ChartData(10, 0),
    _ChartData(11, 0),
    _ChartData(12, 0),
    _ChartData(13, 0),
    _ChartData(14, 0),
    _ChartData(15, 0),
    _ChartData(16, 0),
    _ChartData(17, 0),
    _ChartData(18, 0),
  ];
  int count = 19;
  ChartSeriesController _chartSeriesController;

  Future<void> enableBluetooth() async {
    // Retrieving the current Bluetooth state
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    // If the Bluetooth is off, then turn it on first
    // and then retrieve the devices that are paired.
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  // Define a new class member variable
  // for storing the devices list
  List<BluetoothDevice> _devicesList = [];

  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];

    // To get the list of paired devices
    try {
      devices = await _bluetooth.getBondedDevices();
    } catch (err) {
      print("Error");
      print(err);
    }

    // It is an error to call [setState] unless [mounted] is true.
    if (!mounted) {
      return;
    }

    // Store the [devices] list in the [_devicesList] for accessing
    // the list outside this class
    setState(() {
      _devicesList = devices;
    });
  }

  // Define a member variable to track
  // when the disconnection is in progress
  bool isDisconnecting = false;

  @override
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }
    timer?.cancel();
    super.dispose();
  }

  // Define this member variable for storing
  // the current device connectivity status
  bool _connected = false;

  // Define this member variable for storing
  // each device from the dropdown items
  BluetoothDevice _device;

  void _connect() async {
    if (_device == null) {
      print('No device selected');
    } else {
      // Trying to connect to the device using
      // its address
      await BluetoothConnection.toAddress(_device.address).then((_connection) {
        print('Connected to the device');
        connection = _connection;

        // Updating the device connectivity
        // status to [true]
        setState(() {
          _connected = true;
        });

        // This is for tracking when the disconnecting process
        // is in progress which uses the [isDisconnecting] variable
        // defined before.
        // Whenever we make a disconnection call, this [onDone]
        // method is fired.
        connection.input.listen(_onDataReceived).onDone(() {
          if (isDisconnecting) {
            print('Disconnecting locally!');
          } else {
            print('Disconnected remotely!');
          }
          if (this.mounted) {
            setState(() {});
          }
        });
      }).catchError((error) {
        print('Cannot connect, exception occurred');
        print(error);
      });
      print('Device connected');
    }
  }

  void _disconnect() async {
    // Closing the Bluetooth connection
    await connection.close();
    print('Device disconnected');

    // Update the [_connected] variable
    if (!connection.isConnected) {
      setState(() {
        _connected = false;
      });
    }
  }

  String fullData = "";
  bool dataComplete = false;

  String v_no_unit = "0",
      v_cmH2O_maks = "0",
      v_cmH2O_min = "0",
      v_cmH2O_now = "0",
      v_BPM = "0",
      v_E_ratio = "0";

  List<double> traceX = List();

  void _onDataReceived(Uint8List data) {
    data.forEach((byte) {
      // print("-----");
      // print("byte");
      // print(byte);
      // print("StringByte");
      // print(String.fromCharCode(byte));
      // print("-----");
      if (byte == 13 || byte == 10) {
        if (fullData != "") {
          // print("fullData");
          // print(fullData);

          String val_no_unit = fullData.substring(0, 1);
          String val_cmH2O_maks = fullData.substring(1, 3);
          String val_cmH2O_min = fullData.substring(3, 5);
          String val_cmH2O_now = fullData.substring(5, 7);
          String val_BPM = fullData.substring(7, 8);
          String val_E_ratio = fullData.substring(8, 9);

          setState(() {
            v_no_unit = val_no_unit;
            v_cmH2O_maks = val_cmH2O_maks;
            v_cmH2O_min = val_cmH2O_min;
            v_cmH2O_now = val_cmH2O_now;
            v_BPM = val_BPM;
            v_E_ratio = val_E_ratio;
            traceX.add(double.parse(val_cmH2O_now));
          });

          print(
              "no_unit = $val_no_unit, cmH2O_maks = $val_cmH2O_maks, cmH2O_min = $val_cmH2O_min, cmH2O_now = $val_cmH2O_now, BPM = $val_BPM, E_ratio = $val_E_ratio");
        }
        dataComplete = true;
        fullData = "";
      } else {
        fullData = fullData + String.fromCharCode(byte);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.titles),
        ),
        body: Column(
          children: [
            Flexible(
              flex: 3,
              fit: FlexFit.tight,
              // fit: FlexFit.loose,
              child: Container(
                // color: Colors.indigo,
                child: Column(
                  children: <Widget>[
                    // Padding(
                    //   padding: EdgeInsets.only(top: 10.0, bottom: 5.0),
                    //   child: Text(
                    //     'Convent v2',
                    //     style: TextStyle(
                    //       fontWeight: FontWeight.bold,
                    //       fontSize: 18,
                    //     ),
                    //   ),
                    // ),
                    // Divider(),
                    Expanded(
                        flex: 2,
                        child: Container(
                          // decoration: BoxDecoration(
                          //     border: Border.all(color: Colors.red[500]),
                          //     borderRadius:
                          //         BorderRadius.all(Radius.circular(20))),
                          margin: EdgeInsets.all(5),
                          child: GridView.count(
                            crossAxisCount: 3,
                            crossAxisSpacing: 1,
                            mainAxisSpacing: 1,
                            children: <Widget>[
                              buildCard(
                                  value: v_no_unit,
                                  label1: "No. Unit",
                                  label2: "",
                                  color: Colors.lightBlueAccent,
                                  size: 50),
                              buildCard(
                                  value: int.parse(v_BPM) < 10
                                      ? "0" + v_BPM
                                      : v_BPM,
                                  label1: "BPM",
                                  label2: "",
                                  color: Colors.lightBlueAccent,
                                  size: 50),
                              buildCard(
                                  value: "1:" + v_E_ratio,
                                  label1: "E. Ratio",
                                  label2: "",
                                  color: Colors.lightBlueAccent,
                                  size: 50),
                              buildCard(
                                  value: v_cmH2O_maks,
                                  label1: "cmH2O",
                                  label2: "(PIP)",
                                  color: Colors.lightBlueAccent,
                                  size: 50),
                              buildCard(
                                  value: v_cmH2O_now,
                                  label1: "cmH2O",
                                  label2: "(Now)",
                                  color: Colors.lightBlueAccent,
                                  size: 50),
                              buildCard(
                                  value: v_cmH2O_min,
                                  label1: "cmH2O",
                                  label2: "(PEEP)",
                                  color: Colors.lightBlueAccent,
                                  size: 50),
                            ],
                          ),
                        ))
                  ],
                ),
              ),
            ),
            Flexible(
              flex: 3,
              child: Container(
                child: SfCartesianChart(
                  plotAreaBorderWidth: 0,
                  primaryXAxis: NumericAxis(
                    majorGridLines: MajorGridLines(
                      width: 0,
                    ),
                  ),
                  // primaryXAxis: DateTimeAxis(
                  //   intervalType: DateTimeIntervalType.seconds,
                  //   interval: 1,
                  // ),
                  primaryYAxis: NumericAxis(
                      axisLine: AxisLine(width: 0),
                      majorTickLines: MajorTickLines(size: 0)),
                  series: <SplineSeries<_ChartData, int>>[
                    SplineSeries<_ChartData, int>(
                      onRendererCreated: (ChartSeriesController controller) {
                        _chartSeriesController = controller;
                      },
                      dataSource: chartData,
                      color: const Color.fromRGBO(192, 108, 132, 1),
                      xValueMapper: (_ChartData data, _) => data.x,
                      yValueMapper: (_ChartData data, _) => data.y,
                      animationDuration: 0,
                    ),
                  ],
                ),
              ),
            ),
            Flexible(flex: 1, child: Container(color: Colors.white)),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // SwitchListTile(
                      //     value: _bluetoothState.isEnabled,
                      //     title: const Text('Enable Bluetooth'),
                      //     onChanged: (bool value) {
                      //       // Do the request and update with the true value then
                      //       future() async {
                      //         if (value)
                      //           await FlutterBluetoothSerial.instance
                      //               .requestEnable();
                      //         else
                      //           await FlutterBluetoothSerial.instance
                      //               .requestDisable();

                      //         // In order to update the devices list
                      //         await getPairedDevices();

                      //         // Disconnect from any device before
                      //         // turning off Bluetooth
                      //         if (_connected) {
                      //           _disconnect();
                      //         }
                      //       }

                      //       future().then((_) {
                      //         setState(() {});
                      //       });
                      //     }),
                      ListTile(
                        title: RaisedButton(
                            child: _bluetoothState.isEnabled
                                ? Text('Disable Bluetooth')
                                : Text('Enable Bluetooth'),
                            onPressed: () async {
                              // Do the request and update with the true value then
                              future() async {
                                if (!_bluetoothState.isEnabled)
                                  await FlutterBluetoothSerial.instance
                                      .requestEnable();
                                else
                                  await FlutterBluetoothSerial.instance
                                      .requestDisable();

                                // In order to update the devices list
                                await getPairedDevices();

                                // Disconnect from any device before
                                // turning off Bluetooth
                                if (_connected) {
                                  _disconnect();
                                }
                              }

                              future().then((_) {
                                setState(() {});
                              });
                              Navigator.pop(context);
                            }),
                      ),
                      ListTile(
                        title: RaisedButton(
                            child: const Text('Explore discovered devices'),
                            onPressed: () async {
                              // try {
                              //   if (_scanning) {
                              //     await _scanBluetooth.stopScan();
                              //     debugPrint("scanning stoped");
                              //     setState(() {
                              //       _data = '';
                              //     });
                              //   } else {
                              //     print(
                              //         "-------------------------Start Scan-------------------------");
                              //     await _scanBluetooth.startScan(
                              //         pairedDevices: false);
                              //     debugPrint("scanning started");
                              //     setState(() {
                              //       _scanning = true;
                              //     });
                              //   }
                              // } on PlatformException catch (e) {
                              //   debugPrint(e.toString());
                              // }

                              BluetoothDevice selectedDevice =
                                  await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) {
                                    return DiscoveryPage();
                                  },
                                ),
                              );

                              // // print("selectedDevice");
                              // // print(selectedDevice);

                              // // selectedDevice =
                              // //     BluetoothDevice(address: "98:D3:11:FC:34:A1");

                              if (selectedDevice != null) {
                                print('Discovery -> selected ' +
                                    selectedDevice.address);
                                _device = selectedDevice;
                                _connect();
                              } else {
                                print('Discovery -> no device selected');
                              }
                              Navigator.pop(context);
                            }),
                      ),
                    ],
                  );
                });
          },
          child: Icon(Icons.bluetooth),
        ));
  }

  ///Continously updating the data source based on timer
  void _updateDataSource(Timer timer) {
    // chartData.add(_ChartData(count, _getRandomInt(10, 100)));
    chartData.add(_ChartData(count, int.parse(v_cmH2O_now)));
    if (chartData.length == 20) {
      chartData.removeAt(0);
      _chartSeriesController.updateDataSource(
        addedDataIndexes: <int>[chartData.length - 1],
        removedDataIndexes: <int>[0],
      );
    } else {
      _chartSeriesController.updateDataSource(
        addedDataIndexes: <int>[chartData.length - 1],
      );
    }
    count = count + 1;
  }

  ///Get the random data
  num _getRandomInt(num min, num max) {
    final math.Random _random = math.Random();
    return min + _random.nextInt(max - min);
  }
}

class buildCard extends StatelessWidget {
  final String value;
  final String label1;
  final String label2;
  final Color color;
  final int size;

  buildCard(
      {@required this.value,
      @required this.label1,
      @required this.label2,
      @required this.color,
      @required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      child: Card(
        semanticContainer: true,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        // elevation: 5,
        // margin: EdgeInsets.all(5),
        color: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              value,
              style: TextStyle(
                fontSize: size.toDouble(),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label1,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              label2,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            )
          ],
        ),
      ),
    );
  }
}

/// Private calss for storing the chart series data points.
class _ChartData {
  _ChartData(this.x, this.y);
  final num x;
  final num y;
}
