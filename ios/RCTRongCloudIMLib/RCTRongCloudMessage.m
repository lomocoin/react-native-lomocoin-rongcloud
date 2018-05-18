//
//  RCTRongCloudMessage.m
//  RongCloud
//
//  Created by SUN on 2018/5/17.
//  Copyright © 2018年 Sun. All rights reserved.
//

#import "RCTRongCloudMessage.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

@interface RCTRongCloudMessage ()

@property (nonatomic, assign) BOOL       isSend;    //是否已发送
@property (nonatomic, assign) NSInteger  duration;  //语音时长
@property (nonatomic, strong) NSTimer *  longTimer; //60s定时器
@property (nonatomic, strong) NSDate * startDate;
@property (nonatomic, strong) NSDate * endDate;
@property (nonatomic, strong) AVAudioSession *session;
@property (nonatomic, strong) AVAudioRecorder *recorder;//录音器
@property (nonatomic, strong) AVAudioPlayer *player; //播放器
@property (nonatomic, strong) NSURL *recordFileUrl; //语音路径

@property (nonatomic, assign) int type;
@property (nonatomic, copy) NSString *targetId;
@property (nonatomic, copy) NSString *pushContent;
@property (nonatomic, copy) NSString *extra;

@end

@implementation RCTRongCloudMessage

static RCTRongCloudMessage * _message = nil;

+ (instancetype)shareMessage
{
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _message = [[self alloc] init] ;
    }) ;
    
    return _message ;
}

+ (RCIMClient *) getClient {
    return [RCIMClient sharedRCIMClient];
}

+ (RCConversationType)getConversationType:(int)type{
    switch (type) {
        case 1:
            return ConversationType_PRIVATE;
        case 2:
            return ConversationType_DISCUSSION;
        case 3:
            return ConversationType_GROUP;
        default:
            return ConversationType_PRIVATE;
    }
}

#pragma mark Text Message

+ (void)sendTextMessage:(int)type
               targetId:(NSString *)targetId
                content:(NSString *)content
            pushContent:(NSString *)pushContent
                  extra:(NSString *)extra
                success:(void (^)(NSString *messageId))successBlock
                  error:(void (^)(RCErrorCode status, NSString *messageId))errorBlock{
    
    RCTextMessage *messageContent = [RCTextMessage messageWithContent:content];
    if(extra){
        messageContent.extra = extra;
    }
    [self sendMessage:type messageType:@"text" targetId:targetId content:messageContent pushContent:pushContent success:successBlock error:errorBlock];
}

#pragma mark Image Message

+ (void)sendImageMessage:(int)type
                targetId:(NSString *)targetId
                imageUrl:(NSString *)imageUrl
             pushContent:(NSString *)pushContent
                   extra:(NSString *)extra
                 success:(void (^)(NSString *messageId))successBlock
                   error:(void (^)(RCErrorCode status, NSString *messageId))errorBlock{
    
    if([imageUrl rangeOfString:@"assets-library"].location == NSNotFound){
        RCImageMessage *imageMessage = [RCImageMessage messageWithImageURI:imageUrl];
        if(extra){
            imageMessage.extra = extra;
        }
        [self sendMessage:type messageType:@"image" targetId:targetId content:imageMessage pushContent:pushContent success:successBlock error:errorBlock];
    }
    else{
        [self sendImageMessageWithType:type targetId:targetId ImageUrl:imageUrl pushContent:pushContent extra:extra success:successBlock error:errorBlock];
    }
}

