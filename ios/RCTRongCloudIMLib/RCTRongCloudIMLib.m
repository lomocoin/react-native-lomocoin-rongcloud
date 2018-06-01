//
//  RCTRongCloudIMLib.m
//  RCTRongCloudIMLib
//
//  Created by lomocoin on 10/21/2017.
//  Copyright © 2017 lomocoin.com. All rights reserved.
//

#import "RCTRongCloudIMLib.h"

#import "RCTRongCloudDiscussion.h"
#import "RCTRongCloudMessage.h"

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
        NSString *errcode = [self getRCConnectErrorCode:status];
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
    
    RCConversationType conversationType = [self getConversationType:type];
    int unreadCount = [[self getClient] getUnreadCount:conversationType targetId:targetId];
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
    
    RCConversationType conversationType = [self getConversationType:type];
    
    [[self getClient] clearMessagesUnreadStatus:conversationType targetId:targetId];
}

#pragma mark  RongCloud  Discussion

RCT_EXPORT_METHOD(createDiscussion:(NSString *)name
                  userIdList:(NSArray *)userIdList
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    [RCTRongCloudDiscussion createDiscussion:name userIdList:userIdList success:^(NSDictionary *discussionDic) {
        resolve(discussionDic);
    } error:^(RCErrorCode status) {
        reject([self getRCErrorCode:status],[self getRCErrorCode:status],nil);
    }];
}

RCT_EXPORT_METHOD(addMemberToDiscussion:(NSString *)discussionId
                  userIdList:(NSArray *)userIdList
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    [RCTRongCloudDiscussion addMemberToDiscussion:discussionId userIdList:userIdList success:^(NSDictionary *discussionDic) {
        resolve(discussionDic);
    } error:^(RCErrorCode status) {
        reject([self getRCErrorCode:status],[self getRCErrorCode:status],nil);
    }];
}

RCT_EXPORT_METHOD(removeMemberFromDiscussion:(NSString *)discussionId
                  userId:(NSString *)userId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    [RCTRongCloudDiscussion removeMemberFromDiscussion:discussionId userId:userId success:^(NSDictionary *discussionDic) {
        resolve(discussionDic);
    } error:^(RCErrorCode status) {
        reject([self getRCErrorCode:status],[self getRCErrorCode:status],nil);
    }];
}

RCT_EXPORT_METHOD(quitDiscussion:(NSString *)discussionId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    [RCTRongCloudDiscussion quitDiscussion:discussionId success:^(NSDictionary *discussionDic) {
        resolve(discussionDic);
    } error:^(RCErrorCode status) {
        reject([self getRCErrorCode:status],[self getRCErrorCode:status],nil);
    }];
}

RCT_EXPORT_METHOD(getDiscussion:(NSString *)discussionId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    [RCTRongCloudDiscussion getDiscussion:discussionId success:^(NSDictionary *discussionDic) {
        resolve(discussionDic);
    } error:^(RCErrorCode status) {
        reject([self getRCErrorCode:status],[self getRCErrorCode:status],nil);
    }];
}

RCT_EXPORT_METHOD(setDiscussionName:(NSString *)discussionId
                  name:(NSString *)name
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    [RCTRongCloudDiscussion setDiscussionName:discussionId name:name success:^(BOOL success) {
        resolve(@(success));
    } error:^(RCErrorCode status) {
        reject([self getRCErrorCode:status],[self getRCErrorCode:status],nil);
    }];
}

RCT_EXPORT_METHOD(setDiscussionInviteStatus:(NSString *)discussionId
                  isOpen:(BOOL)isOpen
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    [RCTRongCloudDiscussion setDiscussionInviteStatus:discussionId isOpen:isOpen success:^(BOOL success) {
        resolve(@(success));
    } error:^(RCErrorCode status) {
        reject([self getRCErrorCode:status],[self getRCErrorCode:status],nil);
    }];
}


#pragma mark  RongCloud  Messages Operation

