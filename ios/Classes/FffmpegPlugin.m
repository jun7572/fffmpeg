#import "FffmpegPlugin.h"

#import <AVFoundation/AVFoundation.h>
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
  }
   if([@"exeCommand" isEqualToString:call.method]){
       NSDictionary* arguments = call.arguments[@"arguments"];
       NSString *input=arguments[@"inputPath"];
       NSString *output=arguments[@"outputPath"];
       NSLog(input);
        NSLog(output);
       //test
//       [self addWaterPicWithVideoPath1:input outPath:output result:result];

   } else if([@"addwaterMark" isEqualToString:call.method]){
        NSDictionary* arguments = call.arguments[@"arguments"];
         NSString *input=arguments[@"inputPath"];
         NSString *output=arguments[@"outputPath"];
            NSLog(input);
            NSLog(output);
           NSString *watermarkPath=arguments[@"watermarkPath"];
       //LeftTop  RightTop  RightBottom  LeftBottom
           NSString *position=arguments[@"position"];
       [self addWaterPicWithVideoPath:input outPath:output result:result watermarkPath:watermarkPath position:position];
       
   }else {
    result(FlutterMethodNotImplemented);
  }
}



- (void)addWaterPicWithVideoPath:(NSString*)path outPath:(NSString*)outPath result:(FlutterResult)result watermarkPath:(NSString*)watermarkPath position:(NSString*)position
{
    //1 创建AVAsset实例
    AVURLAsset* videoAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:path]];

    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];


    //3 视频通道
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                        ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject]
                         atTime:kCMTimeZero error:nil];


    //2 音频通道
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                        ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject]
                         atTime:kCMTimeZero error:nil];

    //3.1 AVMutableVideoCompositionInstruction 视频轨道中的一个视频，可以缩放、旋转等
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
      mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    

    
           
   
    // 3.2 AVMutableVideoCompositionLayerInstruction 一个视频轨道，包含了这个轨道上的所有视频素材
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];

    [videolayerInstruction setOpacity:0.0 atTime:videoAsset.duration];

    // 3.3 - Add instructions
    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];

    //AVMutableVideoComposition：管理所有视频轨道，水印添加就在这上面
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    
    
    CGAffineTransform translateToCenter;
    CGAffineTransform mixedTransform;
            translateToCenter = CGAffineTransformMakeTranslation(videoTrack.naturalSize.height, 0.0);
            mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI_2);
      mainCompositionInst.renderSize = CGSizeMake(videoTrack.naturalSize.width,videoTrack.naturalSize.height);

    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    CGSize naturalSize = videoAssetTrack.naturalSize;

    float renderWidth, renderHeight;
    renderWidth = naturalSize.width;
    renderHeight = naturalSize.height;
    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    [self applyVideoEffectsToComposition:mainCompositionInst size:naturalSize watermarkPath:watermarkPath position:position];

    //    // 4 - 输出路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:
                             [NSString stringWithFormat:@"FinalVideo-%d.mp4",arc4random() % 1000]];
    
    NSURL* videoUrl = [NSURL fileURLWithPath:outPath];

    // 5 - 视频文件输出
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = videoUrl;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = mainCompositionInst;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{

            if( exporter.status == AVAssetExportSessionStatusCompleted ){
 NSLog(@"ios-addmark-ok");
                UISaveVideoAtPathToSavedPhotosAlbum(myPathDocs, nil, nil, nil);
                
                        result(outPath);
               
            }else if( exporter.status == AVAssetExportSessionStatusFailed )
            {
                NSLog(@"not-ok");
                NSLog(exporter.error.localizedDescription);
                   result(@"notok");
                
               
            }

        });
    }];
}


/**
 设置水印及其对应视频的位置

 @param composition 视频的结构
 @param size 视频的尺寸
 */
- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size watermarkPath:(NSString*)watermarkPath position:(NSString*)position
{
    // 文字
//    CATextLayer *subtitle1Text = [[CATextLayer alloc] init];
//    //    [subtitle1Text setFont:@"Helvetica-Bold"];
//    [subtitle1Text setFontSize:36];
//    [subtitle1Text setFrame:CGRectMake(10, size.height-10-100, size.width, 100)];
//    [subtitle1Text setString:@"ZHIMABAOBAO"];
//    //    [subtitle1Text setAlignmentMode:kCAAlignmentCenter];
//    [subtitle1Text setForegroundColor:[[UIColor whiteColor] CGColor]];
    
    NSData *imageData = [NSData dataWithContentsOfFile:watermarkPath];
      UIImage *image2 = [UIImage imageWithData:imageData];
//    //图片
    CALayer*picLayer = [CALayer layer];
////    UIImage *ui11=[UIImage imageNamed:@"watermarklogo"];
//
    picLayer.contents = (id)image2.CGImage;
     
    
//    CALayer*picLayer = [CALayer layer];
//    picLayer.contents = (id)[UIImage imageNamed:@"watermarklogo"].CGImage;
//    picLayer.frame = CGRectMake(20, size.height-120, 100, 102);

     picLayer.contents = (id)image2.CGImage;
     NSUInteger width= image2.size.width;
     NSUInteger height= image2.size.height;
    //看到时候传不传进来
    NSInteger logoPadding=20;
    //LeftTop  RightTop  RightBottom  LeftBottom
    if([@"LeftTop" isEqualToString:position]){
        picLayer.frame = CGRectMake(logoPadding, size.height-height-logoPadding, width, height);
    }else if([@"RightTop" isEqualToString:position]){
        picLayer.frame = CGRectMake(size.width-width-logoPadding, size.height-height-logoPadding, width, height);
    }else if([@"RightBottom" isEqualToString:position]){
picLayer.frame = CGRectMake(size.width-width-logoPadding, logoPadding, width, height);
    }else if([@"LeftBottom" isEqualToString:position]){
 picLayer.frame = CGRectMake(logoPadding, logoPadding, width, height);
    }
    
    // 2 - The usual overlay
    CALayer *overlayLayer = [CALayer layer];
    [overlayLayer addSublayer:picLayer];
    overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [overlayLayer setMasksToBounds:YES];

    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer];

    composition.animationTool = [AVVideoCompositionCoreAnimationTool
                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
 
}






@end
