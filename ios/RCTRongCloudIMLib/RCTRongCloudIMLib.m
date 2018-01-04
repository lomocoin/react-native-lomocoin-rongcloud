//
//  RCTRongCloudIMLib.m
//  RCTRongCloudIMLib
//
//  Created by lomocoin on 10/21/2017.
//  Copyright © 2017 lomocoin.com. All rights reserved.
//

#import "RCTRongCloudIMLib.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

@interface RCTRongCloudIMLib ()

{
    BOOL       _isSend;    //是否已发送
    NSTimer *  _longTimer; //60s定时器
    NSInteger  _duration;  //语音时长
}

@property (nonatomic, strong) NSDate * startDate;
@property (nonatomic, strong) NSDate * endDate;
@property (nonatomic, strong) AVAudioSession *session;
@property (nonatomic, strong) AVAudioRecorder *recorder;//录音器
@property (nonatomic, strong) AVAudioPlayer *player; //播放器
@property (nonatomic, strong) NSURL *recordFileUrl; //语音路径

@end

@implementation RCTRongCloudIMLib

@synthesize bridge = _bridge;


RCT_EXPORT_MODULE(RongCloudIMLibModule)

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"onRongMessageReceived"];
}

#pragma mark RongCloud Init

RCT_EXPORT_METHOD(initWithAppKey:(NSString *)appkey) {
    NSLog(@"initWithAppKey %@", appkey);
    [[self getClient] initWithAppKey:appkey];
    
    [[self getClient] setReceiveMessageDelegate:self object:nil];
}

#pragma mark RongCloud Connect

RCT_EXPORT_METHOD(connectWithToken:(NSString *) token
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSLog(@"connectWithToken %@", token);
    
    void (^successBlock)(NSString *userId);
    successBlock = ^(NSString* userId) {
        NSArray *events = [[NSArray alloc] initWithObjects:userId,nil];
        resolve(events);
    };
    
    void (^errorBlock)(RCConnectErrorCode status);
    errorBlock = ^(RCConnectErrorCode status) {
        NSString *errcode;
        switch (status) {
            case RC_CONN_ID_REJECT:
                errcode = @"RC_CONN_ID_REJECT";
                break;
            case RC_CONN_TOKEN_INCORRECT:
                errcode = @"RC_CONN_TOKEN_INCORRECT";
                break;
            case RC_CONN_NOT_AUTHRORIZED:
                errcode = @"RC_CONN_NOT_AUTHRORIZED";
                break;
            case RC_CONN_PACKAGE_NAME_INVALID:
                errcode = @"RC_CONN_PACKAGE_NAME_INVALID";
                break;
            case RC_CONN_APP_BLOCKED_OR_DELETED:
                errcode = @"RC_CONN_APP_BLOCKED_OR_DELETED";
                break;
            case RC_DISCONN_KICK:
                errcode = @"RC_DISCONN_KICK";
                break;
            case RC_CLIENT_NOT_INIT:
                errcode = @"RC_CLIENT_NOT_INIT";
                break;
            case RC_INVALID_PARAMETER:
                errcode = @"RC_INVALID_PARAMETER";
                break;
            case RC_INVALID_ARGUMENT:
                errcode = @"RC_INVALID_ARGUMENT";
                break;
                
            default:
                errcode = @"OTHER";
                break;
        }
        reject(errcode, [NSString stringWithFormat:@"status :%ld  errcode: %@",(long)status,errcode], nil);
    };
    void (^tokenIncorrectBlock)();
    tokenIncorrectBlock = ^() {
        reject(@"TOKEN_INCORRECT", @"tokenIncorrect", nil);
    };
    
    [[self getClient] connectWithToken:token success:successBlock error:errorBlock tokenIncorrect:tokenIncorrectBlock];
    
}

#pragma mark RongCloud  Unread Message