RCT_REMAP_METHOD(getConversationList,
                 resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject) {
    
    [RCTRongCloudMessage getConversationList:^(NSArray *array) {
        resolve(array);
    } error:^{
        reject(@"读取失败", @"读取失败", nil);
    }];
}

RCT_REMAP_METHOD(searchConversations,
                 keyword:(NSString *)keyword
                 resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject) {
    
    [RCTRongCloudMessage searchConversations:keyword success:^(NSArray *array) {
        resolve(array);
    } error:^{
        reject(@"读取失败", @"读取失败", nil);
    }];
}

RCT_REMAP_METHOD(getLatestMessages,
                 type:(int)type
                 targetId:(NSString *)targetId
                 count:(int)count
                 resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject) {
    
    [RCTRongCloudMessage getLatestMessages:type targetId:targetId count:count success:^(NSArray *array) {
        resolve(array);
    } error:^{
        reject(@"读取失败", @"读取失败", nil);
    }];
}

RCT_REMAP_METHOD(getHistoryMessages,
                 type:(int)type
                 targetId:(NSString *)targetId
                 oldestMessageId:(int)oldestMessageId
                 count:(int)count
                 resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject) {
    
    [RCTRongCloudMessage getHistoryMessages:type targetId:targetId oldestMessageId:oldestMessageId count:count success:^(NSArray *array) {
        resolve(array);
    } error:^{
        reject(@"读取失败", @"读取失败", nil);
    }];
}

RCT_REMAP_METHOD(getDesignatedTypeHistoryMessages,
                 type:(int)type
                 targetId:(NSString *)targetId
                 objectName:(NSString *)objectName
                 oldestMessageId:(int)oldestMessageId
                 count:(int)count
                 resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject) {
    
    [RCTRongCloudMessage getDesignatedTypeHistoryMessages:type targetId:targetId objectName:objectName oldestMessageId:oldestMessageId count:count success:^(NSArray *array) {
        resolve(array);
    } error:^{
        reject(@"读取失败", @"读取失败", nil);
    }];
}

RCT_REMAP_METHOD(getDesignatedDirectionypeHistoryMessages,
                 type:(int)type
                 targetId:(NSString *)targetId
                 objectName:(NSString *)objectName
                 baseMessageId:(int)baseMessageId
                 count:(int)count
                 direction:(BOOL)direction
                 resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject) {
    
    [RCTRongCloudMessage getDesignatedDirectionypeHistoryMessages:type targetId:targetId objectName:objectName baseMessageId:baseMessageId count:count direction:direction success:^(NSArray *array) {
        resolve(array);
    } error:^{
        reject(@"读取失败", @"读取失败", nil);
    }];
}

RCT_REMAP_METHOD(getBaseOnSentTimeHistoryMessages,
                 type:(int)type
                 targetId:(NSString *)targetId
                 sentTime:(long long)sentTime
                 before:(int)before
                 after:(int)after
                 resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject) {
    
    [RCTRongCloudMessage getBaseOnSentTimeHistoryMessages:type targetId:targetId sentTime:sentTime before:before after:after success:^(NSArray *array) {
        resolve(array);
    } error:^{
        reject(@"读取失败", @"读取失败", nil);
    }];
}

#pragma mark  RongCloud  DeleteMessages

RCT_EXPORT_METHOD(deleteTargetMessages:(int)type
                  targetId:(NSString *)targetId
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    RCConversationType conversationType = [self getConversationType:type];
    
    void (^successBlock)(void);
    successBlock = ^() {
        resolve(@"删除成功");
    };
    
    [[self getClient] deleteMessages:conversationType targetId:targetId success:successBlock error:^(RCErrorCode status) {
        reject([self getRCErrorCode:status],[self getRCErrorCode:status],nil);
    }];
}

RCT_EXPORT_METHOD(deleteMessages:(NSArray *)messageIds
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    BOOL delete = [[self getClient] deleteMessages:messageIds];
    if (delete) {
        resolve(@(delete));
    } else {
        reject(@"error", @"error", nil);
    }
}

