import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:fffmpeg/fffmpeg.dart';

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
          onPressed: (){
            addWaterMask(input, output).then((value) => print("========"+value.toString()));
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
  static Future addWaterMask(String inputPath,String outputPath)async{
//    await _addLogoTodisk();
//       String s = await _getWaterMaskPath();
//       await File(outputPath).create();
      String command="-i "+input+" -i "+logo+" -filter_complex 'overlay=main_w-overlay_w-10:main_h-overlay_h-10' "+output;
      //处理完返回路径吧
    return  await Fffmpeg.exeCommand(command);

  }
}