RCT_REMAP_METHOD(getTotalUnreadCount,
                 resolve:(RCTPromiseResolveBlock)resolve
                 rejects:(RCTPromiseRejectBlock)rejects) {
    
    int totalUnreadCount = [[self getClient] getTotalUnreadCount];
    if(totalUnreadCount){
        resolve(@(totalUnreadCount));
    }else{
        rejects(@"获取失败",@"获取失败",nil);
    }
}

RCT_EXPORT_METHOD(getTargetUnreadCount:(int)type
                  targetId:(NSString *)targetId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    int unreadCount = [[self getClient] getUnreadCount:type targetId:targetId];
    if(unreadCount){
        resolve(@(unreadCount));
    }else{
        reject(@"获取失败",@"获取失败",nil);
    }
}

RCT_EXPORT_METHOD(getConversationsUnreadCount:(NSArray *)types
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    int unreadCount = [[self getClient] getUnreadCount:types];
    if(unreadCount){
        resolve(@(unreadCount));
    }else{
        reject(@"获取失败",@"获取失败",nil);
    }
}

RCT_EXPORT_METHOD(clearUnreadMessage:(int)type
                  targetId:(NSString *)targetId) {
    
    RCConversationType conversationType;
    switch (type) {
        case 1:
            conversationType = ConversationType_PRIVATE;
            break;
        case 3:
            conversationType = ConversationType_GROUP;
            break;
            
        default:
            conversationType = ConversationType_PRIVATE;
            break;
    }
    
    [[self getClient] clearMessagesUnreadStatus:conversationType targetId:targetId];
}

#pragma mark  RongCloud  GetMessagesFromLocal

RCT_REMAP_METHOD(getConversationList,
                 resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject) {
    
    NSArray *conversationList = [[self getClient] getConversationList:@[@(ConversationType_PRIVATE),@(ConversationType_GROUP)]];
    if(conversationList.count > 0){
        NSMutableArray * array = [NSMutableArray new];
        for  (RCConversation * conversation in conversationList) {
            NSMutableDictionary * dict = [NSMutableDictionary new];
            dict[@"conversationType"] = @((unsigned long)conversation.conversationType);
            dict[@"targetId"] = conversation.targetId;
            dict[@"conversationTitle"] = conversation.conversationTitle;
            dict[@"unreadMessageCount"] = @(conversation.unreadMessageCount);
            dict[@"receivedTime"] = @((long long)conversation.receivedTime);
            dict[@"sentTime"] = @((long long)conversation.sentTime);
            dict[@"senderUserId"] = conversation.senderUserId;
            dict[@"lastestMessageId"] = @(conversation.lastestMessageId);
            dict[@"lastestMessageDirection"] = @(conversation.lastestMessageDirection);
            dict[@"jsonDict"] = conversation.jsonDict;
            if ([conversation.lastestMessage isKindOfClass:[RCTextMessage class]]) {
                RCTextMessage *textMsg = (RCTextMessage *)conversation.lastestMessage;
                dict[@"msgType"] = @"text";
                dict[@"lastestMessage"] = textMsg.content;
            } else if ([conversation.lastestMessage isKindOfClass:[RCImageMessage class]]) {
                dict[@"msgType"] = @"image";
            } else if ([conversation.lastestMessage isKindOfClass:[RCVoiceMessage class]]) {
                dict[@"msgType"] = @"voice";
            }
            
            [array addObject:dict];
        }
        NSLog(@"conversationList === %@",array);
        resolve(array);
    }else{
        NSLog(@"=== 读取失败 === ");
        reject(@"读取失败", @"读取失败", nil);
    }
}


