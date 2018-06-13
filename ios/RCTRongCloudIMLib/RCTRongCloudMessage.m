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
@property (nonatomic, copy) NSString *pushData;
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

#pragma mark Messages

+ (NSMutableArray *)getConversation:(NSArray *)conversationList{
    NSMutableArray * array = [NSMutableArray new];
    for  (RCConversation * conversation in conversationList) {
        NSMutableDictionary * dict = [NSMutableDictionary new];
        dict[@"conversationType"] = @((unsigned long)conversation.conversationType);
        dict[@"targetId"] = conversation.targetId;
        dict[@"conversationTitle"] = conversation.conversationTitle;
        dict[@"unreadMessageCount"] = @(conversation.unreadMessageCount);
        dict[@"isTop"] = @(conversation.isTop);
        dict[@"hasUnreadMentioned"] = @(conversation.hasUnreadMentioned);
        dict[@"receivedStatus"] = @((unsigned long)conversation.receivedStatus);
        dict[@"sentStatus"] = @((unsigned long)conversation.sentStatus);
        dict[@"receivedTime"] = @((long long)conversation.receivedTime);
        dict[@"sentTime"] = @((long long)conversation.sentTime);
        dict[@"draft"] = conversation.draft;
        dict[@"objectName"] = conversation.objectName;
        dict[@"senderUserId"] = conversation.senderUserId;
        dict[@"lastestMessageId"] = @(conversation.lastestMessageId);
        dict[@"lastestMessageDirection"] = @(conversation.lastestMessageDirection);
        dict[@"jsonDict"] = conversation.jsonDict;
        if ([conversation.lastestMessage isKindOfClass:[RCTextMessage class]]) {
            RCTextMessage *textMsg = (RCTextMessage *)conversation.lastestMessage;
            dict[@"msgType"] = @"text";
            dict[@"lastestMessage"] = textMsg.content;
            dict[@"extra"] = textMsg.extra;
            if (textMsg.mentionedInfo) {
                dict[@"mentionedType"] = @(textMsg.mentionedInfo.type);
                dict[@"userIdList"] = textMsg.mentionedInfo.userIdList;
                dict[@"mentionedContent"] = textMsg.mentionedInfo.mentionedContent;
                dict[@"isMentionedMe"] = @(textMsg.mentionedInfo.isMentionedMe);
            }
        } else if ([conversation.lastestMessage isKindOfClass:[RCImageMessage class]]) {
            RCImageMessage *imageMsg = (RCImageMessage *)conversation.lastestMessage;
            dict[@"msgType"] = @"image";
            dict[@"extra"] = imageMsg.extra;
            dict[@"imageUrl"] = imageMsg.imageUrl;
        } else if ([conversation.lastestMessage isKindOfClass:[RCVoiceMessage class]]) {
            RCVoiceMessage *voiceMsg = (RCVoiceMessage *)conversation.lastestMessage;
            dict[@"msgType"] = @"voice";
            dict[@"extra"] = voiceMsg.extra;
            dict[@"duration"] = @(voiceMsg.duration);
        } else if ([conversation.lastestMessage isKindOfClass:[RCRecallNotificationMessage class]]) {
            RCRecallNotificationMessage *recallMsg = (RCRecallNotificationMessage *)conversation.lastestMessage;
            dict[@"type"] = @"recall";
            dict[@"operatorId"] = recallMsg.operatorId;
            dict[@"recallTime"] = @(recallMsg.recallTime);
            dict[@"originalObjectName"] = recallMsg.originalObjectName;
        }
        
        [array addObject:dict];
    }
    return array;
}

/*!
 获取会话列表
 
 @param conversationTypeList 会话类型的数组(需要将RCConversationType转为NSNumber构建Array)
 */
+ (void)getConversationList:(void (^)(NSArray *array))successBlock error:(void (^)())errorBlock{
    NSArray *conversationList = [[self getClient] getConversationList:@[@(ConversationType_PRIVATE),@(ConversationType_GROUP)]];
    if(conversationList.count > 0){
        successBlock([self getConversation:conversationList]);
    } else {
        errorBlock();
    }
}

