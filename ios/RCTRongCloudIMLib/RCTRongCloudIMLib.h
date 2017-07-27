//
//  RCTRongCloudIMLib.h
//  RCTRongCloudIMLib
//
//  Created by lovebing on 3/21/2016.
//  Copyright © 2016 lovebing.org. All rights reserved.
//

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

#import <RongIMLib/RongIMLib.h>
#import <RongIMLib/RCIMClient.h>


@interface RCTRongCloudIMLib: RCTEventEmitter <RCTBridgeModule, RCIMClientReceiveMessageDelegate>

@end
