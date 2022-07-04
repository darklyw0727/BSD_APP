import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:audioplayers/audioplayers.dart';

import './bluetooth_page.dart';

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

  //警示燈號(按鈕)
  bool s1Button = false; //前方警示
  bool s01Button = false; //右後警示
  bool s05Button = false; //左後警示
  //警示燈號
  bool frontBackground = false; //前方警示
  bool rightBackground = false; //右後警示
  bool leftBackground = false; //左後警示

  //藍芽傳送警示
  int bsdWarningL = 0;
  int bsdWarningR = 0;
  bool casWarning = false;
  bool sysRunLight = false;

  //藍芽資料處理
  //region
  int dataIndex = 0; //資料片段指標
  var emaBufferL = []; //emaL
  bool emaDoneL = false;
  bool emaToStringL = false;
  String emaL = '';
  var emaBufferR = []; //emaR
  bool emaDoneR = false;
  bool emaToStringR = false;
  String emaR = '';
  var emaBufferF = []; //emaF
  bool emaDoneF = false;
  bool emaToStringF = false;
  String emaF = '';
  var btWarningBuffer = []; //bsd+ema warning
  bool btWarningDone = false;
  bool btWarningToStatus = false;
  String btWarning = '';
  var respBufferB = []; //bsd radar resp
  bool respDoneB = false;
  bool respToStringB = false;
  String respB = '';
  var radarDBufferB = []; //bsd radar distance
  bool radarDDoneB = false;
  bool radarDToStringB = false;
  String radarDB = '';
  var radarSBufferB = []; //bsd radar speed
  bool radarSDoneB = false;
  bool radarSToStringB = false;
  String radarSB = '';
  var radarABufferB = []; //bsd radar angle
  bool radarADoneB = false;
  bool radarAToStringB = false;
  String radarAB = '';
  var radarTBufferB = []; //bsd radar target size
  bool radarTDoneB = false;
  bool radarTToStringB = false;
  String radarTB = '';
  var pastEmaBufferL = []; //past emaL
  bool pastEmaDoneL = false;
  bool pastEmaToStringL = false;
  String pastEmaL = '';
  var pastEmaBufferR = []; //past emaR
  bool pastEmaDoneR = false;
  bool pastEmaToStringR = false;
  String pastEmaR = '';
  var tLBuffer = []; //tL
  bool tLDone = false;
  bool tLToString = false;
  String tL = '';
  var tRBuffer = []; //tR
  bool tRDone = false;
  bool tRToString = false;
  String tR = '';
  var respBufferF = []; //cas radar resp
  bool respDoneF = false;
  bool respToStringF = false;
  String respF = '';
  var radarDBufferF = []; //cas radar distance
  bool radarDDoneF = false;
  bool radarDToStringF = false;
  String radarDF = '';
  var radarSBufferF = []; //cas radar speed
  bool radarSDoneF = false;
  bool radarSToStringF = false;
  String radarSF = '';
  var radarABufferF = []; //cas radar angle
  bool radarADoneF = false;
  bool radarAToStringF = false;
  String radarAF = '';
  var radarTBufferF = []; //cas radar target size
  bool radarTDoneF = false;
  bool radarTToStringF = false;
  String radarTF = '';
  var pastEmaBufferF = []; //past emaF
  bool pastEmaDoneF = false;
  bool pastEmaToStringF = false;
  String pastEmaF = '';
  var tFBuffer = []; //tF
  bool tFDone = false;
  bool tFToString = false;
  String tF = '';
  var mySpeedBuffer = []; //速度
  bool mySpeedDone = false;
  bool mySpeedToString = false;
  String mySpeed = '';
  var longBuffer = []; //經度
  bool longDone = false;
  bool longToString = false;
  String longitude = '';
  var latBuffer = []; //緯度
  bool latDone = false;
  bool latToString = false;
  String latitude = '';
  //endregion

  //紅黑顏色變換
  Color changeColor(bool warning){
    if(warning == true){
      return Colors.red;
    }else{
      return Colors.black26;
    }
  }

  Color sysRunColor(bool warning){
    if(warning == true){
      return Colors.blueAccent;
    }else{
      return Colors.grey;
    }
  }

  //音源撥放
  AudioPlayer audioPlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
  AudioCache audioCache = AudioCache();

  @override
  void initState(){
    super.initState();

    audioCache.load('BSD_alarm_1.wav');

    //1 second timer
    Timer.periodic(Duration(milliseconds: 1000), (timer) {
      /*if(s1Button){
        setState(() {
          front = !front;
        });
      }
      if(front == true) audioCache.play('BSD_alarm_1.wav', mode: PlayerMode.LOW_LATENCY);*/
    });

    //0.5 second timer
    Timer.periodic(Duration(milliseconds: 500), (timer) {
      if((bsdWarningR==1)||(bsdWarningL==1)) audioCache.play('BSD_alarm.wav', mode: PlayerMode.LOW_LATENCY);

      if(bsdWarningL == 1){
        setState(() {
          leftBackground = !leftBackground;
        });
      }else if(bsdWarningL == 0){
        setState(() {
          leftBackground = false;
        });
      }
      if(bsdWarningR == 1){
        setState(() {
          rightBackground = !rightBackground;
        });
      }else if(bsdWarningR == 0){
        setState(() {
          rightBackground = false;
        });
      }

      /*if(s05Button){
        setState(() {
          left = !left;
        });
      }
      if(left == true) audioCache.play('BSD_alarm.wav', mode: PlayerMode.LOW_LATENCY);*/
    });

    //0.1 second timer
    Timer.periodic(Duration(milliseconds: 200), (timer) {
      if((casWarning==true)||(bsdWarningL==2)||(bsdWarningR==2)) audioCache.play('BSD_alarm.wav', mode: PlayerMode.LOW_LATENCY);

      if(casWarning){
        setState(() {
          frontBackground = !frontBackground;
        });
      }else{
        setState(() {
          frontBackground = false;
        });
      }
      if(bsdWarningL == 2){
        setState(() {
          leftBackground = !leftBackground;
        });
      }else if(bsdWarningL == 0){
        setState(() {
          leftBackground = false;
        });
      }
      if(bsdWarningR == 2){
        setState(() {
          rightBackground = !rightBackground;
        });
      }else if(bsdWarningR == 0){
        setState(() {
          rightBackground = false;
        });
      }

      /*if(s01Button){
        setState(() {
          right = !right;
        });
      }
      if(right == true) audioCache.play('BSD_alarm.wav', mode: PlayerMode.LOW_LATENCY);*/
    });
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
        //fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          //背景
          Column(
            children: [
              //上方
              Flexible(
                  flex:4,
                  child:Container(
                    color:changeColor(frontBackground),
                  )
              ),
              //中間
              SizedBox(
                height: 20,
                //width: 200,
                child: Container(
                  color: Colors.black,
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
                            color:changeColor(leftBackground),
                          )
                      ),
                      SizedBox(
                        //height: 1000,
                        width: 20,
                        child: Container(
                          color: Colors.black,
                        ),
                      ),
                      //右
                      Flexible(
                          flex:1,
                          child:Container(
                            color:changeColor(rightBackground),
                          )
                      ),
                    ],
                  )
              ),
            ],
          ),
          //速度 & 座標
          Positioned(
            top: 300,
            child: Column(
              children: [
                //速度
                Container( //外框
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 10),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Container( //內框
                    padding: EdgeInsets.all(40),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Container( //文字
                      alignment: Alignment.center,
                      width: 100,
                      child: Text(/*mySpeed*/'38.075',style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),),
                    ),
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
                        child: Text(/*longitude*/'2342.19442'),
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
                        child: Text(/*latitude*/'12025.82153'),
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
            child: FloatingActionButton.extended(
              onPressed: (){
                setState((){
                  s05Button = !s05Button;
                  if(leftBackground == true) leftBackground = false;
                });
              },
              label: Container( //文字
                alignment: Alignment.center,
                width: 130,
                child: Text(emaL,style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),),
              ),
            ),
          ),
          //右下按鈕
          Positioned(
            bottom: 10,
            right: 10,
            child: FloatingActionButton.extended(
              onPressed: (){
                setState((){
                  s01Button = !s01Button;
                  if(rightBackground == true) rightBackground = false;
                });
              },
              label: Container( //文字
                alignment: Alignment.center,
                width: 130,
                child: Text(emaR,style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),),
              ),
            ),
          ),
          //上方按鈕
          Positioned(
            top: 50,
            child: FloatingActionButton.extended(
              onPressed: (){
                //audioCache.play('BSD_alarm.wav');
                setState((){
                  s1Button = !s1Button;
                  if(frontBackground == true) frontBackground = false;
                });
              },
              label: Container( //文字
                alignment: Alignment.center,
                width: 130,
                child: Text(emaF,style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),),
              ),
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
          Positioned(
              top: 120,
              right: 20,
              child: Container(
                alignment: Alignment.center,
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: sysRunColor(sysRunLight)
                  ,
                  shape: BoxShape.circle,
                ),

              )
          ),
          //CAS其餘資訊
          Positioned(
            top:100,
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 2),
                  alignment: Alignment.center,
                  width:170,
                  decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.all(Radius.circular(50))
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                      ),
                      Container(
                        width: 30,
                        child: Text('P: ',style: TextStyle(
                          fontSize: 30,
                        ),),
                      ),
                      Container(
                        child: Text(pastEmaF,style: TextStyle(
                          fontSize: 30,
                        ),),
                      )
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 2),
                  alignment: Alignment.center,
                  width:170,
                  decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      borderRadius: BorderRadius.all(Radius.circular(50))
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                      ),
                      Container(
                        width: 30,
                        child: Text('D: ',style: TextStyle(
                          fontSize: 30,
                          color:Colors.white,
                        ),),
                      ),
                      Container(
                        child: Text(radarDF,style: TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                        ),),
                      )
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  alignment: Alignment.center,
                  width:170,
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent,
                    borderRadius: BorderRadius.all(Radius.circular(50))
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                      ),
                      Container(
                        width: 30,
                        child: Text('S: ',style: TextStyle(
                          fontSize: 30,
                          color:Colors.white,
                        ),),
                      ),
                      Container(
                        child: Text(radarSF,style: TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                        ),),
                      )
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 2),
                  alignment: Alignment.center,
                  width:170,
                  decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      borderRadius: BorderRadius.all(Radius.circular(50))
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                      ),
                      Container(
                        width: 30,
                        child: Text('A: ',style: TextStyle(
                          fontSize: 30,
                          color:Colors.white,
                        ),),
                      ),
                      Container(
                        child: Text(radarAF,style: TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                        ),),
                      )
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 2),
                  alignment: Alignment.center,
                  width:170,
                  decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      borderRadius: BorderRadius.all(Radius.circular(50))
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                      ),
                      Container(
                        width: 30,
                        child: Text('T: ',style: TextStyle(
                          fontSize: 30,
                          color:Colors.white,
                        ),),
                      ),
                      Container(
                        child: Text(radarTF,style: TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                        ),),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 110,
            left: 10,
            child: Container(
              alignment: Alignment.center,
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent,
              ),
              child: Text(respF,style: TextStyle(
                fontSize: 30,
                color: Colors.white,
              ),),
            ),
          ),
          //BSD其餘資訊
          Positioned(
            //width: 500,
            bottom: 102,
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 2),
                  alignment: Alignment.center,
                  width:170,
                  decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      borderRadius: BorderRadius.all(Radius.circular(50))
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                      ),
                      Container(
                        width: 30,
                        child: Text('D: ',style: TextStyle(
                          fontSize: 30,
                          color:Colors.white,
                        ),),
                      ),
                      Container(
                        child: Text(radarDB,style: TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                        ),),
                      )
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 2),
                  alignment: Alignment.center,
                  width:170,
                  decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      borderRadius: BorderRadius.all(Radius.circular(50))
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                      ),
                      Container(
                        width: 30,
                        child: Text('S: ',style: TextStyle(
                          fontSize: 30,
                          color:Colors.white,
                        ),),
                      ),
                      Container(
                        child: Text(radarSB,style: TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                        ),),
                      )
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 2),
                  alignment: Alignment.center,
                  width:170,
                  decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      borderRadius: BorderRadius.all(Radius.circular(50))
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                      ),
                      Container(
                        width: 30,
                        child: Text('A: ',style: TextStyle(
                          fontSize: 30,
                          color:Colors.white,
                        ),),
                      ),
                      Container(
                        child: Text(radarAB,style: TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                        ),),
                      )
                    ],
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  width:170,
                  decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      borderRadius: BorderRadius.all(Radius.circular(50))
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                      ),
                      Container(
                        width: 30,
                        child: Text('T: ',style: TextStyle(
                          fontSize: 30,
                          color:Colors.white,
                        ),),
                      ),
                      Container(
                        child: Text(radarTB,style: TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                        ),),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
              bottom: 60,
              left: 10,
              child: Container(
                alignment: Alignment.center,
                width: 170,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                    ),
                    Container(
                      width: 30,
                      child: Text('P: ',style: TextStyle(
                        fontSize: 30,
                      ),),
                    ),
                    Container(
                      child: Text(pastEmaL,style: TextStyle(
                        fontSize: 30,
                      ),),
                    )
                  ],
                ),
              )
          ),
          Positioned(
            bottom: 60,
            right: 10,
            child: Container(
              alignment: Alignment.center,
              width: 170,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.all(Radius.circular(50)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                  ),
                  Container(
                    width: 30,
                    child: Text('P: ',style: TextStyle(
                      fontSize: 30,
                    ),),
                  ),
                  Container(
                    child: Text(pastEmaR,style: TextStyle(
                      fontSize: 30,
                    ),),
                  )
                ],
              ),
            )
          ),
          Positioned(
            bottom: 165,
            left: 10,
            child: Container(
              alignment: Alignment.center,
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent,
              ),
              child: Text(respB,style: TextStyle(
                fontSize: 30,
                color: Colors.white,
              ),),
            ),
          ),
          //警示狀態
          Positioned(
              top: 50,
              left: 10,
              child: Container(
                alignment: Alignment.center,
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
                child: Text(casWarning?'1':'0',style: TextStyle(
                  fontSize: 30
              ),),
              )
          ),
          Positioned(
              bottom: 105,
              left: 10,
              child: Container(
                alignment: Alignment.center,
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
                child: Text(bsdWarningL.toString(),style: TextStyle(
                    fontSize: 30
                ),),
              )
          ),
          Positioned(
            bottom: 105,
            right: 10,
            child: Container(
              alignment: Alignment.center,
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              child: Text(bsdWarningR.toString(),style: TextStyle(
                  fontSize: 30
              ),),
            )
          ),
        ],
      ),
    );
  }

  void _printData(Uint8List data){
    //print(data);
    data.forEach((byte){
      //print(byte);
      //指標切換
      switch(byte){
        case 30:
          //初始化
          dataIndex = 0;
          print('-----Start, Index = ' + dataIndex.toString());
          _resetBTinfo();
          break;
        case 76: //L 左EMA
          dataIndex = 1;
          print('emaL, Index = ' + dataIndex.toString());
          break;
        case 82: //R 右EMA
          dataIndex = 2;
          print('emaR, Index = ' + dataIndex.toString());
          break;
        case 70: //F emaF
          dataIndex = 3;
          print('emaF, Index = ' + dataIndex.toString());
          break;
        case 90: //Z bsd+cas warning
          dataIndex = 4;
          print('Warning, Index = ' + dataIndex.toString());
          break;
        case 65: //A bsd radar resp
          dataIndex = 5;
          print('BSD RESP, Index = ' + dataIndex.toString());
          break;
        case 66: //B bsd radar distance
          dataIndex = 6;
          print('BSD radar distance, Index = ' + dataIndex.toString());
          break;
        case 67: //C bsd radar speed
          dataIndex = 7;
          print('BSD radar speed, Index = ' + dataIndex.toString());
          break;
        case 68: //D bsd radar angle
          dataIndex = 8;
          print('BSD radar angle, Index = ' + dataIndex.toString());
          break;
        case 71: //G bsd radar target
          dataIndex = 9;
          print('BSD radar target size, Index = ' + dataIndex.toString());
          break;
        case 72: //H past emaL
          dataIndex = 10;
          print('Past EMA L, Index = ' + dataIndex.toString());
          break;
        case 73: //I past emaR
          dataIndex = 11;
          print('Past EMA R, Index = ' + dataIndex.toString());
          break;
        case 74: //J tL
          dataIndex = 12;
          print('tL, Index = ' + dataIndex.toString());
          break;
        case 75: //K tR
          dataIndex = 13;
          print('tR, Index = ' + dataIndex.toString());
          break;
        case 97: //a cas radar resp
          dataIndex = 14;
          print('CAS radar RESP, Index = ' + dataIndex.toString());
          break;
        case 98: //b cas radar distance
          dataIndex = 15;
          print('CAS radar distance, Index = ' + dataIndex.toString());
          break;
        case 99: //c cas radar speed
          dataIndex = 16;
          print('CAS radar speed, Index = ' + dataIndex.toString());
          break;
        case 100: //d cas radar angle
          dataIndex = 17;
          print('CAS radar angle, Index = ' + dataIndex.toString());
          break;
        case 103: //g cas radar target size
          dataIndex = 18;
          print('CAS radar target, Index = ' + dataIndex.toString());
          break;
        case 104: //h past emaF
          dataIndex = 19;
          print('pastEmaF, Index = ' + dataIndex.toString());
          break;
        case 106: //j tF
          dataIndex = 20;
          print('tF, Index = ' + dataIndex.toString());
          break;
        case 78: //N GPS方位
          dataIndex = 21;
          print('Index = ' + dataIndex.toString());
          break;
        case 83: //S GPS方位
          dataIndex = 21;
          print('Longitude, Index = ' + dataIndex.toString());
          break;
        case 69: //E GPS方位
          dataIndex = 22;
          print('Latitude, Index = ' + dataIndex.toString());
          break;
        case 87: //W GPS方位
          dataIndex = 22;
          print('Latitude, Index = ' + dataIndex.toString());
          break;
        case 77: //M GPS速度
          dataIndex = 23;
          print('Speed, Index = ' + dataIndex.toString());
          break;
      }

      //buffer資料寫入
      switch(dataIndex){
        case 1:
          if(byte>=46 && byte<=57){ //資料為數字
            if(!emaDoneL) emaBufferL.add(byte); //資料加入buffer
          }else if(byte==13 || byte==10){ //換行鍵
            if(!emaDoneL){ //資料尚未接收完畢
              emaDoneL = true; //資料接收完畢
              print('emaBufferL = ' + emaBufferL.toString());
            }
          }
          break;
        case 2:
          if(byte>=46 && byte<=57){
            if(!emaDoneR) emaBufferR.add(byte);
          }else if(byte==13 || byte==10){
            if(!emaDoneR){
              emaDoneR = true;
              print('emaBufferR = ' + emaBufferR.toString());
            }
          }
          break;
        case 3:
          if(byte>=46 && byte<=57){
            if(!emaDoneF) emaBufferF.add(byte);
          }else if(byte==13 || byte==10){
            if(!emaDoneF){
              emaDoneF = true;
              print('emabufferF = ' + emaBufferF.toString());
            }
          }
          break;
        case 4:
          if(byte>=46 && byte<=57){
            if(!btWarningDone) btWarningBuffer.add(byte);
          }else if(byte==13 || byte==10){
            if(!btWarningDone){
              btWarningDone = true;
              print('btWarningBuffer = ' + btWarningBuffer.toString());
            }
          }
          break;
        case 5:
          if(byte>=46 && byte<=57){
            if(!respDoneB) respBufferB.add(byte);
          }else if(byte==13 || byte==10){
            if(!respDoneB){
              respDoneB = true;
              print('respBufferB = ' + respBufferB.toString());
            }
          }
          break;
        case 6:
          if(byte>=46 && byte<=57){
            if(!radarDDoneB) radarDBufferB.add(byte);
          }else if(byte==13 || byte==10){
            if(!radarDDoneB){
              radarDDoneB = true;
              print('radarDistanceBufferB = ' + radarDBufferB.toString());
            }
          }
          break;
        case 7:
          if(byte>=46 && byte<=57){
            if(!radarSDoneB) radarSBufferB.add(byte);
          }else if(byte==13 || byte==10){
            if(!radarSDoneB){
              radarSDoneB = true;
              print('radarSpeedBufferB = ' + radarSBufferB.toString());
            }
          }
          break;
        case 8:
          if(byte>=46 && byte<=57){
            if(!radarADoneB) radarABufferB.add(byte);
          }else if(byte==13 || byte==10){
            if(!radarADoneB){
              radarADoneB = true;
              print('radarAngleBufferB = ' + radarABufferB.toString());
            }
          }
          break;
        case 9:
          if(byte>=46 && byte<=57){
            if(!radarTDoneB) radarTBufferB.add(byte);
          }else if(byte==13 || byte==10){
            if(!radarTDoneB){
              radarTDoneB = true;
              print('radarTargetBufferB = ' + radarTBufferB.toString());
            }
          }
          break;
        case 10:
          if(byte>=46 && byte<=57){
            if(!pastEmaDoneL) pastEmaBufferL.add(byte);
          }else if(byte==13 || byte==10){
            if(!pastEmaDoneL){
              pastEmaDoneL = true;
              print('pastEmaBufferL = ' + pastEmaBufferL.toString());
            }
          }
          break;
        case 11:
          if(byte>=46 && byte<=57){
            if(!pastEmaDoneR) pastEmaBufferR.add(byte);
          }else if(byte==13 || byte==10){
            if(!pastEmaDoneR){
              pastEmaDoneR = true;
              print('pastEmaBufferR = ' + pastEmaBufferR.toString());
            }
          }
          break;
        case 12:
          if(byte>=46 && byte<=57){
            if(!tLDone) tLBuffer.add(byte);
          }else if(byte==13 || byte==10){
            if(!tLDone){
              tLDone = true;
              print('tLBuffer = ' + tLBuffer.toString());
            }
          }
          break;
        case 13:
          if(byte>=46 && byte<=57){
            if(!tRDone) tRBuffer.add(byte);
          }else if(byte==13 || byte==10){
            if(!tRDone){
              tRDone = true;
              print('tRBuffer = ' + tRBuffer.toString());
            }
          }
          break;
        case 14:
          if(byte>=46 && byte<=57){
            if(!respDoneF) respBufferF.add(byte);
          }else if(byte==13 || byte==10){
            if(!respDoneF){
              respDoneF = true;
              print('respBufferF = ' + respBufferF.toString());
            }
          }
          break;
        case 15:
          if(byte>=46 && byte<=57){
            if(!radarDDoneF) radarDBufferF.add(byte);
          }else if(byte==13 || byte==10){
            if(!radarDDoneF){
              radarDDoneF = true;
              print('radarDistanceBufferF = ' + radarDBufferF.toString());
            }
          }
          break;
        case 16:
          if(byte>=46 && byte<=57){
            if(!radarSDoneF) radarSBufferF.add(byte);
          }else if(byte==13 || byte==10){
            if(!radarSDoneF){
              radarSDoneF = true;
              print('radarSpeedBufferF = ' + radarSBufferF.toString());
            }
          }
          break;
        case 17:
          if(byte>=46 && byte<=57){
            if(!radarADoneF) radarABufferF.add(byte);
          }else if(byte==13 || byte==10){
            if(!radarADoneF){
              radarADoneF = true;
              print('radarAngleBufferF = ' + radarABufferF.toString());
            }
          }
          break;
        case 18:
          if(byte>=46 && byte<=57){
            if(!radarTDoneF) radarTBufferF.add(byte);
          }else if(byte==13 || byte==10){
            if(!radarTDoneF){
              radarTDoneF = true;
              print('radarTargetBufferF = ' + radarTBufferF.toString());
            }
          }
          break;
        case 19:
          if(byte>=46 && byte<=57){
            if(!pastEmaDoneF) pastEmaBufferF.add(byte);
          }else if(byte==13 || byte==10){
            if(!pastEmaDoneF){
              pastEmaDoneF = true;
              print('pastEmaBufferF = ' + pastEmaBufferF.toString());
            }
          }
          break;
        case 20:
          if(byte>=46 && byte<=57){
            if(!tFDone) tFBuffer.add(byte);
          }else if(byte==13 || byte==10){
            if(!tFDone){
              tFDone = true;
              print('tFBuffer = ' + tFBuffer.toString());
            }
          }
          break;
        case 21:
          if(byte>=46 && byte<=57){
            if(!longDone) longBuffer.add(byte);
          }else if(byte==13 || byte==10){
            if(!longDone){
              longDone = true;
              print('longBuffer = ' + longBuffer.toString());
            }
          }
          break;
        case 22:
          if(byte>=46 && byte<=57){
            if(!latDone) latBuffer.add(byte);
          }else if(byte==13 || byte==10){
            if(!latDone){
              latDone = true;
              print('latBuffer = ' + latBuffer.toString());
            }
          }
          break;
        case 23:
          if(byte>=46 && byte<=57){
            if(!mySpeedDone) mySpeedBuffer.add(byte);
          }else if(byte==13 || byte==10){
            if(!mySpeedDone){
              mySpeedDone = true;
              print('speedBuffer = ' + mySpeedBuffer.toString());
            }
          }
          break;
      }
    });

    //資料轉換
    if(emaDoneL && !emaToStringL){ //資料接收完成 且 尚未完成轉換
      Uint8List emaLL = Uint8List(emaBufferL.length); //依據buffer建立暫存
      //buffer資料存入暫存
      for(int i=0;i<emaBufferL.length;i++){
        emaLL[i] = emaBufferL[i];
      }
      emaToStringL = true; //資料轉換完成
      //print('*Uint8ListL = ' + radarLL.toString());
      setState(() { //更新頁面
        emaL = String.fromCharCodes(emaLL);
      });
      print('**emaL = ' + emaL + ' (' + emaLL.toString() + ')');
    }
    if(emaDoneR && !emaToStringR){
      Uint8List emaRR = Uint8List(emaBufferR.length);
      for(int i=0;i<emaBufferR.length;i++){
        emaRR[i] = emaBufferR[i];
      }
      emaToStringR = true;
      setState(() {
        emaR = String.fromCharCodes(emaRR);
      });
      print('**emaR = ' + emaR + ' (' + emaRR.toString() + ')');
    }
    if(emaDoneF && !emaToStringF){
      Uint8List emaFF = Uint8List(emaBufferF.length);
      for(int i=0;i<emaBufferF.length;i++){
        emaFF[i] = emaBufferF[i];
      }
      emaToStringF = true;
      setState(() {
        emaF = String.fromCharCodes(emaFF);
      });
      print('**emaF = ' + emaF + ' (' + emaFF.toString() + ')');
    }
    if(btWarningDone && !btWarningToStatus){
      setState(() {
        sysRunLight = btWarningBuffer[0]==49?true:false; //運行指示燈
        bsdWarningL = btWarningBuffer[1]==50?2:btWarningBuffer[0]==49?1:0;
        bsdWarningR = btWarningBuffer[2]==50?2:btWarningBuffer[1]==49?1:0;
        casWarning = btWarningBuffer[3]==49?true:false;
      });
      print('**Warning = ' + bsdWarningL.toString() + '/' + bsdWarningR.toString() + '/' + casWarning.toString() + '(' + btWarningBuffer[0].toString() + '/' + btWarningBuffer[1].toString() + '/' + btWarningBuffer[2].toString() + ')');
    }
    if(respDoneB && !respToStringB){
      Uint8List respBB = Uint8List(respBufferB.length);
      for(int i=0;i<respBufferB.length;i++){
        respBB[i] = respBufferB[i];
      }
      respToStringB = true;
      setState(() {
        respB = String.fromCharCodes(respBB);
      });
      print('**respB = ' + respB + ' (' + respBB.toString() + ')');
    }
    if(radarDDoneB && !radarDToStringB){
      Uint8List radarDBB = Uint8List(radarDBufferB.length);
      for(int i=0;i<radarDBufferB.length;i++){
        radarDBB[i] = radarDBufferB[i];
      }
      radarDToStringB = true;
      setState(() {
        radarDB = String.fromCharCodes(radarDBB);
      });
      print('**BSD radar distance = ' + radarDB + ' (' + radarDBB.toString() + ')');
    }
    if(radarSDoneB && !radarSToStringB){
      Uint8List radarSBB = Uint8List(radarSBufferB.length);
      for(int i=0;i<radarSBufferB.length;i++){
        radarSBB[i] = radarSBufferB[i];
      }
      radarSToStringB = true;
      setState(() {
        radarSB = String.fromCharCodes(radarSBB);
      });
      print('**BSD radar speed = ' + radarSB + ' (' + radarSBB.toString() + ')');
    }
    if(radarADoneB && !radarAToStringB){
      Uint8List radarABB = Uint8List(radarABufferB.length);
      for(int i=0;i<radarABufferB.length;i++){
        radarABB[i] = radarABufferB[i];
      }
      radarAToStringB = true;
      setState(() {
        radarAB = String.fromCharCodes(radarABB);
      });
      print('**BSD radar angle = ' + radarAB + ' (' + radarABB.toString() + ')');
    }
    if(radarTDoneB && !radarTToStringB){
      Uint8List radarTBB = Uint8List(radarTBufferB.length);
      for(int i=0;i<radarTBufferB.length;i++){
        radarTBB[i] = radarTBufferB[i];
      }
      radarTToStringB = true;
      setState(() {
        radarTB = String.fromCharCodes(radarTBB);
      });
      print('**BSD radar target = ' + radarTB + ' (' + radarTBB.toString() + ')');
    }
    if(pastEmaDoneL && !pastEmaToStringL){
      Uint8List pastEmaLL = Uint8List(pastEmaBufferL.length);
      for(int i=0;i<pastEmaBufferL.length;i++){
        pastEmaLL[i] = pastEmaBufferL[i];
      }
      pastEmaToStringL = true;
      setState(() {
        pastEmaL = String.fromCharCodes(pastEmaLL);
      });
      print('**pastEmaL = ' + pastEmaL + ' (' + pastEmaLL.toString() + ')');
    }
    if(pastEmaDoneR && !pastEmaToStringR){
      Uint8List pastEmaRR = Uint8List(pastEmaBufferR.length);
      for(int i=0;i<pastEmaBufferR.length;i++){
        pastEmaRR[i] = pastEmaBufferR[i];
      }
      pastEmaToStringR = true;
      setState(() {
        pastEmaR = String.fromCharCodes(pastEmaRR);
      });
      print('**pastEmaR = ' + pastEmaR + ' (' + pastEmaRR.toString() + ')');
    }
    if(tLDone && !tLToString){
      Uint8List tLL = Uint8List(tLBuffer.length);
      for(int i=0;i<tLBuffer.length;i++){
        tLL[i] = tLBuffer[i];
      }
      tLToString = true;
      setState(() {
        tL = String.fromCharCodes(tLL);
      });
      print('**tL = ' + tL + ' (' + tLL.toString() + ')');
    }
    if(tRDone && !tRToString){
      Uint8List tRR = Uint8List(tRBuffer.length);
      for(int i=0;i<tRBuffer.length;i++){
        tRR[i] = tRBuffer[i];
      }
      tRToString = true;
      setState(() {
        tR = String.fromCharCodes(tRR);
      });
      print('**tR = ' + tR + ' (' + tRR.toString() + ')');
    }
    if(respDoneF && !respToStringF){
      Uint8List respFF = Uint8List(respBufferF.length);
      for(int i=0;i<respBufferF.length;i++){
        respFF[i] = respBufferF[i];
      }
      respToStringF = true;
      setState(() {
        respF = String.fromCharCodes(respFF);
      });
      print('**respF = ' + respF + ' (' + respFF.toString() + ')');
    }
    if(radarDDoneF && !radarDToStringF){
      Uint8List radarDFF = Uint8List(radarDBufferF.length);
      for(int i=0;i<radarDBufferF.length;i++){
        radarDFF[i] = radarDBufferF[i];
      }
      radarDToStringF = true;
      setState(() {
        radarDF = String.fromCharCodes(radarDFF);
      });
      print('**CAS radar distance = ' + radarDF + ' (' + radarDFF.toString() + ')');
    }
    if(radarSDoneF && !radarSToStringF){
      Uint8List radarSFF = Uint8List(radarSBufferF.length);
      for(int i=0;i<radarSBufferF.length;i++){
        radarSFF[i] = radarSBufferF[i];
      }
      radarSToStringF = true;
      setState(() {
        radarSF = String.fromCharCodes(radarSFF);
      });
      print('**CAS radar speed = ' + radarSF + ' (' + radarSFF.toString() + ')');
    }
    if(radarADoneF && !radarAToStringF){
      Uint8List radarAFF = Uint8List(radarABufferF.length);
      for(int i=0;i<radarABufferF.length;i++){
        radarAFF[i] = radarABufferF[i];
      }
      radarAToStringF = true;
      setState(() {
        radarAF = String.fromCharCodes(radarAFF);
      });
      print('**CAS radar angle = ' + radarAF + ' (' + radarAFF.toString() + ')');
    }
    if(radarTDoneF && !radarTToStringF){
      Uint8List radarTFF = Uint8List(radarTBufferF.length);
      for(int i=0;i<radarTBufferF.length;i++){
        radarTFF[i] = radarTBufferF[i];
      }
      radarTToStringF = true;
      setState(() {
        radarTF = String.fromCharCodes(radarTFF);
      });
      print('**CAS radar target = ' + radarTF + ' (' + radarTFF.toString() + ')');
    }
    if(pastEmaDoneF && !pastEmaToStringF){
      Uint8List pastEmaFF = Uint8List(pastEmaBufferF.length);
      for(int i=0;i<pastEmaBufferF.length;i++){
        pastEmaFF[i] = pastEmaBufferF[i];
      }
      pastEmaToStringF = true;
      setState(() {
        pastEmaF = String.fromCharCodes(pastEmaFF);
      });
      print('**pastEmaF = ' + pastEmaF + ' (' + pastEmaFF.toString() + ')');
    }
    if(tFDone && !tFToString){
      Uint8List tFF = Uint8List(tFBuffer.length);
      for(int i=0;i<tFBuffer.length;i++){
        tFF[i] = tFBuffer[i];
      }
      tFToString = true;
      setState(() {
        tF = String.fromCharCodes(tFF);
      });
      print('**tF = ' + tF + ' (' + tFF.toString() + ')');
    }
    if(longDone && !longToString){
      Uint8List longg = Uint8List(longBuffer.length);
      for(int i=0;i<longBuffer.length;i++){
        longg[i] = longBuffer[i];
      }
      longToString = true;
      setState(() {
        longitude = String.fromCharCodes(longg);
      });
      print('**longitude = ' + longitude + ' (' + longg.toString() + ')');
    }
    if(latDone && !latToString){
      Uint8List latt = Uint8List(latBuffer.length);
      for(int i=0;i<latBuffer.length;i++){
        latt[i] = latBuffer[i];
      }
      latToString = true;
      setState(() {
        latitude = String.fromCharCodes(latt);
      });
      print('**latitude = ' + emaR + ' (' + latt.toString() + ')');
    }
    if(mySpeedDone && !mySpeedToString){
      Uint8List mySpeedd = Uint8List(mySpeedBuffer.length);
      for(int i=0;i<mySpeedBuffer.length;i++){
        mySpeedd[i] = mySpeedBuffer[i];
      }
      mySpeedToString = true;
      setState(() {
        mySpeed = String.fromCharCodes(mySpeedd);
      });
      print('**speed = ' + mySpeed + ' (' + mySpeedd.toString() + ')');
    }
  }

  void _resetBTinfo(){
    emaBufferL.clear();
    emaDoneL = false;
    emaToStringL = false;

    emaBufferR.clear();
    emaDoneR = false;
    emaToStringR = false;

    emaBufferF.clear();
    emaDoneF = false;
    emaToStringF = false;

    btWarningBuffer.clear();
    btWarningDone = false;
    btWarningToStatus = false;

    respBufferB.clear();
    respDoneB = false;
    respToStringB = false;

    radarDBufferB.clear();
    radarDDoneB = false;
    radarDToStringB = false;

    radarSBufferB.clear();
    radarSDoneB = false;
    radarSToStringB = false;

    radarABufferB.clear();
    radarADoneB = false;
    radarAToStringB = false;

    radarTBufferB.clear();
    radarTDoneB = false;
    radarTToStringB = false;

    pastEmaBufferL.clear();
    pastEmaDoneL = false;
    pastEmaToStringL = false;

    pastEmaBufferR.clear();
    pastEmaDoneR = false;
    pastEmaToStringR = false;

    tLBuffer.clear();
    tLDone = false;
    tLToString = false;

    tRBuffer.clear();
    tRDone = false;
    tRToString = false;

    respBufferF.clear();
    respDoneF = false;
    respToStringF = false;

    radarDBufferF.clear();
    radarDDoneF = false;
    radarDToStringF = false;

    radarSBufferF.clear();
    radarSDoneF = false;
    radarSToStringF = false;

    radarABufferF.clear();
    radarADoneF = false;
    radarAToStringF = false;

    radarTBufferF.clear();
    radarTDoneF = false;
    radarTToStringF = false;

    pastEmaBufferF.clear();
    pastEmaDoneF = false;
    pastEmaToStringF = false;

    tFBuffer.clear();
    tFDone = false;
    tFToString = false;

    longBuffer.clear();
    longDone = false;
    longToString = false;

    latBuffer.clear();
    latDone = false;
    latToString = false;

    mySpeedBuffer.clear();
    mySpeedDone = false;
    mySpeedToString = false;

    print("reset btBuffer");
  }
}