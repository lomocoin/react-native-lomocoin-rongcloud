//
//  RCTRongCloudDiscussion.m
//  RongCloud
//
//  Created by SUN on 2018/5/17.
//  Copyright © 2018年 Sun. All rights reserved.
//

#import "RCTRongCloudDiscussion.h"

@implementation RCTRongCloudDiscussion

+ (RCIMClient *) getClient {
    return [RCIMClient sharedRCIMClient];
}

+ (NSDictionary *)getDiscussionDicWith:(RCDiscussion *)discussion{
    
    NSDictionary * discussionDic = @{@"discussionId": discussion.discussionId,
                                     @"discussionName": discussion.discussionName,
                                     @"creatorId": discussion.creatorId,
                                     @"memberIdList": discussion.memberIdList,
                                     @"inviteStatus": @(discussion.inviteStatus)};
    return discussionDic;
}

/*!
 创建讨论组
 */
+ (void)createDiscussion:(NSString *)name
              userIdList:(NSArray *)userIdList
                 success:(void (^)(NSDictionary *discussionDic))successBlock
                   error:(void (^)(RCErrorCode status))errorBlock{
    
    [[self getClient] createDiscussion:name userIdList:userIdList success:^(RCDiscussion *discussion) {
        NSDictionary * discussionDic = [self getDiscussionDicWith:discussion];
        successBlock(discussionDic);
    }  error:errorBlock];
}

/*!
 讨论组加人，将用户加入讨论组
 @discussion 设置的讨论组名称长度不能超过40个字符，否则将会截断为前40个字符。
 */
+ (void)addMemberToDiscussion:(NSString *)discussionId
                   userIdList:(NSArray *)userIdList
                      success:(void (^)(NSDictionary *discussionDic))successBlock
                        error:(void (^)(RCErrorCode status))errorBlock{
    
    [[self getClient] addMemberToDiscussion:discussionId userIdList:userIdList success:^(RCDiscussion *discussion) {
        NSDictionary * discussionDic = [self getDiscussionDicWith:discussion];
        successBlock(discussionDic);
    }  error:errorBlock];
}

/*!
 讨论组踢人，将用户移出讨论组
 
 @discussion 如果当前登陆用户不是此讨论组的创建者并且此讨论组没有开放加人权限，则会返回错误。
 
 @warning 不能使用此接口将自己移除，否则会返回错误。
 如果您需要退出该讨论组，可以使用-quitDiscussion:success:error:方法。
 */
+ (void)removeMemberFromDiscussion:(NSString *)discussionId
                            userId:(NSString *)userId
                           success:(void (^)(NSDictionary *discussionDic))successBlock
                             error:(void (^)(RCErrorCode status))errorBlock{
    
    [[self getClient] removeMemberFromDiscussion:discussionId userId:userId success:^(RCDiscussion *discussion) {
        NSDictionary * discussionDic = [self getDiscussionDicWith:discussion];
        successBlock(discussionDic);
    }  error:errorBlock];
}

/*!
 退出当前讨论组
 */
+ (void)quitDiscussion:(NSString *)discussionId
               success:(void (^)(NSDictionary *discussionDic))successBlock
                 error:(void (^)(RCErrorCode status))errorBlock{
    
    [[self getClient] quitDiscussion:discussionId success:^(RCDiscussion *discussion) {
        NSDictionary * discussionDic = [self getDiscussionDicWith:discussion];
        successBlock(discussionDic);
    }  error:errorBlock];
}

/*!
 获取讨论组的信息
 */
+ (void)getDiscussion:(NSString *)discussionId
              success:(void (^)(NSDictionary *discussionDic))successBlock
                error:(void (^)(RCErrorCode status))errorBlock{
    
    [[self getClient] getDiscussion:discussionId success:^(RCDiscussion *discussion) {
        NSDictionary * discussionDic = [self getDiscussionDicWith:discussion];
        successBlock(discussionDic);
    } error:^(RCErrorCode status) {
        errorBlock(status);
    }];
}

/*!
 设置讨论组名称
 @discussion 设置的讨论组名称长度不能超过40个字符，否则将会截断为前40个字符。
 */
+ (void)setDiscussionName:(NSString *)targetId
                     name:(NSString *)discussionName
                  success:(void (^)(BOOL success))successBlock
                    error:(void (^)(RCErrorCode status))errorBlock{
    
    [[self getClient] setDiscussionName:targetId name:discussionName success:^{
        successBlock(YES);
    } error:^(RCErrorCode status) {
        errorBlock(status);
    }];
}

/*!
 设置讨论组是否开放加人权限
 @discussion 讨论组默认开放加人权限，即所有成员都可以加人。
 如果关闭加人权限之后，只有讨论组的创建者有加人权限。
 */
+ (void)setDiscussionInviteStatus:(NSString *)targetId
                           isOpen:(BOOL)isOpen
                          success:(void (^)(BOOL success))successBlock
                            error:(void (^)(RCErrorCode status))errorBlock{
    
    [[self getClient] setDiscussionInviteStatus:targetId isOpen:isOpen success:^{
        successBlock(YES);
    } error:^(RCErrorCode status) {
        errorBlock(status);
    }];
}

@end
