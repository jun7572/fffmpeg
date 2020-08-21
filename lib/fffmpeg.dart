import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

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
}