#pragma mark  RongCloud  Send Text / Image / Voice  Messages

RCT_EXPORT_METHOD(sendTextMessage:(int)type
                  targetId:(NSString *)targetId
                  content:(NSString *)content
                  pushContent:(NSString *)pushContent
                  pushData:(NSString *)pushData
                  extra:(NSString *)extra
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    [RCTRongCloudMessage sendTextMessage:type targetId:targetId content:content pushContent:pushContent pushData:pushData extra:extra success:^(NSString *messageId) {
        resolve(messageId);
    } error:^(RCErrorCode status, NSString *messageId) {
        reject(messageId,[self getRCErrorCode:status],nil);
    }];
}

RCT_EXPORT_METHOD(sendImageMessage:(int)type
                  targetId:(NSString *)targetId
                  imageUrl:(NSString *)imageUrl
                  pushContent:(NSString *)pushContent
                  pushData:(NSString *)pushData
                  extra:(NSString *)extra
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    [RCTRongCloudMessage sendImageMessage:type targetId:targetId imageUrl:imageUrl pushContent:pushContent pushData:pushData extra:extra success:^(NSString *messageId) {
        resolve(messageId);
    } error:^(RCErrorCode status, NSString *messageId) {
        reject(messageId,[self getRCErrorCode:status],nil);
    }];
}

/**
 *  录音开始
 */
RCT_EXPORT_METHOD(voiceBtnPressIn:(int)type
                  targetId:(NSString *)targetId
                  pushContent:(NSString *)pushContent
                  pushData:(NSString *)pushData
                  extra:(NSString *)extra
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    RCTRongCloudMessage * RCMessage = [RCTRongCloudMessage shareMessage];
    
    [RCMessage voiceBtnPressIn:type targetId:targetId pushContent:pushContent pushData:pushData extra:extra];
    RCMessage.successBlock = ^(NSString *messageId) {
        resolve(messageId);
    };
    RCMessage.errorBlock = ^(RCErrorCode status, NSString *messageId) {
        reject(messageId,[self getRCErrorCode:status],nil);
    };
}

/**
 *  取消录音
 */
RCT_EXPORT_METHOD(voiceBtnPressCancel:(int)type
                  targetId:(NSString *)targetId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    RCTRongCloudMessage * RCMessage = [RCTRongCloudMessage shareMessage];
    
    [RCMessage voiceBtnPressCancel:type targetId:targetId success:^(NSString *message) {
        resolve(message);
    } error:^(NSString *message) {
        reject(message, message, nil);
    }];
}

/**
 *  录音结束
 */
RCT_EXPORT_METHOD(voiceBtnPressOut:(int)type
                  targetId:(NSString *)targetId
                  pushContent:(NSString *)pushContent
                  pushData:(NSString *)pushData
                  extra:(NSString *)extra
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    RCTRongCloudMessage * RCMessage = [RCTRongCloudMessage shareMessage];
    
    [RCMessage voiceBtnPressOut:type targetId:targetId pushContent:pushContent pushData:pushData extra:extra success:^(NSString *messageId) {
        resolve(messageId);
    } error:^(RCErrorCode status, NSString *messageId) {
        reject(messageId,[self getRCErrorCode:status],nil);
    }];
}

#pragma mark  RongCloud  Play Voice Messages

RCT_EXPORT_METHOD(audioPlayStart:(NSString *)filePath
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject){
    
    RCTRongCloudMessage * RCMessage = [RCTRongCloudMessage shareMessage];
    
    [RCMessage audioPlayStart:filePath success:^(NSString *message) {
        resolve(message);
    } error:^(NSString *Code) {
        reject(@"", @"", nil);
    }];
}


RCT_REMAP_METHOD(audioPlayStop,
                 resolve:(RCTPromiseResolveBlock)resolve
                 rejecte:(RCTPromiseRejectBlock)reject){
    
    RCTRongCloudMessage * RCMessage = [RCTRongCloudMessage shareMessage];
    
    [RCMessage audioPlayStop:^(NSString *message) {
        resolve(message);
    } error:^(NSString *Code) {
        reject(@"", @"", nil);
    }];
}

