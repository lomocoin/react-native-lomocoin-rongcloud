//
//  RCTRongCloudDiscussion.h
//  RongCloud
//
//  Created by SUN on 2018/5/17.
//  Copyright © 2018年 Sun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RongIMLib/RongIMLib.h>
#import <RongIMLib/RCIMClient.h>


@interface RCTRongCloudDiscussion : NSObject

/*!
 创建讨论组
 
 @param name            讨论组名称
 @param userIdList      用户ID的列表
 @param successBlock    创建讨论组成功的回调 [discussion:创建成功返回的讨论组对象]
 @param errorBlock      创建讨论组失败的回调 [status:创建失败的错误码]
 */
+ (void)createDiscussion:(NSString *)name
              userIdList:(NSArray *)userIdList
                 success:(void (^)(NSDictionary *discussionDic))successBlock
                   error:(void (^)(RCErrorCode status))errorBlock;

/*!
 讨论组加人，将用户加入讨论组
 
 @param discussionId    讨论组ID
 @param userIdList      需要加入的用户ID列表
 @param successBlock    讨论组加人成功的回调 [discussion:讨论组加人成功返回的讨论组对象]
 @param errorBlock      讨论组加人失败的回调 [status:讨论组加人失败的错误码]
 
 @discussion 设置的讨论组名称长度不能超过40个字符，否则将会截断为前40个字符。
 */
+ (void)addMemberToDiscussion:(NSString *)discussionId
                   userIdList:(NSArray *)userIdList
                      success:(void (^)(NSDictionary *discussionDic))successBlock
                        error:(void (^)(RCErrorCode status))errorBlock;

/*!
 讨论组踢人，将用户移出讨论组
 
 @param discussionId    讨论组ID
 @param userId          需要移出的用户ID
 @param successBlock    讨论组踢人成功的回调 [discussion:讨论组踢人成功返回的讨论组对象]
 @param errorBlock      讨论组踢人失败的回调 [status:讨论组踢人失败的错误码]
 
 @discussion 如果当前登陆用户不是此讨论组的创建者并且此讨论组没有开放加人权限，则会返回错误。
 
 @warning 不能使用此接口将自己移除，否则会返回错误。
 如果您需要退出该讨论组，可以使用-quitDiscussion:success:error:方法。
 */
+ (void)removeMemberFromDiscussion:(NSString *)discussionId
                            userId:(NSString *)userId
                           success:(void (^)(NSDictionary *discussionDic))successBlock
                             error:(void (^)(RCErrorCode status))errorBlock;

/*!
 退出当前讨论组
 
 @param discussionId    讨论组ID
 @param successBlock    退出成功的回调 [discussion:退出成功返回的讨论组对象]
 @param errorBlock      退出失败的回调 [status:退出失败的错误码]
 */
+ (void)quitDiscussion:(NSString *)discussionId
               success:(void (^)(NSDictionary *discussionDic))successBlock
                 error:(void (^)(RCErrorCode status))errorBlock;

/*!
 获取讨论组的信息
 
 @param discussionId    需要获取信息的讨论组ID
 @param successBlock    获取讨论组信息成功的回调 [discussion:获取的讨论组信息]
 @param errorBlock      获取讨论组信息失败的回调 [status:获取讨论组信息失败的错误码]
 */
+ (void)getDiscussion:(NSString *)discussionId
              success:(void (^)(NSDictionary *discussionDic))successBlock
                error:(void (^)(RCErrorCode status))errorBlock;

/*!
 设置讨论组名称
 
 @param targetId                需要设置的讨论组ID
 @param discussionName          需要设置的讨论组名称，discussionName长度<=40
 @param successBlock            设置成功的回调
 @param errorBlock              设置失败的回调 [status:设置失败的错误码]
 
 @discussion 设置的讨论组名称长度不能超过40个字符，否则将会截断为前40个字符。
 */
+ (void)setDiscussionName:(NSString *)targetId
                     name:(NSString *)discussionName
                  success:(void (^)(BOOL success))successBlock
                    error:(void (^)(RCErrorCode status))errorBlock;

/*!
 设置讨论组是否开放加人权限
 
 @param targetId        讨论组ID
 @param isOpen          是否开放加人权限
 @param successBlock    设置成功的回调
 @param errorBlock      设置失败的回调[status:设置失败的错误码]
 
 @discussion 讨论组默认开放加人权限，即所有成员都可以加人。
 如果关闭加人权限之后，只有讨论组的创建者有加人权限。
 */
+ (void)setDiscussionInviteStatus:(NSString *)targetId
                           isOpen:(BOOL)isOpen
                          success:(void (^)(BOOL success))successBlock
                            error:(void (^)(RCErrorCode status))errorBlock;

@end
