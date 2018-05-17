//
//  RCTRongCloudMessage.h
//  RongCloud
//
//  Created by SUN on 2018/5/17.
//  Copyright © 2018年 Sun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>
#import <RongIMLib/RCIMClient.h>

@interface RCTRongCloudMessage : NSObject

@property(nonatomic, copy) void (^successBlock)(NSString *message);
@property(nonatomic, copy) void (^errorBlock)(RCErrorCode status, NSString *message);

+ (instancetype)shareMessage;

// 发送文本消息
+ (void)sendTextMessage:(int)type
               targetId:(NSString *)targetId
                content:(NSString *)content
            pushContent:(NSString *)pushContent
                  extra:(NSString *)extra
                success:(void (^)(NSString *messageId))successBlock
                  error:(void (^)(RCErrorCode status, NSString *messageId))errorBlock;

// 发送图片消息
+ (void)sendImageMessage:(int)type
                targetId:(NSString *)targetId
                 imageUrl:(NSString *)imageUrl
             pushContent:(NSString *)pushContent
                   extra:(NSString *)extra
                 success:(void (^)(NSString *messageId))successBlock
                   error:(void (^)(RCErrorCode status, NSString *messageId))errorBlock;


// 发送语音消息
- (void)voiceBtnPressIn:(int)type
               targetId:(NSString *)targetId
            pushContent:(NSString *)pushContent
                  extra:(NSString *)extra;

- (void)voiceBtnPressOut:(int)type
                targetId:(NSString *)targetId
             pushContent:(NSString *)pushContent
                   extra:(NSString *)extra
                 success:(void (^)(NSString *message))successBlock
                   error:(void (^)(RCErrorCode status, NSString *message))errorBlock;

- (void)voiceBtnPressCancel:(int)type
                   targetId:(NSString *)targetId
                    success:(void (^)(NSString *message))successBlock
                      error:(void (^)(NSString *Code))errorBlock;

// 播放语音消息
- (void)audioPlayStart:(NSString *)filePath
               success:(void (^)(NSString *message))successBlock
                 error:(void (^)(NSString *Code))errorBlock;

- (void)audioPlayStop:(void (^)(NSString *message))successBlock
                error:(void (^)(NSString *Code))errorBlock;

@end