+ (void)sendImageMessageWithType:(int)type targetId:(NSString *)targetId ImageUrl:(NSString *)imageUrl  pushContent:(NSString *)pushContent extra:(NSString *)extra success:(void (^)(NSString *messageId))successBlock error:(void (^)(RCErrorCode nErrorCode, NSString *messageId))errorBlock{
    
    ALAssetsLibrary   *lib = [[ALAssetsLibrary alloc] init];
    
    [lib assetForURL:[NSURL URLWithString:imageUrl] resultBlock:^(ALAsset *asset) {
        //在这里使用asset来获取图片
        ALAssetRepresentation *assetRep = [asset defaultRepresentation];
        CGImageRef imgRef = [assetRep fullResolutionImage];
        UIImage * image = [UIImage imageWithCGImage:imgRef
                                              scale:assetRep.scale
                                        orientation:(UIImageOrientation)assetRep.orientation];
        UIImage * scaledImage = [self scaleImageWithImage:image toSize:CGSizeMake(960, 960)]; // 融云推荐使用的大图尺寸为：960 x 960 像素
        
        RCImageMessage *imageMessage = [RCImageMessage messageWithImage:scaledImage];
        if(extra){
            imageMessage.extra = extra;
        }
        [self sendMessage:type messageType:@"image" targetId:targetId content:imageMessage pushContent:pushContent success:successBlock error:errorBlock];
        
    } failureBlock:^(NSError *error) {
        errorBlock(ERRORCODE_UNKNOWN, 0);
    }];
    
}

//等比例缩小
+ (UIImage *)scaleImageWithImage:(UIImage *)image toSize:(CGSize)size
{
    CGFloat width = CGImageGetWidth(image.CGImage);
    CGFloat height = CGImageGetHeight(image.CGImage);
    
    if(width < size.width && height < size.height){
        return image;
    }
    
    float verticalRadio = height/size.height;
    float horizontalRadio = width/size.width;
    
    float radio = verticalRadio > horizontalRadio ? verticalRadio : horizontalRadio;
    
    width = width/radio;
    height = height/radio;
    
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    
    // 绘制改变大小的图片
    [image drawInRect:CGRectMake(0, 0, width, height)];
    
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    
    // 返回新的改变大小后的图片
    return scaledImage;
}


#pragma mark Voice Message

- (void)voiceBtnPressIn:(int)type
               targetId:(NSString *)targetId
            pushContent:(NSString *)pushContent
                  extra:(NSString *)extra{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.type = type;
        self.targetId = targetId;
        self.pushContent = pushContent;
        self.extra = extra;
        
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
        if(authStatus == AVAuthorizationStatusDenied) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                if (!granted) {
                    if(self.errorBlock) {
                        self.errorBlock(ERRORCODE_UNKNOWN, @"permission_error");
                    }
                }
            }];
        }
        
        AVAudioSession *session =[AVAudioSession sharedInstance];
        NSError *sessionError;
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
        
        if (session == nil) {
            NSLog(@"Error creating session: %@",[sessionError description]);
        }else{
            [session setActive:YES error:nil];
        }
        
        
        self.session = session;
        
        //1.获取沙盒地址
        NSString * filePath = [self getSandboxFilePath];
        
        //2.获取文件路径
        self.recordFileUrl = [NSURL fileURLWithPath:filePath];
        
        //设置参数
        //    NSDictionary *recordSetting = [[NSDictionary alloc] initWithObjectsAndKeys:
        //                                   //采样率  8000/11025/22050/44100/96000（影响音频的质量）
        //                                   [NSNumber numberWithFloat: 8000.0],AVSampleRateKey,
        //                                   // 音频格式
        //                                   [NSNumber numberWithInt: kAudioFormatLinearPCM],AVFormatIDKey,
        //                                   //采样位数  8、16、24、32 默认为16
        //                                   [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
        //                                   // 音频通道数 1 或 2
        //                                   [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
        //                                   //录音质量
        //                                   [NSNumber numberWithInt:AVAudioQualityHigh],AVEncoderAudioQualityKey,
        //                                   nil];
        
        NSDictionary * recordSetting = @{AVFormatIDKey: @(kAudioFormatLinearPCM),
                                         AVSampleRateKey: @8000.00f,
                                         AVNumberOfChannelsKey: @1,
                                         AVLinearPCMBitDepthKey: @16,
                                         AVLinearPCMIsNonInterleaved: @NO,
                                         AVLinearPCMIsFloatKey: @NO,
                                         AVLinearPCMIsBigEndianKey: @NO};   //RongCloud 推荐参数
        
        
        self.recorder = [[AVAudioRecorder alloc] initWithURL:self.recordFileUrl settings:recordSetting error:nil];
        
        if (self.recorder) {
            
            @try{
                
                self.startDate = [NSDate date];
                
                self.recorder.meteringEnabled = YES;
                [self.recorder prepareToRecord];
                [self.recorder record];
                
                self.isSend = NO;
                self.duration = 0;
                
                self.longTimer = [NSTimer scheduledTimerWithTimeInterval:59.0 target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];
            }
            @catch(NSException *exception) {
                NSLog(@"exception:%@", exception);
            }
            @finally {
                
            }
        }else{
            NSLog(@"音频格式和文件存储格式不匹配,无法初始化Recorder");
        }
    });
}

