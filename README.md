# react-native-lomocoin-rongcloud
Rongcloud For React Native

# usage
```
npm install --save https://github.com/lomocoin/react-native-lomocoin-rongcloud
react-native link react-native-lomocoin-rongcloud
```

## android config
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

## ios config
add framework
- libopencore-amrnb.a
- RongIMLib.framework
- libsqlite3.tbd

add framework search paths & library search paths
- $(PROJECT_DIR)/../node_modules/react-native-lomocoin-rongcloud/ios/lib

## import
```
import RongCloud from 'react-native-lomocoin-rongcloud'
```
```

## thanks
this project is base on https://github.com/lovebing/react-native-rongcloud-imlib
```
