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

@property(nonatomic, copy) void (^successBlock)(NSString *messageId);
@property(nonatomic, copy) void (^errorBlock)(RCErrorCode status, NSString *messageId);

+ (instancetype)shareMessage;

#pragma mark Messages Operation

+ (NSMutableArray *)getConversation:(NSArray *)conversationList;

/*!
 获取会话列表
 
 @param conversationTypeList 会话类型的数组(需要将RCConversationType转为NSNumber构建Array)
 */
+ (void)getConversationList:(void (^)(NSArray *array))successBlock error:(void (^)())errorBlock;

/*!
 根据关键字搜索会话
 
 @param keyword              关键字
 */
+ (void)searchConversations:(NSString *)keyword
                    success:(void (^)(NSArray *array))successBlock
                      error:(void (^)())errorBlock;

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
                    error:(void (^)())errorBlock;


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
                     error:(void (^)())errorBlock;


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
                                   error:(void (^)())errorBlock;


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
                                           error:(void (^)())errorBlock;


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
                                   error:(void (^)())errorBlock;


#pragma mark Send Message

// 发送文本消息
+ (void)sendTextMessage:(int)type
               targetId:(NSString *)targetId
                content:(NSString *)content
            pushContent:(NSString *)pushContent
               pushData:(NSString *)pushData
                  extra:(NSString *)extra
                success:(void (^)(NSString *messageId))successBlock
                  error:(void (^)(RCErrorCode status, NSString *messageId))errorBlock;

// 发送图片消息
+ (void)sendImageMessage:(int)type
                targetId:(NSString *)targetId
                imageUrl:(NSString *)imageUrl
             pushContent:(NSString *)pushContent
                pushData:(NSString *)pushData
                   extra:(NSString *)extra
                 success:(void (^)(NSString *messageId))successBlock
                   error:(void (^)(RCErrorCode status, NSString *messageId))errorBlock;


// 发送语音消息
- (void)voiceBtnPressIn:(int)type
               targetId:(NSString *)targetId
            pushContent:(NSString *)pushContent
               pushData:(NSString *)pushData
                  extra:(NSString *)extra;

- (void)voiceBtnPressOut:(int)type
                targetId:(NSString *)targetId
             pushContent:(NSString *)pushContent
                pushData:(NSString *)pushData
                   extra:(NSString *)extra
                 success:(void (^)(NSString *messageId))successBlock
                   error:(void (^)(RCErrorCode status, NSString *messageId))errorBlock;

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

+ (void)recallMessage:(NSDictionary *)message
                 push:(NSString *)push
              success:(void (^)(NSString *messageId))successBlock
                error:(void (^)(RCErrorCode status))errorBlock;

@end