#pragma mark  RongCloud PushNotification Settting

RCT_EXPORT_METHOD(setConversationNotificationStatus:(int)type
                  targetId:(NSString *)targetId
                  isBlocked:(BOOL)isBlocked
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    RCConversationType conversationType = [self getConversationType:type];
    
    void (^successBlock)(NSUInteger RCConversationNotificationStatus);
    successBlock = ^(NSUInteger RCConversationNotificationStatus) {
        //0: 消息免打扰(DO_NOT_DISTURB)   1: 新消息提醒(NOTIFY)
        resolve(@(RCConversationNotificationStatus));
    };
    
    [[self getClient] setConversationNotificationStatus:conversationType targetId:targetId isBlocked:isBlocked success:successBlock error:^(RCErrorCode status) {
        reject([self getRCErrorCode:status],[self getRCErrorCode:status],nil);
    }];
    
}

RCT_EXPORT_METHOD(getConversationNotificationStatus:(int)type
                  targetId:(NSString *)targetId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    RCConversationType conversationType = [self getConversationType:type];
    
    void (^successBlock)(NSUInteger RCConversationNotificationStatus);
    successBlock = ^(NSUInteger RCConversationNotificationStatus) {
        //0: 消息免打扰(DO_NOT_DISTURB)   1: 新消息提醒(NOTIFY)
        resolve(@(RCConversationNotificationStatus));
    };
    
    [[self getClient] getConversationNotificationStatus:conversationType targetId:targetId success:successBlock error:^(RCErrorCode status) {
        reject([self getRCErrorCode:status],[self getRCErrorCode:status],nil);
    }];
}



RCT_REMAP_METHOD(screenGlobalNotification,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
    
    void (^successBlock)();
    successBlock = ^() {
        resolve(@"success");
    };
    
    [[self getClient] setNotificationQuietHours:@"00:00:00" spanMins:1439 success:successBlock error:^(RCErrorCode status) {
        reject([self getRCErrorCode:status],[self getRCErrorCode:status],nil);
    }];
}

RCT_REMAP_METHOD(removeScreenOfGlobalNotification,
                 removeResolver:(RCTPromiseResolveBlock)resolve
                 removeRejecter:(RCTPromiseRejectBlock)reject) {
    
    void (^successBlock)();
    successBlock = ^() {
        resolve(@"success");
    };
    
    [[self getClient] removeNotificationQuietHours:successBlock error:^(RCErrorCode status) {
        reject([self getRCErrorCode:status],[self getRCErrorCode:status],nil);
    }];
}

RCT_REMAP_METHOD(getGlobalNotificationStatus,
                 statusResolver:(RCTPromiseResolveBlock)resolve
                 statusRejecter:(RCTPromiseRejectBlock)reject) {
    
    void (^successBlock)(NSString *startTime, int spansMin);
    successBlock = ^(NSString *startTime, int spansMin) {
        
        if(spansMin > 0){
            resolve(@(0));
        }else{
            resolve(@(1));
        }
    };
    
    [[self getClient] getNotificationQuietHours:successBlock error:^(RCErrorCode status) {
        reject([self getRCErrorCode:status],[self getRCErrorCode:status],nil);
    }];
}

#pragma mark  Blacklist

RCT_EXPORT_METHOD(addToBlacklist:(NSString *)userId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    void (^successBlock)(void);
    successBlock = ^(void) {
        resolve(@"success");
    };
    
    [[self getClient] addToBlacklist:userId success:successBlock error:^(RCErrorCode status) {
        reject([self getRCErrorCode:status],[self getRCErrorCode:status],nil);
    }];
}

RCT_EXPORT_METHOD(removeFromBlacklist:(NSString *)userId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    void (^successBlock)(void);
    successBlock = ^(void) {
        resolve(@"success");
    };
    
    [[self getClient] removeFromBlacklist:userId success:successBlock error:^(RCErrorCode status) {
        reject([self getRCErrorCode:status],[self getRCErrorCode:status],nil);
    }];
}

