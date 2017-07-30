//
//  RCTRongCloudIMLib.m
//  RCTRongCloudIMLib
//
//  Created by lovebing on 3/21/2016.
//  Copyright © 2016 lovebing.org. All rights reserved.
//

#import "RCTRongCloudIMLib.h"

@implementation RCTRongCloudIMLib


RCT_EXPORT_MODULE(RongCloudIMLibModule)

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"onRongMessageReceived"];
}

RCT_EXPORT_METHOD(initWithAppKey:(NSString *)appkey) {
    NSLog(@"initWithAppKey %@", appkey);
    [[self getClient] initWithAppKey:appkey];
    
    [[self getClient] setReceiveMessageDelegate:self object:nil];
}

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

RCT_REMAP_METHOD(getConversationList,
                 resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject) {
    
    NSArray *conversationList = [[self getClient] getConversationList:@[@(ConversationType_PRIVATE)]];
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
                dict[@"lastestMessage"] = textMsg.content;
            } else if ([conversation.lastestMessage isKindOfClass:[RCImageMessage class]]) {
                dict[@"lastestMessage"] = @"[图片]";
            } else if ([conversation.lastestMessage isKindOfClass:[RCVoiceMessage class]]) {
                dict[@"lastestMessage"] = @"[语音]";
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
                 targetId:(NSString *)targetId
                 count:(int)count
                 resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject) {
    
    NSArray * messageList = [[self getClient] getLatestMessages:ConversationType_PRIVATE targetId:targetId count:count];
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
                dict[@"data"] = voiceMsg.wavAudioData;
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

RCT_REMAP_METHOD(searchConversations,
                 keyword:(NSString *)keyword
                 resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject) {
    
    NSArray *SearchResult = [[self getClient] searchConversations:@[@(ConversationType_PRIVATE)] messageType:@[[RCTextMessage getObjectName]] keyword:keyword];
    
    
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
                dict[@"lastestMessage"] = textMsg.content;
            } else if ([result.conversation.lastestMessage isKindOfClass:[RCImageMessage class]]) {
                dict[@"lastestMessage"] = @"[图片]";
            } else if ([result.conversation.lastestMessage isKindOfClass:[RCVoiceMessage class]]) {
                dict[@"lastestMessage"] = @"[语音]";
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

RCT_EXPORT_METHOD(sendTextMessage:(NSString *)type
                  targetId:(NSString *)targetId
                  content:(NSString *)content
                  pushContent:(NSString *) pushContent
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    RCTextMessage *messageContent = [RCTextMessage messageWithContent:content];
    [self sendMessage:type targetId:targetId content:messageContent pushContent:pushContent resolve:resolve reject:reject];
    
    
}

RCT_EXPORT_METHOD(sendImageMessage:(NSString *)type
                  targetId:(NSString *)targetId
                  content:(NSString *)imageUrl
                  pushContent:(NSString *) pushContent
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    RCImageMessage *imageMessage = [RCImageMessage messageWithImageURI:imageUrl];
    [self sendMessage:type targetId:targetId content:imageMessage pushContent:pushContent resolve:resolve reject:reject];
    
}

RCT_EXPORT_METHOD(sendVoiceMessage:(NSString *)type
                  targetId:(NSString *)targetId
                  content:(NSData *)voiceData
                  duration:(float )duration
                  pushContent:(NSString *) pushContent
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    RCVoiceMessage *rcVoiceMessage = [RCVoiceMessage messageWithAudio:voiceData duration:duration];
    [self sendMessage:type targetId:targetId content:rcVoiceMessage pushContent:pushContent resolve:resolve reject:reject];
    
}

RCT_REMAP_METHOD(getSDKVersion,
                 rejecter:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
    NSString* version = [[self getClient] getSDKVersion];
    resolve(version);
}

RCT_EXPORT_METHOD(disconnect:(BOOL)isReceivePush) {
    [[self getClient] disconnect:isReceivePush];
}



-(RCIMClient *) getClient {
    return [RCIMClient sharedRCIMClient];
}

-(void)sendMessage:(NSString *)type
          targetId:(NSString *)targetId
           content:(RCMessageContent *)content
       pushContent:(NSString *) pushContent
           resolve:(RCTPromiseResolveBlock)resolve
            reject:(RCTPromiseRejectBlock)reject {
    
    RCConversationType conversationType;
    if([type isEqualToString:@"PRIVATE"]) {
        conversationType = ConversationType_PRIVATE;
    }
    else if([type isEqualToString:@"GROUP"]) {
        conversationType = ConversationType_GROUP;
    }
    else {
        conversationType = ConversationType_SYSTEM;
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
    
    [[self getClient] sendMessage:conversationType targetId:targetId content:content pushContent:pushContent pushData:nil success:successBlock error:errorBlock];
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
    _message[@"sentTime"] = [NSString stringWithFormat:@"%lld",message.sentTime];
    
    if ([message.content isMemberOfClass:[RCTextMessage class]]) {
        RCTextMessage *testMessage = (RCTextMessage *)message.content;
        _message[@"content"] = testMessage.content;
    }
    else if([message.content isMemberOfClass:[RCImageMessage class]]) {
        RCImageMessage *imageMessage = (RCImageMessage *)message.content;
        _message[@"imageUrl"] = imageMessage.imageUrl;
        _message[@"thumbnailImage"] = imageMessage.thumbnailImage;
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

