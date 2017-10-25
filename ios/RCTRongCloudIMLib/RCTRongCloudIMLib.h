//
//  RCTRongCloudIMLib.h
//  RCTRongCloudIMLib
//
//  Created by lomocoin on 10/21/2017.
//  Copyright © 2017 lomocoin.com. All rights reserved.
//

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

#import <RongIMLib/RongIMLib.h>
#import <RongIMLib/RCIMClient.h>


@interface RCTRongCloudIMLib: RCTEventEmitter <RCTBridgeModule, RCIMClientReceiveMessageDelegate>

@end
