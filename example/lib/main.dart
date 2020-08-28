import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:fffmpeg/fffmpeg.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initss();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await Fffmpeg.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: ()async{
              String http="http://139.199.153.108:8080/test.mp4";
              String img="http://139.199.153.108:8080/tomcat.png";
              Directory temporaryDirectory =await getTemporaryDirectory();
              String sss= temporaryDirectory.path+"/test.mp4";
              String sss_img= temporaryDirectory.path+"/sss_img.png";
              if(!await File(sss).exists()){
                await Dio().download(http, sss,onReceiveProgress: (int2,int1){
                  print("int===="+int2.toString()+"===="+int1.toString());
                });
              }
              if(!await File(sss_img).exists()){
                await Dio().download(img, sss_img);
              }
              input=sss;
              output= temporaryDirectory.path+"/test_water4.mp4";
              logo=sss_img;
              print("ok");

              String ss=input+","+output;
            // addWaterMask(input, output).then((value) => print("========"+value.toString()));
            Fffmpeg.addWatermarkToVedio(input, output, logo, WaterMarkPosition.LeftBottom);
            // Fffmpeg.exeCommand(ss);
          },
        ),
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }
  static String logo="/storage/emulated/0/aa_flutter/logo.jpeg";
  static String input="/storage/emulated/0/aa_flutter/test.mp4";
  static String output="/storage/emulated/0/aa_flutter/test_water.mp4";
  //传个图片,能设定宽高和四个角落
  static Future addWaterMask(String inputPath,String outputPath)async{
//    await _addLogoTodisk();
//       String s = await _getWaterMaskPath();
//       await File(outputPath).create();

      //处理完返回路径吧
    return  await Fffmpeg.addWatermarkToVedio(input,output,logo,WaterMarkPosition.LeftBottom);

  }
  initss()async{
    if(Platform.isIOS){
      Directory temporaryDirectory =await getTemporaryDirectory();
      String sss= temporaryDirectory.path+"/test.mp4";
      String sss_img= temporaryDirectory.path+"/sss_img.png";

      input=sss;
      output= temporaryDirectory.path+"/test_water.mp4";
      logo=sss_img;
      print("init_ok");
    }
  }
}
