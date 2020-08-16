#import "FffmpegPlugin.h"

#import <mobileffmpeg/ArchDetect.h>
#import <mobileffmpeg/MobileFFmpegConfig.h>
#import <mobileffmpeg/MobileFFmpeg.h>
#import <mobileffmpeg/MobileFFprobe.h>
@implementation FffmpegPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"fffmpeg"
            binaryMessenger:[registrar messenger]];
  FffmpegPlugin* instance = [[FffmpegPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  }else if([@"exeCommand" isEqualToString:call.method]){
         NSArray* arguments = call.arguments[@"arguments"];
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

                 int rc = [MobileFFmpeg executeWithArguments:arguments];

                 NSLog(@"FFmpeg exited with rc: %d\n", rc);

                 result(@"ok");
             });
      
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