RCT_EXPORT_METHOD(getBlacklistStatus:(NSString *)userId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    void (^successBlock)(int bizStatus);
    successBlock = ^(int bizStatus) {
        if (bizStatus == 0) {
            resolve(@(YES));
        } else {
            resolve(@(NO));
        }
    };
    
    [[self getClient] getBlacklistStatus:userId success:successBlock error:^(RCErrorCode status) {
        reject([self getRCErrorCode:status],[self getRCErrorCode:status],nil);
    }];
}

RCT_REMAP_METHOD(getBlacklist,
                 blackResolve:(RCTPromiseResolveBlock)resolve
                 blackReject:(RCTPromiseRejectBlock)reject) {
    
    void (^successBlock)(NSArray *blockUserIds);
    successBlock = ^(NSArray *blockUserIds) {
        resolve(blockUserIds);
    };
    
    [[self getClient] getBlacklist:successBlock error:^(RCErrorCode status) {
        reject([self getRCErrorCode:status],[self getRCErrorCode:status],nil);
    }];
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

RCT_EXPORT_METHOD(logout) {
    [[self getClient] logout];
}


#pragma mark RongCloud OnReceived New Message

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

#pragma mark  RongCloud  SDK methods

-(RCIMClient *) getClient {
    return [RCIMClient sharedRCIMClient];
}

- (RCConversationType)getConversationType:(int)type{
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

-(NSMutableDictionary *)getEmptyBody {
    NSMutableDictionary *body = @{}.mutableCopy;
    return body;
}

- (NSString *)getRCConnectErrorCode:(RCConnectErrorCode)code{
    NSString *errcode;
    switch (code) {
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
    return errcode;
}

- (NSString *)getRCErrorCode:(RCErrorCode)code{
    NSString *errcode;
    switch (code) {
        case ERRORCODE_UNKNOWN:
            errcode = @"ERRORCODE_UNKNOWN";
            break;
        case REJECTED_BY_BLACKLIST:
            errcode = @"REJECTED_BY_BLACKLIST";
            break;
        case ERRORCODE_TIMEOUT:
            errcode = @"ERRORCODE_TIMEOUT";
            break;
        case SEND_MSG_FREQUENCY_OVERRUN:
            errcode = @"SEND_MSG_FREQUENCY_OVERRUN";
            break;
        case NOT_IN_DISCUSSION:
            errcode = @"NOT_IN_DISCUSSION";
            break;
        case NOT_IN_GROUP:
            errcode = @"NOT_IN_GROUP";
            break;
        case FORBIDDEN_IN_GROUP:
            errcode = @"FORBIDDEN_IN_GROUP";
            break;
        case RC_CHANNEL_INVALID:
            errcode = @"RC_CHANNEL_INVALID";
            break;
        case RC_NETWORK_UNAVAILABLE:
            errcode = @"RC_NETWORK_UNAVAILABLE";
            break;
        case RC_MSG_RESPONSE_TIMEOUT:
            errcode = @"RC_MSG_RESPONSE_TIMEOUT";
            break;
        case DATABASE_ERROR:
            errcode = @"DATABASE_ERROR";
            break;
        case RC_MSG_SIZE_OUT_OF_LIMIT:
            errcode = @"RC_MSG_SIZE_OUT_OF_LIMIT";
            break;
        case RC_PUSHSETTING_PARAMETER_INVALID:
            errcode = @"RC_PUSHSETTING_PARAMETER_INVALID";
            break;
        case RC_OPERATION_BLOCKED:
            errcode = @"RC_OPERATION_BLOCKED";
            break;
        case RC_OPERATION_NOT_SUPPORT:
            errcode = @"RC_OPERATION_NOT_SUPPORT";
            break;
        default:
            errcode = @"OTHER";
            break;
    }
    return errcode;
}

@end
