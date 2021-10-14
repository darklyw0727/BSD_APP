import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import './bluetooth_page.dart';
import 'package:audioplayers/audioplayers.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

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

  //警示燈號
  bool front = false; //前方警示
  bool backRight = false; //右後警示
  bool backLeft = false; //左後警示

  //藍芽資料處理
  int dataIndex = 5; //資料片段指標
  String longitude = ''; //經度
  String latitude = ''; //緯度
  String mySpeed = ''; //速度

  //紅黑顏色變換
  Color changeColor(bool warning){
    if(warning == true){
      return Colors.red;
    }else{
      return Colors.black26;
    }
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      connection?.dispose();
      connection = null;
    }

    super.dispose();
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
              //中間
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
                Container( //外框
                  child: Container( //內框
                    child: Container( //文字
                      alignment: Alignment.center,
                      child: Text(mySpeed,style: TextStyle(
                        fontSize: 45,
                        fontWeight: FontWeight.bold,
                      ),),
                      width: 100,
                    ),
                    padding: EdgeInsets.all(40),
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
                        child: Text(longitude),
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
                        child: Text(latitude),
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

                      connection!.input!.listen(_printData).onDone(() {
                        // Example: Detect which side closed the connection
                        // There should be `isDisconnecting` flag to show are we are (locally)
                        // in middle of disconnecting process, should be set before calling
                        // `dispose`, `finish` or `close`, which all causes to disconnect.
                        // If we except the disconnection, `onDone` should be fired as result.
                        // If we didn't except this (no flag set), it means closing by remote.
                        /*if (isDisconnecting) {
                          print('Disconnecting locally!');
                        } else {
                          print('Disconnected remotely!');
                        }*/
                        if (this.mounted) {
                          setState(() {});
                        }
                      });
                    });
                  }else{
                    print('NoSelected !');
                  }
                },
              )
          ),
        ],
      ),
    );
  }

  void _printData(Uint8List data){
    //資料長度
    int countLong = 0;
    int countLat = 0;
    int countSpeed = 0;

    //確認資料長度
    data.forEach((byte) {
      //不計算換行鍵
      if(byte != 13){
        if(byte != 10){
          //切換資料段指標
          if(byte == 78 || byte == 83){ //N or S
            dataIndex = 0;
          }else if(byte == 69 || byte == 87){ //E or W
            dataIndex = 1;
          }else if(byte == 77){ //M
            dataIndex = 2;
          }

          //依指標登記資料長度(不計算字母)
          if(dataIndex == 0){
            if(byte != 78 && byte != 83){
              countLong ++;
            }
          }else if(dataIndex == 1){
            if(byte != 69 && byte != 87){
              countLat ++;
            }
          }else if(dataIndex == 2){
            if(byte != 77){
              countSpeed ++;
            }
          }
        }
      }
    });

    print(countLong);
    print(countLat);
    print(countSpeed);
    print('********' + dataIndex.toString() + '*************');

    //依照資料長度建立Buffer
    Uint8List longBuffer = Uint8List(countLong);
    Uint8List latBuffer = Uint8List(countLat);
    Uint8List speedBuffer = Uint8List(countSpeed);

    //由後至前檢查資料並填進Buffer
    for(int a = data.length-1 ; a >= 0 ; a--){
      //跳過換行鍵
      if(data[a] != 13){
        if(data[a] != 10){
          //依照指標與資料長度填入
          if(dataIndex == 2 && countSpeed > 0){
            speedBuffer[--countSpeed] = data[a];
          }else if(dataIndex == 1 && countLat > 0){
            latBuffer[--countLat] = data[a];
          }else if(dataIndex == 0 && countLong > 0){
            longBuffer[--countLong] = data[a];
          }

          //切換指標
          if(data[a] == 77){ //M
            dataIndex = 1;
          }else if(data[a] == 69 || data[a] == 87) { //E or W
            dataIndex = 0;
          }
        }
      }
    }

    //字串轉換
    setState(() {
      if(longBuffer.length > 1){
        longitude = String.fromCharCodes(longBuffer);
      }
      if(latBuffer.length > 1){
        latitude = String.fromCharCodes(latBuffer);
      }
      if(speedBuffer.length > 1){
        mySpeed = String.fromCharCodes(speedBuffer);
      }
    });

    print(longitude);
    print('------------' + longitude.length.toString());
    print(latitude);
    print('xxxxxxxxxxxxxxx' + latitude.length.toString());
    print(mySpeed);
    print('ooooooooooooooo' + mySpeed.length.toString());
  }
}