/*!
 根据关键字搜索会话
 
 @param keyword              关键字
 */
+ (void)searchConversations:(NSString *)keyword
                    success:(void (^)(NSArray *array))successBlock
                      error:(void (^)())errorBlock{
    
    NSArray *SearchResult = [[self getClient] searchConversations:@[@(ConversationType_PRIVATE),@(ConversationType_GROUP)] messageType:@[[RCTextMessage getObjectName]] keyword:keyword];
    
    if(SearchResult.count > 0){
        NSMutableArray * array = [NSMutableArray new];
        for  (RCSearchConversationResult * result in SearchResult) {
            NSMutableDictionary * dict = [NSMutableDictionary new];
            dict[@"conversationType"] = @((unsigned long)result.conversation.conversationType);
            dict[@"targetId"] = result.conversation.targetId;
            dict[@"conversationTitle"] = result.conversation.conversationTitle;
            dict[@"unreadMessageCount"] = @(result.conversation.unreadMessageCount);
            dict[@"isTop"] = @(result.conversation.isTop);
            dict[@"hasUnreadMentioned"] = @(result.conversation.hasUnreadMentioned);
            dict[@"receivedStatus"] = @((unsigned long)result.conversation.receivedStatus);
            dict[@"sentStatus"] = @((unsigned long)result.conversation.sentStatus);
            dict[@"receivedTime"] = @((long long)result.conversation.receivedTime);
            dict[@"sentTime"] = @((long long)result.conversation.sentTime);
            dict[@"draft"] = result.conversation.draft;
            dict[@"objectName"] = result.conversation.objectName;
            dict[@"senderUserId"] = result.conversation.senderUserId;
            dict[@"lastestMessageId"] = @(result.conversation.lastestMessageId);
            dict[@"lastestMessageDirection"] = @(result.conversation.lastestMessageDirection);
            dict[@"jsonDict"] = result.conversation.jsonDict;
            if ([result.conversation.lastestMessage isKindOfClass:[RCTextMessage class]]) {
                RCTextMessage *textMsg = (RCTextMessage *)result.conversation.lastestMessage;
                dict[@"msgType"] = @"text";
                dict[@"lastestMessage"] = textMsg.content;
                dict[@"extra"] = textMsg.extra;
                if (textMsg.mentionedInfo) {
                    dict[@"mentionedType"] = @(textMsg.mentionedInfo.type);
                    dict[@"userIdList"] = textMsg.mentionedInfo.userIdList;
                    dict[@"mentionedContent"] = textMsg.mentionedInfo.mentionedContent;
                    dict[@"isMentionedMe"] = @(textMsg.mentionedInfo.isMentionedMe);
                }
            } else if ([result.conversation.lastestMessage isKindOfClass:[RCImageMessage class]]) {
                RCImageMessage *imageMsg = (RCImageMessage *)result.conversation.lastestMessage;
                dict[@"msgType"] = @"image";
                dict[@"extra"] = imageMsg.extra;
                dict[@"imageUrl"] = imageMsg.imageUrl;
            } else if ([result.conversation.lastestMessage isKindOfClass:[RCVoiceMessage class]]) {
                RCVoiceMessage *voiceMsg = (RCVoiceMessage *)result.conversation.lastestMessage;
                dict[@"msgType"] = @"voice";
                dict[@"extra"] = voiceMsg.extra;
                dict[@"duration"] = @(voiceMsg.duration);
            } else if ([result.conversation.lastestMessage isKindOfClass:[RCRecallNotificationMessage class]]) {
                RCRecallNotificationMessage *recallMsg = (RCRecallNotificationMessage *)result.conversation.lastestMessage;
                dict[@"type"] = @"recall";
                dict[@"operatorId"] = recallMsg.operatorId;
                dict[@"recallTime"] = @(recallMsg.recallTime);
                dict[@"originalObjectName"] = recallMsg.originalObjectName;
            }
            
            [array addObject:dict];
        }
        NSLog(@"SearchResultList === %@",array);
        successBlock(array);
    }else{
        errorBlock();
    }
}



