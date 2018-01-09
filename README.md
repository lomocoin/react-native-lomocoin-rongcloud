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
Build Phases -> Link Binary With Libraries -> add Other:
- libopencore-amrnb.a
- RongIMLib.framework
- libsqlite3.tbd

add framework search paths & library search paths
"$(SRCROOT)/../node_modules/react-native-lomocoin-rongcloud/ios/lib"

## Import
```
import RongCloud from 'react-native-lomocoin-rongcloud'
```

### iOS Push Notifications

Please follow RongCloud official website to configuration certificate: http://www.rongcloud.cn/docs/ios_push.html

 
 #### [Xcode 工程配置](https://github.com/lomocoin/react-native-lomocoin-rongcloud/blob/master/iOSPush.md)


## Thanks
this project is base on https://github.com/lovebing/react-native-rongcloud-imlib
