import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import './bluetooth_page.dart';
import './chat_page.dart';

class HomePage extends StatefulWidget {
  //const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  Timer? _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;
  BluetoothDevice? selectedDevice;
  BluetoothConnection? connection;
  bool get isConnected => (connection?.isConnected ?? false);

  Timer? _bluetoothTimer;
  bool timerStart = false;
  bool front = false; //前方警示
  bool backRight = false; //右後警示
  bool backLeft = false; //左後警示

  //紅黑顏色變換
  Color changeColor(bool warning){
    if(warning == true){
      return Colors.red;
    }else{
      return Colors.black26;
    }
  }

  void bluetoothTimer(){
    _bluetoothTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if(timerStart){
        print('0.1sec');
        setState(() {

        });
      }
    });
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      body:Stack(
        alignment: Alignment.center,
        children: [
          //背景
          Column(
            children: [
              //上方
              Flexible(
                  flex:2,
                  child:Container(
                    color:changeColor(front),
                  )
              ),
              SizedBox(
                height: 20,
                width: 1000,
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.black, Colors.blue, Colors.blue, Colors.blue, Colors.black])
                  ),
                ),
              ),
              //下方
              Flexible(
                  flex:5,
                  child:Row(
                    children: [
                      //左
                      Flexible(
                          flex:1,
                          child:Container(
                            color:changeColor(backLeft),
                          )
                      ),
                      SizedBox(
                        height: 1000,
                        width: 20,
                        child: Container(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  colors: [Colors.blue, Colors.blue, Colors.black]
                              )
                          ),
                        ),
                      ),
                      //右
                      Flexible(
                          flex:1,
                          child:Container(
                            color:changeColor(backRight),
                          )
                      ),
                    ],
                  )
              ),
            ],
          ),
          //速度 & 座標
          Positioned(
            top: 150,
            child: Column(
              children: [
                //速度
                Container(
                  child: Container(
                    child: isConnected
                        ?Text('Speed'):Text('fail'),
                    padding: EdgeInsets.all(55),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueAccent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 10),
                        blurRadius: 10,
                      )
                    ],
                  ),
                ),
                //經度
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: Row(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        width: 100,
                        height: 50,
                        child: Text('Longitude:'),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        width: 100,
                        height: 50,
                        child: selectedDevice == null
                          ?Text('null'):Text(selectedDevice!.name.toString()),
                      ),
                    ],
                  ),
                ),
                //緯度
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: Row(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        width: 100,
                        height: 50,
                        child: Text('Latitude:'),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        width: 100,
                        height: 50,
                        child: Text('null'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          //左下按鈕
          Positioned(
            bottom: 10,
            left: 10,
            child: FloatingActionButton(
              onPressed: (){
                setState((){
                  backLeft = !backLeft;
                });
              },
              child: const Icon(Icons.keyboard_arrow_left),
            ),
          ),
          //右下按鈕
          Positioned(
            bottom: 10,
            right: 10,
            child: FloatingActionButton(
              onPressed: (){
                setState((){
                  backRight = !backRight;
                });
              },
              child: const Icon(Icons.keyboard_arrow_right),
            ),
          ),
          //上方按鈕
          Positioned(
            top: 50,
            child: FloatingActionButton(
              onPressed: (){
                setState((){
                  front = !front;
                });
              },
              child: const Icon(Icons.keyboard_arrow_up),
            ),
          ),
          //藍芽按鈕
          Positioned(
              top: 50,
              right:10,
              child: FloatingActionButton(
                child: Icon(Icons.bluetooth),
                onPressed: ()async{
                  selectedDevice =
                  await Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) {return BluetoothPage(checkAvailability: false,);})
                  );

                  if(selectedDevice != null){
                    print('Select : ' + selectedDevice!.address);
                    /*Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) {return ChatPage(server: selectedDevice!);},),
                    );*/
                    BluetoothConnection.toAddress(selectedDevice!.address).then((_connection){
                      print('Connected to the device');
                      connection = _connection;
                      setState(() {
                      });
                    });
                    bluetoothTimer();
                  }else{
                    print('NoSelected !');
                    //bluetoothTimer();
                    if(_bluetoothTimer != null){
                      _bluetoothTimer!.cancel();
                    }
                  }
                },
              )
          ),
        ],
      ),
    );
  }
}