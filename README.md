# react-native-lomocoin-rongcloud
Rongcloud For React Native

# Usage
```
npm i react-native-lomocoin-rongcloud
react-native link react-native-lomocoin-rongcloud
```

## Android config
- config AndroidManifest.xml
- fix settings.gradle
```
// file: android/settings.gradle
// ...
include ':react-native-lomocoin-rongcloud'
project(":react-native-lomocoin-rongcloud").projectDir = file("../node_modules/react-native-lomocoin-rongcloud/android")
```
```
// file: android/app/build.gradle

dependencies {
    // ...
    compile project(':react-native-lomocoin-rongcloud')
}

```

## iOS config
add framework
- libopencore-amrnb.a
- RongIMLib.framework
- libsqlite3.tbd

add framework search paths & library search paths
- $(PROJECT_DIR)/../node_modules/react-native-lomocoin-rongcloud/ios/lib

## Import
```
import RongCloud from 'react-native-lomocoin-rongcloud'
```

## iOS Push Notifications

Please follow RongCloud official website to configuration certificate: http://www.rongcloud.cn/docs/ios_push.html
 
 And add code on -application:didFinishLaunchingWithOptions:  of  AppDelegate.m
 ```
 /**
 * Push Notifications
 */
 if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
 //iOS10
 UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
 center.delegate = self;
 [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
 if (granted) {
 // user access push notifications permission
 [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
 }];
 } else {
 // user reject push notifications permission
 }
 }];
 }
 else if ([application
 respondsToSelector:@selector(registerUserNotificationSettings:)]) {
 //iOS 8 or later
 UIUserNotificationSettings *settings = [UIUserNotificationSettings
 settingsForTypes:(UIUserNotificationTypeBadge |
 UIUserNotificationTypeSound |
 UIUserNotificationTypeAlert)
 categories:nil];
 [application registerUserNotificationSettings:settings];
 }
 
 // register Notifications
 [[UIApplication sharedApplication] registerForRemoteNotifications];
 ```


## Thanks
this project is base on https://github.com/lovebing/react-native-rongcloud-imlib
