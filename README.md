# react-native-rongcloud
Rongcloud For React Native

# usage
```
npm install --save https://github.com/lomocoin/react-native-rongcloud
react-native link react-native-rongcloud
```

## android config
- config AndroidManifest.xml
- fix settings.gradle
```
// file: android/settings.gradle
// ...
include ':react-native-rongcloud'
project(":react-native-rongcloud").projectDir = file("../node_modules/react-native-rongcloud/android")
```
```
// file: android/app/build.gradle

dependencies {
    // ...
    compile project(':react-native-rongcloud')
}

```

## ios config
add framework
- libopencore-amrnb.a
- RongIMLib.framework
- libsqlite3.tbd

add framework search paths & library search paths
- $(PROJECT_DIR)/../node_modules/react-native-rongcloud/ios/lib

## import
```
import RongCloud from 'react-native-rongcloud'
```
```

```