+ (NSMutableArray *)getMessageList:(NSArray *)messageList{
    NSMutableArray * array = [NSMutableArray new];
    for (RCMessage * message in messageList) {
        NSMutableDictionary * dict = [NSMutableDictionary new];
        dict[@"conversationType"] = @((unsigned long)message.conversationType);
        dict[@"targetId"] = message.targetId;
        dict[@"messageId"] = @(message.messageId);
        dict[@"receivedTime"] = @((long long)message.receivedTime);
        dict[@"sentTime"] = @((long long)message.sentTime);
        dict[@"receivedStatus"] = @((unsigned long)message.receivedStatus);
        dict[@"sentStatus"] = @((unsigned long)message.sentStatus);
        dict[@"objectName"] = message.objectName;
        dict[@"senderUserId"] = message.senderUserId;
        dict[@"messageUId"] = message.messageUId;
        dict[@"messageDirection"] = @(message.messageDirection);
        if([message.content isKindOfClass:[RCTextMessage class]]){
            RCTextMessage *textMsg = (RCTextMessage *)message.content;
            dict[@"type"] = @"text";
            dict[@"content"] = textMsg.content;
            dict[@"extra"] = textMsg.extra;
            if (textMsg.mentionedInfo) {
                dict[@"mentionedType"] = @(textMsg.mentionedInfo.type);
                dict[@"userIdList"] = textMsg.mentionedInfo.userIdList;
                dict[@"mentionedContent"] = textMsg.mentionedInfo.mentionedContent;
                dict[@"isMentionedMe"] = @(textMsg.mentionedInfo.isMentionedMe);
            }
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
        else if ([message.content isKindOfClass:[RCRecallNotificationMessage class]]){
            RCRecallNotificationMessage *recallMsg = (RCRecallNotificationMessage *)message.content;
            dict[@"type"] = @"recall";
            dict[@"operatorId"] = recallMsg.operatorId;
            dict[@"recallTime"] = @(recallMsg.recallTime);
            dict[@"originalObjectName"] = recallMsg.originalObjectName;
        }
        [array addObject:dict];
    }
    return array;
}

+ (NSString *)saveWavAudioDataToSandbox:(NSData *)data messageId:(NSInteger)msgId{
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    NSString * documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString * directoryPath = [documentPath stringByAppendingString:@"/ChatMessage"];
    
    if(![fileManager fileExistsAtPath:directoryPath]){
        
        [fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    
    NSString * filePath = [directoryPath stringByAppendingString:[NSString stringWithFormat:@"/%ld.wav",(long)msgId]];
    
    [fileManager createFileAtPath:filePath contents:data attributes:nil];
    
    return filePath;
}


/*!
 获取某个会话中指定数量的最新消息实体
 
 @param conversationType    会话类型
 @param targetId            目标会话ID
 @param count               需要获取的消息数量
 */
+ (void)getLatestMessages:(int)type
                 targetId:(NSString *)targetId
                    count:(int)count
                  success:(void (^)(NSArray *array))successBlock
                    error:(void (^)())errorBlock{
    
    RCConversationType conversationType = [self getConversationType:type];
    
    NSArray * messageList = [[self getClient] getLatestMessages:conversationType targetId:targetId count:count];
    if(messageList){
        NSLog(@"MessagesList === %@",messageList);
        successBlock([self getMessageList:messageList]);
    }
    else{
        errorBlock();
    }
}

/*!
 获取会话中，从指定消息之前、指定数量的最新消息实体
 
 @param conversationType    会话类型
 @param targetId            目标会话ID
 @param oldestMessageId     截止的消息ID
 @param count               需要获取的消息数量
 */
+ (void)getHistoryMessages:(int)type
                  targetId:(NSString *)targetId
           oldestMessageId:(int)oldestMessageId
                     count:(int)count
                   success:(void (^)(NSArray *array))successBlock
                     error:(void (^)())errorBlock{
    
    RCConversationType conversationType = [self getConversationType:type];
    
    NSArray * messageList = [[self getClient] getHistoryMessages:conversationType targetId:targetId oldestMessageId:oldestMessageId count:count];
    if(messageList){
        successBlock([self getMessageList:messageList]);
    }
    else{
        errorBlock();
    }
}

/*!
 获取会话中，从指定消息之前、指定数量的、指定消息类型的最新消息实体
 
 @param conversationType    会话类型
 @param targetId            目标会话ID
 @param objectName          消息内容的类型名，如果想取全部类型的消息请传 nil
 @param oldestMessageId     截止的消息ID
 @param count               需要获取的消息数量
 */
+ (void)getDesignatedTypeHistoryMessages:(int)type
                                targetId:(NSString *)targetId
                              objectName:(NSString *)objectName
                         oldestMessageId:(int)oldestMessageId
                                   count:(int)count
                                 success:(void (^)(NSArray *array))successBlock
                                   error:(void (^)())errorBlock{
    
    RCConversationType conversationType = [self getConversationType:type];
    
    NSArray * messageList = [[self getClient] getHistoryMessages:conversationType targetId:targetId objectName:objectName oldestMessageId:oldestMessageId count:count];
    if(messageList){
        successBlock([self getMessageList:messageList]);
    }
    else{
        errorBlock();
    }
}

/*!
 获取会话中，指定消息、指定数量、指定消息类型、向前或向后查找的消息实体列表
 
 @param conversationType    会话类型
 @param targetId            目标会话ID
 @param objectName          消息内容的类型名，如果想取全部类型的消息请传 nil
 @param baseMessageId       当前的消息ID
 @param isForward           查询方向 true为向前，false为向后
 @param count               需要获取的消息数量
 */
+ (void)getDesignatedDirectionypeHistoryMessages:(int)type
                                        targetId:(NSString *)targetId
                                      objectName:(NSString *)objectName
                                   baseMessageId:(int)baseMessageId
                                           count:(int)count
                                       direction:(BOOL)direction
                                         success:(void (^)(NSArray *array))successBlock
                                           error:(void (^)())errorBlock{
    
    RCConversationType conversationType = [self getConversationType:type];
    
    NSArray * messageList = [[self getClient] getHistoryMessages:conversationType targetId:targetId objectName:objectName baseMessageId:baseMessageId isForward:direction count:count];
    if(messageList){
        successBlock([self getMessageList:messageList]);
    }
    else{
        errorBlock();
    }
}

/*!
 在会话中搜索指定消息的前 beforeCount 数量和后 afterCount
 数量的消息。返回的消息列表中会包含指定的消息。消息列表时间顺序从旧到新。
 
 @param conversationType    会话类型
 @param targetId            目标会话ID
 @param sentTime            消息的发送时间
 @param beforeCount         指定消息的前部分消息数量
 @param afterCount          指定消息的后部分消息数量
 */
+ (void)getBaseOnSentTimeHistoryMessages:(int)type
                                targetId:(NSString *)targetId
                                sentTime:(long long)sentTime
                                  before:(int)before
                                   after:(int)after
                                 success:(void (^)(NSArray *array))successBlock
                                   error:(void (^)())errorBlock{
    
    RCConversationType conversationType = [self getConversationType:type];
    
    NSArray * messageList = [[self getClient] getHistoryMessages:conversationType targetId:targetId sentTime:sentTime beforeCount:before afterCount:after];
    if(messageList){
        successBlock([self getMessageList:messageList]);
    }
    else{
        errorBlock();
    }
}

#pragma mark Send Message

#pragma mark Text Message

+ (void)sendTextMessage:(int)type
               targetId:(NSString *)targetId
                content:(NSString *)content
            pushContent:(NSString *)pushContent
               pushData:(NSString *)pushData
                  extra:(NSString *)extra
                success:(void (^)(NSString *messageId))successBlock
                  error:(void (^)(RCErrorCode status, NSString *messageId))errorBlock{
    
    RCTextMessage *messageContent = [RCTextMessage messageWithContent:content];
    if(extra){
        messageContent.extra = extra;
    }
    [self sendMessage:type messageType:@"text" targetId:targetId content:messageContent pushContent:pushContent pushData:pushData success:successBlock error:errorBlock];
}

#pragma mark Image Message

+ (void)sendImageMessage:(int)type
                targetId:(NSString *)targetId
                imageUrl:(NSString *)imageUrl
             pushContent:(NSString *)pushContent
                pushData:(NSString *)pushData
                   extra:(NSString *)extra
                 success:(void (^)(NSString *messageId))successBlock
                   error:(void (^)(RCErrorCode status, NSString *messageId))errorBlock{
    
    if([imageUrl rangeOfString:@"assets-library"].location == NSNotFound){
        UIImage * image = nil;
        if([imageUrl rangeOfString:@"file://"].location != NSNotFound){
            NSData *data = [NSData dataWithContentsOfURL:[NSURL  URLWithString:imageUrl]];
            //转换为图片保存到以上的沙盒路径中
            image = [UIImage imageWithData:data];
        } else {
            image = [[UIImage alloc] initWithContentsOfFile:imageUrl];
        }
        // 融云推荐使用的大图尺寸为：960 x 960 像素
        UIImage * scaledImage = [self scaleImageWithImage:image toSize:CGSizeMake(960, 960)];
        RCImageMessage *imageMessage = [RCImageMessage messageWithImage:scaledImage];
        if(extra){
            imageMessage.extra = extra;
        }
        [self sendMessage:type messageType:@"image" targetId:targetId content:imageMessage pushContent:pushContent pushData:pushData success:successBlock error:errorBlock];
    }
    else{
        [self sendImageMessageWithType:type targetId:targetId ImageUrl:imageUrl pushContent:pushContent pushData:pushData extra:extra success:successBlock error:errorBlock];
    }
}

+ (void)sendImageMessageWithType:(int)type targetId:(NSString *)targetId ImageUrl:(NSString *)imageUrl  pushContent:(NSString *)pushContent pushData:(NSString *)pushData extra:(NSString *)extra success:(void (^)(NSString *messageId))successBlock error:(void (^)(RCErrorCode nErrorCode, NSString *messageId))errorBlock{
    
    ALAssetsLibrary   *lib = [[ALAssetsLibrary alloc] init];
    
    [lib assetForURL:[NSURL URLWithString:imageUrl] resultBlock:^(ALAsset *asset) {
        //在这里使用asset来获取图片
        ALAssetRepresentation *assetRep = [asset defaultRepresentation];
        CGImageRef imgRef = [assetRep fullResolutionImage];
        UIImage * image = [UIImage imageWithCGImage:imgRef
                                              scale:assetRep.scale
                                        orientation:(UIImageOrientation)assetRep.orientation];
        // 融云推荐使用的大图尺寸为：960 x 960 像素
        UIImage * scaledImage = [self scaleImageWithImage:image toSize:CGSizeMake(960, 960)];
        
        RCImageMessage *imageMessage = [RCImageMessage messageWithImage:scaledImage];
        if(extra){
            imageMessage.extra = extra;
        }
        [self sendMessage:type messageType:@"image" targetId:targetId content:imageMessage pushContent:pushContent pushData:pushData success:successBlock error:errorBlock];
        
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
               pushData:(NSString *)pushData
                  extra:(NSString *)extra{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.type = type;
        self.targetId = targetId;
        self.pushContent = pushContent;
        self.pushData = pushData;
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
                pushData:(NSString *)pushData
                   extra:(NSString *)extra
                 success:(void (^)(NSString *messageId))successBlock
                   error:(void (^)(RCErrorCode status, NSString *messageId))errorBlock{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.type = type;
        self.targetId = targetId;
        self.pushContent = pushContent;
        self.pushData = pushData;
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
        self.type = 1;
        self.targetId = @"";
        self.pushContent = @"";
        self.pushData = @"";
        self.extra = @"";
        
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
    
    [self stopRecord:^(NSString *messageId) {
        if(self.successBlock) {
            self.successBlock(messageId);
        }
    } error:^(RCErrorCode status, NSString *messageId) {
        if(self.errorBlock) {
            self.errorBlock(status, messageId);
        }
    }];
}

- (void)stopRecord:(void (^)(NSString *messageId))successBlock
             error:(void (^)(RCErrorCode status, NSString *messageId))errorBlock{
    
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
        [self sendVoiceMessage:self.type targetId:self.targetId content:audioData duration:self.duration pushContent:self.pushContent pushData:self.pushData extra:self.extra success:successBlock error:errorBlock];
        
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
                pushData:(NSString *)pushData
                   extra:(NSString *)extra
                 success:(void (^)(NSString *messageId))successBlock
                   error:(void (^)(RCErrorCode status, NSString *messageId))errorBlock {
    
    RCVoiceMessage *rcVoiceMessage = [RCVoiceMessage messageWithAudio:voiceData duration:duration];
    if (extra){
        rcVoiceMessage.extra = extra;
    }
    
    [RCTRongCloudMessage sendMessage:type messageType:@"voice" targetId:targetId content:rcVoiceMessage pushContent:pushContent pushData:pushData success:successBlock error:errorBlock];
    
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
           pushData:(NSString *)pushData
            success:(void (^)(NSString *messageId))successBlock
              error:(void (^)(RCErrorCode status, NSString *messageId))errorBlock {
    
    RCConversationType conversationType = [self getConversationType:type];
    
    if ([messageType isEqualToString:@"image"]) {
        //图片和文件消息使用sendMediaMessage方法（此方法会将图片上传至融云服务器）
        [[self getClient] sendMediaMessage:conversationType targetId:targetId content:content pushContent:pushContent pushData:pushData progress:nil success:^(long messageId) {
            NSString * message = [NSString stringWithFormat:@"%ld",messageId];
            successBlock(message);
        } error:^(RCErrorCode nErrorCode, long messageId) {
            NSString * message = [NSString stringWithFormat:@"%ld",messageId];
            errorBlock(nErrorCode, message);
        } cancel:nil];
    } else {
        //文本和语音使用sendMessage方法（若使用本方法发送图片消息，则需要上传图片到自己的服务器后把图片地址放到图片消息内）
        [[self getClient] sendMessage:conversationType targetId:targetId content:content pushContent:pushContent pushData:pushData success:^(long messageId) {
            NSString * message = [NSString stringWithFormat:@"%ld",messageId];
            successBlock(message);
        } error:^(RCErrorCode nErrorCode, long messageId) {
            NSString * message = [NSString stringWithFormat:@"%ld",messageId];
            errorBlock(nErrorCode, message);
        }];
    }
    
}

#pragma mark Recall Message 撤回消息

+ (void)recallMessage:(NSDictionary *)message
                 push:(NSString *)push
              success:(void (^)(NSString *messageId))successBlock
                error:(void (^)(RCErrorCode status))errorBlock{
    
    RCConversationType conversationType = [self getConversationType:[message[@"conversationType"] intValue]];
    RCMessageDirection direction = [message[@"messageDirection"] intValue] == 1 ? MessageDirection_SEND : MessageDirection_RECEIVE;
    
    RCTextMessage * textMessage = [RCTextMessage messageWithContent:message[@"content"]];
    textMessage.extra = message[@"extra"];
    
    RCMessage * recallMessage = [[RCMessage alloc] initWithType:conversationType targetId:[NSString stringWithFormat:@"%@",message[@"targetId"]] direction:direction messageId:[message[@"messageId"] longValue] content:textMessage];
    recallMessage.objectName = message[@"objectName"];
    recallMessage.senderUserId = [NSString stringWithFormat:@"%@",message[@"senderUserId"]];
    recallMessage.messageUId = message[@"messageUId"];
    recallMessage.sentTime = [message[@"sentTime"] longLongValue];
    recallMessage.receivedTime = [message[@"receivedTime"] longLongValue];
    
    [[self getClient] recallMessage:recallMessage pushContent:push success:^(long messageId) {
        NSString * message = [NSString stringWithFormat:@"%ld",messageId];
        successBlock(message);
    } error:^(RCErrorCode errorcode) {
        errorBlock(errorcode);
    }];
}

@end