RCT_REMAP_METHOD(getLatestMessages,
                 type:(int)type
                 targetId:(NSString *)targetId
                 count:(int)count
                 resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject) {
    
    RCConversationType conversationType;
    switch (type) {
        case 1:
            conversationType = ConversationType_PRIVATE;
            break;
        case 3:
            conversationType = ConversationType_GROUP;
            break;
            
        default:
            conversationType = ConversationType_PRIVATE;
            break;
    }
    
    NSArray * messageList = [[self getClient] getLatestMessages:conversationType targetId:targetId count:count];
    if(messageList){
        NSMutableArray * array = [NSMutableArray new];
        for (RCMessage * message in messageList) {
            NSMutableDictionary * dict = [NSMutableDictionary new];
            dict[@"conversationType"] = @((unsigned long)message.conversationType);
            dict[@"targetId"] = message.targetId;
            dict[@"messageId"] = @(message.messageId);
            dict[@"receivedTime"] = @((long long)message.receivedTime);
            dict[@"sentTime"] = @((long long)message.sentTime);
            dict[@"senderUserId"] = message.senderUserId;
            dict[@"messageUId"] = message.messageUId;
            dict[@"messageDirection"] = @(message.messageDirection);
            
            if([message.content isKindOfClass:[RCTextMessage class]]){
                RCTextMessage *textMsg = (RCTextMessage *)message.content;
                dict[@"type"] = @"text";
                dict[@"content"] = textMsg.content;
                dict[@"extra"] = textMsg.extra;
            }
            else if ([message.content isKindOfClass:[RCImageMessage class]]){
                RCImageMessage *imageMsg = (RCImageMessage *)message.content;
                dict[@"type"] = @"image";
                dict[@"imageUrl"] = imageMsg.imageUrl;
                dict[@"extra"] = imageMsg.extra;
            }
            else if ([message.content isKindOfClass:[RCVoiceMessage class]]){
                RCVoiceMessage *voiceMsg = (RCVoiceMessage *)message.content;
                dict[@"type"] = @"voice";
                dict[@"wavAudioData"] = [self saveWavAudioDataToSandbox:voiceMsg.wavAudioData messageId:message.messageId];
                dict[@"duration"] = @(voiceMsg.duration);
                dict[@"extra"] = voiceMsg.extra;
            }
            [array addObject:dict];
        }
        NSLog(@"MessagesList === %@",array);
        resolve(array);
        
    }
    else{
        reject(@"读取失败", @"读取失败", nil);
    }
}

