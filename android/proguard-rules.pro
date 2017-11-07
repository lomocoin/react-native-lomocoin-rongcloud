# 融云级GCM 推送 混淆
-dontwarn com.xiaomi.mipush.sdk.**
-keep public class com.xiaomi.mipush.sdk.* {*; }
-keep public class com.google.android.gms.gcm.**
-keep public class * extends android.content.BroadcastReceiver
-keep class com.lomocoin.imlib.RongNotificationReceiver {*;}