- (void)voiceBtnPressOut:(int)type
                targetId:(NSString *)targetId
             pushContent:(NSString *)pushContent
                   extra:(NSString *)extra
                 success:(void (^)(NSString *message))successBlock
                   error:(void (^)(RCErrorCode status, NSString *message))errorBlock{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.type = type;
        self.targetId = targetId;
        self.pushContent = pushContent;
        self.extra = extra;
        
        if(!self.isSend){
            [self stopRecord:successBlock error:errorBlock];
        }
    });
}

- (void)voiceBtnPressCancel:(int)type
                   targetId:(NSString *)targetId
                    success:(void (^)(NSString *message))successBlock
                      error:(void (^)(NSString *Code))errorBlock{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self removeTimer];
        
        self.isSend = NO;
        if ([self.recorder isRecording]) {
            [self.recorder stop];
            self.recorder = nil;
            
            successBlock(@"cancel");
        } else {
            errorBlock(@"no data");
        }
    });
}

- (void)timerFired:(NSTimer *)timer{
    
    [self stopRecord:^(NSString *message) {
        if(self.successBlock) {
            self.successBlock(message);
        }
    } error:^(RCErrorCode nErrorCode, NSString *message) {
        if(self.errorBlock) {
            self.errorBlock(nErrorCode, message);
        }
    }];
}

- (void)stopRecord:(void (^)(NSString *message))successBlock
             error:(void (^)(RCErrorCode status, NSString *message))errorBlock{
    
    [self removeTimer];
    NSLog(@"停止录音");
    
    if ([self.recorder isRecording]) {
        [self.recorder stop];
        self.recorder = nil;
    }
    
    self.isSend = YES;
    
    self.endDate = [NSDate date];
    
    NSTimeInterval dataLong = [self.endDate timeIntervalSinceDate:self.startDate];
    
    if(dataLong < 1.0){
        errorBlock(ERRORCODE_UNKNOWN,@"-500");
    }else{
        
        self.duration = (NSInteger)roundf(dataLong);
        
        NSData * audioData = [NSData dataWithContentsOfURL:self.recordFileUrl];
        [self sendVoiceMessage:self.type targetId:self.targetId content:audioData duration:self.duration pushContent:self.pushContent extra:self.extra success:successBlock error:errorBlock];
        
        //发送完录音后，删除本地录音（融云会自动保存录音）
        NSString * filePath = self.recordFileUrl.absoluteString;
        NSFileManager * fileManager = [NSFileManager defaultManager];
        
        if(![fileManager fileExistsAtPath:filePath]){
            
            [fileManager removeItemAtPath:filePath error:nil];
        }
    }
}