- (NSString *)saveWavAudioDataToSandbox:(NSData *)data messageId:(NSInteger)msgId{
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    NSString * documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString * directoryPath = [documentPath stringByAppendingString:@"/ChatMessage"];
    
    if(![fileManager fileExistsAtPath:directoryPath]){
        
        [fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    
    NSString * filePath = [directoryPath stringByAppendingString:[NSString stringWithFormat:@"/%ld.wav",msgId]];
    
    [fileManager createFileAtPath:filePath contents:data attributes:nil];
    
    return filePath;
}

#pragma mark  RongCloud  SearchMessagesFromLocal

RCT_REMAP_METHOD(searchConversations,
                 keyword:(NSString *)keyword
                 resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject) {
    
    NSArray *SearchResult = [[self getClient] searchConversations:@[@(ConversationType_PRIVATE),@(ConversationType_GROUP)] messageType:@[[RCTextMessage getObjectName]] keyword:keyword];
    
    
    if(SearchResult.count > 0){
        NSMutableArray * array = [NSMutableArray new];
        for  (RCSearchConversationResult * result in SearchResult) {
            NSMutableDictionary * dict = [NSMutableDictionary new];
            dict[@"conversationType"] = @((unsigned long)result.conversation.conversationType);
            dict[@"targetId"] = result.conversation.targetId;
            dict[@"conversationTitle"] = result.conversation.conversationTitle;
            dict[@"unreadMessageCount"] = @(result.conversation.unreadMessageCount);
            dict[@"receivedTime"] = @((long long)result.conversation.receivedTime);
            dict[@"sentTime"] = @((long long)result.conversation.sentTime);
            dict[@"senderUserId"] = result.conversation.senderUserId;
            dict[@"lastestMessageId"] = @(result.conversation.lastestMessageId);
            dict[@"lastestMessageDirection"] = @(result.conversation.lastestMessageDirection);
            dict[@"jsonDict"] = result.conversation.jsonDict;
            if ([result.conversation.lastestMessage isKindOfClass:[RCTextMessage class]]) {
                RCTextMessage *textMsg = (RCTextMessage *)result.conversation.lastestMessage;
                dict[@"msgType"] = @"text";
                dict[@"lastestMessage"] = textMsg.content;
            } else if ([result.conversation.lastestMessage isKindOfClass:[RCImageMessage class]]) {
                dict[@"msgType"] = @"image";
            } else if ([result.conversation.lastestMessage isKindOfClass:[RCVoiceMessage class]]) {
                dict[@"msgType"] = @"voice";
            }
            
            [array addObject:dict];
        }
        NSLog(@"SearchResultList === %@",array);
        resolve(array);
    }else{
        NSLog(@"=== 读取失败 === ");
        reject(@"读取失败", @"读取失败", nil);
    }
}

#pragma mark  RongCloud  Send Text / Image  Messages

RCT_EXPORT_METHOD(sendTextMessage:(int)type
                  targetId:(NSString *)targetId
                  content:(NSString *)content
                  pushContent:(NSString *)pushContent
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    RCTextMessage *messageContent = [RCTextMessage messageWithContent:content];
    [self sendMessage:type messageType:@"text" targetId:targetId content:messageContent pushContent:pushContent resolve:resolve reject:reject];
    
    
}

RCT_EXPORT_METHOD(sendImageMessage:(int)type
                  targetId:(NSString *)targetId
                  content:(NSString *)imageUrl
                  pushContent:(NSString *)pushContent
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    if([imageUrl rangeOfString:@"assets-library"].location == NSNotFound){
        RCImageMessage *imageMessage = [RCImageMessage messageWithImageURI:imageUrl];
        [self sendMessage:type messageType:@"image" targetId:targetId content:imageMessage pushContent:pushContent resolve:resolve reject:reject];
    }
    else{
        [self sendImageMessageWithType:type targetId:targetId ImageUrl:imageUrl pushContent:pushContent resolve:resolve reject:reject];
    }
}

- (void)sendImageMessageWithType:(int)type targetId:(NSString *)targetId ImageUrl:(NSString *)imageUrl  pushContent:(NSString *)pushContent resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject{
    
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
        
        [self sendMessage:type messageType:@"image" targetId:targetId content:imageMessage pushContent:pushContent resolve:resolve reject:reject];
        
    } failureBlock:^(NSError *error) {
        reject(@"Could not find the image",@"Could not find the image",nil);
    }];
    
}

//等比例缩小
-(UIImage *)scaleImageWithImage:(UIImage *)image toSize:(CGSize)size
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

#pragma mark  RongCloud  Send Voice Messages
/**
 *  录音开始
 */
RCT_EXPORT_METHOD(voiceBtnPressIn:(int)type
                  targetId:(NSString *)targetId
                  pushContent:(NSString *)pushContent
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    NSLog(@"开始录音");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
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
        
        
        _recorder = [[AVAudioRecorder alloc] initWithURL:self.recordFileUrl settings:recordSetting error:nil];
        
        if (_recorder) {
            
            @try{
                
                _startDate = [NSDate date];
                
                _recorder.meteringEnabled = YES;
                [_recorder prepareToRecord];
                [_recorder record];
                
                _isSend = NO;
                _duration = 0;
                
                _longTimer = [NSTimer scheduledTimerWithTimeInterval:59.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
                    if(!_isSend){
                        [self stopRecord:type targetId:targetId pushContent:pushContent resolve:resolve reject:reject];
                    }
                }];
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

/**
 *  取消录音
 */
RCT_EXPORT_METHOD(voiceBtnPressCancel:(int)type
                  targetId:(NSString *)targetId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self removeTimer];
        NSLog(@"取消录音");
        
        _isSend = NO;
        if ([self.recorder isRecording]) {
            [self.recorder stop];
            self.recorder = nil;
            
            resolve(@"已取消");
        }else{
            reject(@"没有正在录音的资源",@"没有正在录音的资源",nil);
        }
    });
}

