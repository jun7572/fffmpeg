import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as UI;
import 'dart:ui';
enum WaterMarkPosition{
  LeftTop,
  RightTop,
  LeftBottom,
  RightBottom
}
class Fffmpeg {

  static const MethodChannel _channel =
      const MethodChannel('fffmpeg');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
  //android 传命令 ios传路径
  static Future<String>  exeCommand(String command) async {
    String version="";
    if(Platform.isIOS){
      var split = command.split(",");

      version = await _channel.invokeMethod('exeCommand',{'arguments': {"inputPath":split[0],"outputPath":split[1]}});
    }else if(Platform.isAndroid){
        version = await _channel.invokeMethod('exeCommand',{'arguments': parseArguments(command)});
    }

    return version;
  }

  static Future<String> addWatermarkToVedio(String inputPath,String outputPath,String watermarkPath,WaterMarkPosition waterMarkPosition)async{
    print("input=="+inputPath);
    print("output=="+outputPath);
    String s="";
    String position="";
    if(Platform.isIOS){
      if(waterMarkPosition==WaterMarkPosition.LeftTop){
        position="LeftTop";
      }else if(waterMarkPosition==WaterMarkPosition.RightTop){
        position="RightTop";
      }else if(waterMarkPosition==WaterMarkPosition.RightBottom){
        position="RightBottom";
      }else if(waterMarkPosition==WaterMarkPosition.LeftBottom){
        position="LeftBottom";
      }
      s = await _channel.invokeMethod('addwaterMark',{'arguments': {"inputPath":inputPath,"outputPath":outputPath,"watermarkPath":watermarkPath,"position":position}});
      return s;
    }else if(Platform.isAndroid){
     s= await executeWithArguments(getCommand(inputPath, outputPath, watermarkPath, waterMarkPosition));
      return s;
    }

  }

  static Future<String> executeWithArguments(List<String> arguments) async {
    if(Platform.isIOS){
      return "Platform.isIOS!!error";
    }
    try {
      String version = await _channel
          .invokeMethod('exeCommand', {'arguments': arguments});
      return version;
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
      return "error";
    }
  }
  //解析输入的命令
  static List<String> parseArguments(String command) {
    List<String> argumentList = new List();
    StringBuffer currentArgument = new StringBuffer();

    bool singleQuoteStarted = false;
    bool doubleQuoteStarted = false;

    for (int i = 0; i < command.length; i++) {
      var previousChar;
      if (i > 0) {
        previousChar = command.codeUnitAt(i - 1);
      } else {
        previousChar = null;
      }
      var currentChar = command.codeUnitAt(i);

      if (currentChar == ' '.codeUnitAt(0)) {
        if (singleQuoteStarted || doubleQuoteStarted) {
          currentArgument.write(String.fromCharCode(currentChar));
        } else if (currentArgument.length > 0) {
          argumentList.add(currentArgument.toString());
          currentArgument = new StringBuffer();
        }
      } else if (currentChar == '\''.codeUnitAt(0) &&
          (previousChar == null || previousChar != '\\'.codeUnitAt(0))) {
        if (singleQuoteStarted) {
          singleQuoteStarted = false;
        } else if (doubleQuoteStarted) {
          currentArgument.write(String.fromCharCode(currentChar));
        } else {
          singleQuoteStarted = true;
        }
      } else if (currentChar == '\"'.codeUnitAt(0) &&
          (previousChar == null || previousChar != '\\'.codeUnitAt(0))) {
        if (doubleQuoteStarted) {
          doubleQuoteStarted = false;
        } else if (singleQuoteStarted) {
          currentArgument.write(String.fromCharCode(currentChar));
        } else {
          doubleQuoteStarted = true;
        }
      } else {
        currentArgument.write(String.fromCharCode(currentChar));
      }
    }

    if (currentArgument.length > 0) {
      argumentList.add(currentArgument.toString());
    }

    return argumentList;
  }

  static List<String> getCommand(String inputPath,String outputPath,String imagesPath,WaterMarkPosition waterMarkPosition){
    List<String> commands=List<String>(26);
    if(waterMarkPosition==WaterMarkPosition.LeftTop){
      commands[5] = "overlay=10:10";
    }else if(waterMarkPosition==WaterMarkPosition.RightTop){
     commands[5] = "overlay= main_w-overlay_w:0";
    }else if(waterMarkPosition==WaterMarkPosition.RightBottom){
      commands[5] = "overlay= main_w-overlay_w:main_h-overlay_h";
    }else if(waterMarkPosition==WaterMarkPosition.LeftBottom){
      commands[5] = "overlay=0: main_h-overlay_h";
    }
    commands[0] = "-i";
    commands[1] = inputPath;
    commands[2] = "-i";
    commands[3] = imagesPath;
    commands[4] = "-filter_complex";

    commands[6] = "-y";
    commands[7] = "-strict";
    commands[8] = "-2";
    commands[9] = "-vcodec";
    commands[10] = "libx264";
    commands[11] = "-preset";
    commands[12] = "ultrafast";
    //-crf  用于指定输出视频的质量，取值范围是0-51，默认值为23，数字越小输出视频的质量越高。
    // 这个选项会直接影响到输出视频的码率。一般来说，压制480p我会用20左右，压制720p我会用16-18
    commands[13] = "-crf";
    commands[14] = "29";
    commands[15] = "-threads";
    commands[16] = "2";
    commands[17] = "-acodec";
    commands[18] = "aac";
    commands[19] = "-ar";
    commands[20] = "44100";
    commands[21] = "-ac";
    commands[22] = "2";
    commands[23] = "-b:a";
    commands[24] = "32k";
    //下面两行用于设置视频大小
//        commands[23] = "-s";
//        commands[24] = "480x480";
    commands[25] = outputPath;
    return commands;
  }
}