- (NSString *)getSandboxFilePath{
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    NSString * documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString * directoryPath = [documentPath stringByAppendingString:@"/ChatMessage"];
    
    if(![fileManager fileExistsAtPath:directoryPath]){
        
        [fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString * timeString = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString * filePath = [directoryPath stringByAppendingString:[NSString stringWithFormat:@"/%@.wav",timeString]];
    
    [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    
    return filePath;
}


// 移除定时器
- (void)removeTimer
{
    if(self.longTimer){
        [self.longTimer invalidate];
        self.longTimer = nil;
    }
}

- (void)sendVoiceMessage:(int)type
                targetId:(NSString *)targetId
                 content:(NSData *)voiceData
                duration:(NSInteger )duration
             pushContent:(NSString *)pushContent
                   extra:(NSString *)extra
                 success:(void (^)(NSString *message))successBlock
                   error:(void (^)(RCErrorCode status, NSString *message))errorBlock {
    
    RCVoiceMessage *rcVoiceMessage = [RCVoiceMessage messageWithAudio:voiceData duration:duration];
    if (extra){
        rcVoiceMessage.extra = extra;
    }
    
    [RCTRongCloudMessage sendMessage:type messageType:@"voice" targetId:targetId content:rcVoiceMessage pushContent:pushContent success:successBlock error:errorBlock];
    
}

// 播放语音消息
- (void)audioPlayStart:(NSString *)filePath
               success:(void (^)(NSString *message))successBlock
                 error:(void (^)(NSString *Code))errorBlock{
    
    self.session =[AVAudioSession sharedInstance];
    NSError *sessionError;
    [self.session setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
    [self.session setActive:YES error:nil];
    
    if(self.player){
        [self.player stop];
        self.player = nil;
    }
    
    NSURL *audioUrl = [NSURL fileURLWithPath:filePath];
    NSError *playerError;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:audioUrl error:&playerError];
    
    if (self.player == nil)
    {
        errorBlock(@"play failed! please retry!");
        return;
    }
    
    [self.player setNumberOfLoops:0];
    [self.player prepareToPlay];
    [self.player play];
    successBlock(@"playing");
}

- (void)audioPlayStop:(void (^)(NSString *message))successBlock
                error:(void (^)(NSString *Code))errorBlock{
    
    if(self.player && [self.player isPlaying]){
        [self.player stop];
        successBlock(@"stoped");
    }else{
        errorBlock(@"no data");
    }
}


#pragma mark RongCloud Method
+ (void)sendMessage:(int)type
        messageType:(NSString *)messageType
           targetId:(NSString *)targetId
            content:(RCMessageContent *)content
        pushContent:(NSString *) pushContent
            success:(void (^)(NSString *messageId))successBlock
              error:(void (^)(RCErrorCode status, NSString *messageId))errorBlock {
    
    RCConversationType conversationType = [self getConversationType:type];
    
    if ([messageType isEqualToString:@"image"]) {
        //图片和文件消息使用sendMediaMessage方法（此方法会将图片上传至融云服务器）
        [[self getClient] sendMediaMessage:conversationType targetId:targetId content:content pushContent:pushContent pushData:nil progress:nil success:^(long messageId) {
            NSString * message = [NSString stringWithFormat:@"%ld",messageId];
            successBlock(message);
        } error:^(RCErrorCode nErrorCode, long messageId) {
            NSString * message = [NSString stringWithFormat:@"%ld",messageId];
            errorBlock(nErrorCode, message);
        } cancel:nil];
    } else {
        //文本和语音使用sendMessage方法（若使用本方法发送图片消息，则需要上传图片到自己的服务器后把图片地址放到图片消息内）
        [[self getClient] sendMessage:conversationType targetId:targetId content:content pushContent:pushContent pushData:nil success:^(long messageId) {
            NSString * message = [NSString stringWithFormat:@"%ld",messageId];
            successBlock(message);
        } error:^(RCErrorCode nErrorCode, long messageId) {
            NSString * message = [NSString stringWithFormat:@"%ld",messageId];
            errorBlock(nErrorCode, message);
        }];
    }
    
}

@end