/**
 *  录音结束
 */
RCT_EXPORT_METHOD(voiceBtnPressOut:(int)type
                  targetId:(NSString *)targetId
                  pushContent:(NSString *)pushContent
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if(!_isSend){
            [self stopRecord:type targetId:targetId pushContent:pushContent resolve:resolve reject:reject];
        }
    });
}

- (void)stopRecord:(int)type
          targetId:(NSString *)targetId
       pushContent:(NSString *)pushContent
           resolve:(RCTPromiseResolveBlock)resolve
            reject:(RCTPromiseRejectBlock)reject{
    
    [self removeTimer];
    NSLog(@"停止录音");
    
    if ([self.recorder isRecording]) {
        [self.recorder stop];
        self.recorder = nil;
    }
    
    _isSend = YES;
    
    _endDate = [NSDate date];
    
    NSTimeInterval dataLong = [_endDate timeIntervalSinceDate:_startDate];
    
    if(dataLong < 1.0){
        reject(@"-500",@"-500",nil);
    }else{
        
        _duration = (NSInteger)roundf(dataLong);
        
        NSData * audioData = [NSData dataWithContentsOfURL:self.recordFileUrl];
        [self sendVoiceMessage:type targetId:targetId content:audioData duration:_duration pushContent:pushContent resolve:resolve reject:reject];
        
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
    if(_longTimer){
        [_longTimer invalidate];
        _longTimer = nil;
    }
}

- (void)sendVoiceMessage:(int)type
                targetId:(NSString *)targetId
                 content:(NSData *)voiceData
                duration:(NSInteger )duration
             pushContent:(NSString *)pushContent
                 resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject {
    
    RCVoiceMessage *rcVoiceMessage = [RCVoiceMessage messageWithAudio:voiceData duration:duration];
    [self sendMessage:type messageType:@"voice" targetId:targetId content:rcVoiceMessage pushContent:pushContent resolve:resolve reject:reject];
    
}

#pragma mark  RongCloud  Play Voice Messages

RCT_EXPORT_METHOD(audioPlayStart:(NSString *)filePath
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject){
    
    self.session =[AVAudioSession sharedInstance];
    NSError *sessionError;
    [self.session setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
    [self.session setActive:YES error:nil];
    
    if(_player){
        [_player stop];
        _player = nil;
    }
    
    NSURL *audioUrl = [NSURL fileURLWithPath:filePath];
    NSError *playerError;
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:audioUrl error:&playerError];
    
    if (_player == nil)
    {
        NSLog(@"fail to play audio :(");
        reject(@"播放失败，请重试！",@"播放失败，请重试！",nil);
        return;
    }
    
    [_player setNumberOfLoops:0];
    [_player prepareToPlay];
    [_player play];
    resolve(@"正在播放");
}


RCT_REMAP_METHOD(audioPlayStop,
                 resolve:(RCTPromiseResolveBlock)resolve
                 rejecte:(RCTPromiseRejectBlock)reject){
    if(_player && [_player isPlaying]){
        [_player stop];
        resolve(@"已停止");
    }else{
        reject(@"没有播放的资源",@"没有播放的资源",nil);
    }
}

#pragma mark  RongCloud PushNotification Settting

RCT_EXPORT_METHOD(setConversationNotificationStatus:(int)type
                  targetId:(NSString *)targetId
                  isBlocked:(BOOL)isBlocked
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    void (^successBlock)(NSUInteger RCConversationNotificationStatus);
    successBlock = ^(NSUInteger RCConversationNotificationStatus) {
        //0: 消息免打扰(DO_NOT_DISTURB)   1: 新消息提醒(NOTIFY)
        resolve(@(RCConversationNotificationStatus));
    };
    
    void (^errorBlock)(RCErrorCode nErrorCode);
    errorBlock = ^(RCErrorCode nErrorCode) {
        reject(@"设置失败", @"设置失败", nil);
    };
    
    [[self getClient] setConversationNotificationStatus:type targetId:targetId isBlocked:isBlocked success:successBlock error:errorBlock];
    
}

RCT_EXPORT_METHOD(getConversationNotificationStatus:(int)type
                  targetId:(NSString *)targetId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    void (^successBlock)(NSUInteger RCConversationNotificationStatus);
    successBlock = ^(NSUInteger RCConversationNotificationStatus) {
        //0: 消息免打扰(DO_NOT_DISTURB)   1: 新消息提醒(NOTIFY)
        resolve(@(RCConversationNotificationStatus));
    };
    
    void (^errorBlock)(RCErrorCode nErrorCode);
    errorBlock = ^(RCErrorCode nErrorCode) {
        reject(@"获取失败", @"获取失败", nil);
    };
    
    [[self getClient] getConversationNotificationStatus:type targetId:targetId success:successBlock error:errorBlock];
}



RCT_REMAP_METHOD(screenGlobalNotification,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
    
    void (^successBlock)();
    successBlock = ^() {
        resolve(@(YES));
    };
    
    void (^errorBlock)(RCErrorCode nErrorCode);
    errorBlock = ^(RCErrorCode nErrorCode) {
        reject(@"设置失败", @"设置失败", nil);
    };
    
    [[self getClient] setNotificationQuietHours:@"00:00:00" spanMins:1439 success:successBlock error:errorBlock];
}

RCT_REMAP_METHOD(removeScreenOfGlobalNotification,
                 removeResolver:(RCTPromiseResolveBlock)resolve
                 removeRejecter:(RCTPromiseRejectBlock)reject) {
    
    void (^successBlock)();
    successBlock = ^() {
        resolve(@(YES));
    };
    
    void (^errorBlock)(RCErrorCode nErrorCode);
    errorBlock = ^(RCErrorCode nErrorCode) {
        reject(@"设置失败", @"设置失败", nil);
    };
    
    [[self getClient] removeNotificationQuietHours:successBlock error:errorBlock];
}

RCT_REMAP_METHOD(getGlobalNotificationStatus,
                 statusResolver:(RCTPromiseResolveBlock)resolve
                 statusRejecter:(RCTPromiseRejectBlock)reject) {
    
    void (^successBlock)(NSString *startTime, int spansMin);
    successBlock = ^(NSString *startTime, int spansMin) {
        
        if(spansMin > 0){
            resolve(@(YES));
        }else{
            resolve(@(NO));
        }
    };
    
    void (^errorBlock)(RCErrorCode nErrorCode);
    errorBlock = ^(RCErrorCode nErrorCode) {
        reject(@"获取失败", @"获取失败", nil);
    };
    
    [[self getClient] getNotificationQuietHours:successBlock error:errorBlock];
}

#pragma mark  RongCloud  GetSDKVersion  and   Disconnect

RCT_REMAP_METHOD(getSDKVersion,
                 versionResolver:(RCTPromiseResolveBlock)resolve
                 versionRejecter:(RCTPromiseRejectBlock)reject) {
    NSString* version = [[self getClient] getSDKVersion];
    resolve(version);
}

RCT_EXPORT_METHOD(disconnect:(BOOL)isReceivePush) {
    [[self getClient] disconnect:isReceivePush];
}


#pragma mark  RongCloud  SDK methods

-(RCIMClient *) getClient {
    return [RCIMClient sharedRCIMClient];
}

-(void)sendMessage:(int)type
       messageType:(NSString *)messageType
          targetId:(NSString *)targetId
           content:(RCMessageContent *)content
       pushContent:(NSString *) pushContent
           resolve:(RCTPromiseResolveBlock)resolve
            reject:(RCTPromiseRejectBlock)reject {
    
    RCConversationType conversationType;
    switch (type) {
        case 1:
            conversationType = ConversationType_PRIVATE;
            break;
        case 3:
            conversationType = ConversationType_GROUP;
            break;
            
        default:
            conversationType = ConversationType_PRIVATE;
            break;
    }
    
    void (^successBlock)(long messageId);
    successBlock = ^(long messageId) {
        NSString* messageid = [NSString stringWithFormat:@"%ld",messageId];
        resolve(messageid);
    };
    
    void (^errorBlock)(RCErrorCode nErrorCode , long messageId);
    errorBlock = ^(RCErrorCode nErrorCode , long messageId) {
        reject(@"发送失败", @"发送失败", nil);
    };
    
    if ([messageType isEqualToString:@"image"]){  //图片和文件消息使用sendMediaMessage方法（此方法会将图片上传至融云服务器）
        [[self getClient] sendMediaMessage:conversationType targetId:targetId content:content pushContent:pushContent pushData:nil progress:nil success:successBlock error:errorBlock cancel:nil];
    }else{  //文本和语音使用sendMessage方法（若使用本方法发送图片消息，则需要上传图片到自己的服务器后把图片地址放到图片消息内）
        [[self getClient] sendMessage:conversationType targetId:targetId content:content pushContent:pushContent pushData:nil success:successBlock error:errorBlock];
    }
    
}

-(void)onReceived:(RCMessage *)message
             left:(int)nLeft
           object:(id)object {
    
    NSLog(@"onRongCloudMessageReceived");
    
    NSMutableDictionary *body = [self getEmptyBody];
    NSMutableDictionary *_message = [self getEmptyBody];
    
    _message[@"targetId"] = message.targetId;
    _message[@"senderUserId"] = message.senderUserId;
    _message[@"messageId"] = [NSString stringWithFormat:@"%ld",message.messageId];
    _message[@"sentTime"] = @((long long)message.sentTime);
    _message[@"receivedTime"] = @((long long)message.receivedTime);
    _message[@"senderUserId"] = message.senderUserId;
    _message[@"conversationType"] = @((unsigned long)message.conversationType);
    _message[@"messageDirection"] = @(message.messageDirection);
    _message[@"objectName"] = message.objectName;
    _message[@"extra"] = message.extra;
    
    if ([message.content isMemberOfClass:[RCTextMessage class]]) {
        RCTextMessage *textMessage = (RCTextMessage *)message.content;
        _message[@"type"] = @"text";
        _message[@"content"] = textMessage.content;
        _message[@"extra"] = textMessage.extra;
    }
    else if([message.content isMemberOfClass:[RCImageMessage class]]) {
        RCImageMessage *imageMessage = (RCImageMessage *)message.content;
        _message[@"type"] = @"image";
        _message[@"imageUrl"] = imageMessage.imageUrl;
        _message[@"thumbnailImage"] = imageMessage.thumbnailImage;
        _message[@"extra"] = imageMessage.extra;
    }
    else if ([message.content isMemberOfClass:[RCVoiceMessage class]]) {
        RCVoiceMessage *voiceMessage = (RCVoiceMessage *)message.content;
        _message[@"type"] = @"voice";
        _message[@"wavAudioData"] = voiceMessage.wavAudioData;
        _message[@"duration"] = @(voiceMessage.duration);
        _message[@"extra"] = voiceMessage.extra;
    }
    
    
    body[@"left"] = [NSString stringWithFormat:@"%d",nLeft];
    body[@"message"] = _message;
    body[@"errcode"] = @"0";
    
    [self sendEventWithName:@"onRongMessageReceived" body:body];
}

-(NSMutableDictionary *)getEmptyBody {
    NSMutableDictionary *body = @{}.mutableCopy;
    return body;
}


@end

