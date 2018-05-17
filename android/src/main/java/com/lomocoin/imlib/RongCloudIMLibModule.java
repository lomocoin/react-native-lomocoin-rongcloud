package com.lomocoin.imlib;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.ExecutionException;

import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;

import android.*;
import android.Manifest;
import android.app.Activity;
import android.app.ActivityManager;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.support.annotation.Nullable;

import com.facebook.react.bridge.UiThreadUtil;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.google.firebase.iid.FirebaseInstanceId;

import android.text.TextUtils;
import android.util.Log;

import io.rong.imlib.IRongCallback;
import io.rong.imlib.RongCommonDefine;
import io.rong.imlib.RongIMClient;
import io.rong.imlib.RongIMClient.ResultCallback;
import io.rong.imlib.model.Conversation;
import io.rong.imlib.model.Conversation.ConversationType;
import io.rong.imlib.model.Discussion;
import io.rong.imlib.model.Message;
import io.rong.imlib.model.MessageContent;
import io.rong.imlib.model.SearchConversationResult;
import io.rong.message.ImageMessage;
import io.rong.message.RichContentMessage;
import io.rong.message.TextMessage;
import io.rong.message.VoiceMessage;
import io.rong.push.RongPushClient;
import io.rong.push.common.RongException;
import io.rong.push.notification.PushNotificationMessage;
import io.rong.push.notification.RongNotificationInterface;

/**
 * 融云原生功能模块
 *
 * @author qiaojiayan
 * @date 17/8/2 下午5:34
 */
public class RongCloudIMLibModule extends ReactContextBaseJavaModule {

    protected ReactApplicationContext context;
    private AudioRecoderUtils recoderUtils;
    private String AtargId = "";
    private String aPushContent = "";
    private Promise Apromise = null;
    private int Atype = 0;
    private String extra = "";

    public void addAudioListener() {
        if (recoderUtils == null) {
            recoderUtils = new AudioRecoderUtils();
        }
        recoderUtils.setOnAudioStatusUpdateListener(new AudioRecoderUtils.OnAudioStatusUpdateListener() {
            @Override
            public void onUpdate(double db, long time) {

            }

            @Override
            public void onStop(String filePath, long time) {
                sendVoiceMsg(filePath, time);
            }
        });
    }


    /**
     * 发送语音消息
     *
     * @param filePath 文件路径
     * @param time     单位毫秒
     */
    public void sendVoiceMsg(String filePath, long time) {
        try {
            //
            if (time < 1000) {
                Apromise.reject("-500", "-500");
            } else {
                int duration = (int) Math.ceil(time / 1000);
                sendVoiceMessage(Atype, AtargId, filePath, duration, aPushContent, extra, Apromise);
            }
        } catch (Exception e) {
        }
    }


    /**
     * @param reactContext
     */
    public RongCloudIMLibModule(ReactApplicationContext reactContext) {
        super(reactContext);
        context = reactContext;
    }

    @Override
    public String getName() {
        return "RongCloudIMLibModule";
    }


    @ReactMethod
    public void initWithAppKey(String appKey) {
        // Log.e("isme", "rong init appkey:" + appKey);
        try {
            RongPushClient.registerFCM(context);
            String appId = FirebaseInstanceId.getInstance().getToken();
//            FirebaseMessaging.getInstance().subscribeToTopic("testTopic");
            // Log.e("isme", "token:" + appId);
        } catch (RongException e) {
            // e.printStackTrace();
        }
        RongIMClient.init(context, appKey);
    }

    @ReactMethod
    public void logout(final Promise promise) {
        try {
            RongIMClient.getInstance().logout();
            promise.resolve("success");
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }

    @ReactMethod
    public void disconnect(boolean isReceivePush, final Promise promise) {
        try {
            RongIMClient.getInstance().disconnect(isReceivePush);
            promise.resolve("success");
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }

    @ReactMethod
    public void connectWithToken(String token, final Promise promise) {
        final RongCloudIMLibModule instance = this;
        RongIMClient.setOnReceiveMessageListener(new RongIMClient.OnReceiveMessageListener() {
            @Override
            public boolean onReceived(final Message message, int i) {

                WritableMap map = Arguments.createMap();
                WritableMap msg = instance.formatMessage(message);

                map.putMap("message", msg);
                map.putString("left", "0");
                map.putString("errcode", "0");
                instance.sendEvent("onRongMessageReceived", map);

                //考虑是否需要发送推送到通知栏
                UiThreadUtil.runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            Activity activity = getCurrentActivity();
//                            if (isBackground(activity)) {
                            //关闭 按home键后的消息提醒
                            if (false) {
                                Uri.Builder builder = Uri.parse("rong://" + activity.getPackageName()).buildUpon();

                                builder.appendPath("conversation").appendPath("lomostar")
                                        .appendQueryParameter("targetId", message.getTargetId())
                                        .appendQueryParameter("title", "");
                                Uri uri = builder.build();

                                Intent intent = context.getPackageManager().getLaunchIntentForPackage(activity.getPackageName());
                                intent.setData(uri);

                                String title = "LoMoStar";
                                String tickerText = context.getResources().getString(context.getResources().getIdentifier("rc_notification_ticker_text", "string", context.getPackageName()));
                                PendingIntent intent1 = PendingIntent.getActivity(context, 300, intent, PendingIntent.FLAG_UPDATE_CURRENT);
                                Notification notification = NotificationUtil.createNotification(activity, title, intent1, tickerText);
                                NotificationManager nm = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
                                if (notification != null) {
                                    nm.notify(2000, notification);
                                }
                            }
                        } catch (Exception e) {
                            Log.e("isme", "考虑是否需要发送推送到通知栏 error");
                        }
                    }
                });


                return true;
            }
        });

        RongIMClient.connect(token, new RongIMClient.ConnectCallback() {
            /**
             * Token 错误，在线上环境下主要是因为 Token 已经过期，您需要向 App Server 重新请求一个新的 Token
             */
            @Override
            public void onTokenIncorrect() {
                promise.reject("-1", "tokenIncorrect");
            }

            /**
             * 连接融云成功
             * @param userid 当前 token
             */
            @Override
            public void onSuccess(String userid) {
                Log.e("isme", "连接融云成功");
                WritableMap map = Arguments.createMap();
                map.putString("userid", userid);
                promise.resolve(map);
            }

            /**
             * 连接融云失败
             * @param errorCode 错误码，可到官网 查看错误码对应的注释
             */
            @Override
            public void onError(RongIMClient.ErrorCode errorCode) {
                Log.e("isme", "rong 连接融云失败 code:" + errorCode.getValue());
                String code = errorCode.getValue() + "";
                String msg = errorCode.getMessage();
                promise.reject(code, msg);
            }
        });
    }

    private boolean isBackground(Context context) {
        ActivityManager activityManager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
        List<ActivityManager.RunningAppProcessInfo> appProcesses = activityManager.getRunningAppProcesses();
        for (ActivityManager.RunningAppProcessInfo appProcess : appProcesses) {
            if (appProcess.processName.equals(context.getPackageName())) {
                if (appProcess.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_BACKGROUND) {
                    Log.i("isme", "后台");
                    return true;
                } else {
                    Log.i("isme", "前台");
                    return false;
                }
            }
        }
        return false;
    }


    @ReactMethod
    public void getLatestMessages(int mType, String targetId, int count, final Promise promise) {
        ConversationType type = formatConversationType(mType);
        RongIMClient.getInstance().getLatestMessages(type, targetId, count, new ResultCallback<List<Message>>() {
            @Override
            public void onError(RongIMClient.ErrorCode errorCode) {
                promise.reject(errorCode.getValue() + "", errorCode.getMessage());
            }

            @Override
            public void onSuccess(List<Message> messages) {
                WritableArray data = Arguments.createArray();
                if (messages != null && !messages.isEmpty()) {
                    for (int i = 0; i < messages.size(); i++) {
                        Message message = messages.get(i);
                        WritableMap item = formatMessage(message);
                        data.pushMap(item);
                    }
                }
                promise.resolve(data);
            }
        });
    }

    @ReactMethod
    public void getHistoryMessages(int mType, String targetId, int oldestMessageId, int count, final Promise promise) {
        ConversationType type = formatConversationType(mType);
        RongIMClient.getInstance().getHistoryMessages(type, targetId, oldestMessageId, count, new ResultCallback<List<Message>>() {
            @Override
            public void onSuccess(List<Message> messages) {
                WritableArray data = Arguments.createArray();

                if (messages != null && !messages.isEmpty()) {
                    for (int i = 0; i < messages.size(); i++) {
                        Message message = messages.get(i);
                        WritableMap item = formatMessage(message);
                        data.pushMap(item);
                    }
                }
                promise.resolve(data);
            }

            @Override
            public void onError(RongIMClient.ErrorCode errorCode) {
                promise.reject(errorCode.getValue() + "", errorCode.getMessage());
            }
        });
    }

    @ReactMethod
    public void getDesignatedTypeHistoryMessages(int mType, String targetId, String objectName, int oldestMessageId, int count, final Promise promise) {
        ConversationType type = formatConversationType(mType);
        RongIMClient.getInstance().getHistoryMessages(type, targetId, objectName, oldestMessageId, count, new ResultCallback<List<Message>>() {
            @Override
            public void onSuccess(List<Message> messages) {
                WritableArray data = Arguments.createArray();

                if (messages != null && !messages.isEmpty()) {
                    for (int i = 0; i < messages.size(); i++) {
                        Message message = messages.get(i);
                        WritableMap item = formatMessage(message);
                        data.pushMap(item);
                    }
                }
                promise.resolve(data);
            }

            @Override
            public void onError(RongIMClient.ErrorCode errorCode) {
                promise.reject(errorCode.getValue() + "", errorCode.getMessage());
            }
        });
    }

    @ReactMethod
    public void getDesignatedDirectionypeHistoryMessages(int mType, String targetId, String objectName, int baseMessageId, int count, int direction, final Promise promise) {
        ConversationType type = formatConversationType(mType);

        RongIMClient.getInstance().getHistoryMessages(type, targetId, objectName, baseMessageId, count, getMessageDirection(direction), new ResultCallback<List<Message>>() {
            @Override
            public void onSuccess(List<Message> messages) {
                WritableArray data = Arguments.createArray();

                if (messages != null && !messages.isEmpty()) {
                    for (int i = 0; i < messages.size(); i++) {
                        Message message = messages.get(i);
                        WritableMap item = formatMessage(message);
                        data.pushMap(item);
                    }
                }
                promise.resolve(data);
            }

            @Override
            public void onError(RongIMClient.ErrorCode errorCode) {
                promise.reject(errorCode.getValue() + "", errorCode.getMessage());
            }
        });
    }

    @ReactMethod
    public void getBaseOnSentTimeHistoryMessages(int mType, String targetId, long sentTime, int before, int after, final Promise promise) {
        ConversationType type = formatConversationType(mType);

        RongIMClient.getInstance().getHistoryMessages(type, targetId, sentTime, before, after, new ResultCallback<List<Message>>() {
            @Override
            public void onSuccess(List<Message> messages) {
                WritableArray data = Arguments.createArray();

                if (messages != null && !messages.isEmpty()) {
                    for (int i = 0; i < messages.size(); i++) {
                        Message message = messages.get(i);
                        WritableMap item = formatMessage(message);
                        data.pushMap(item);
                    }
                }
                promise.resolve(data);
            }

            @Override
            public void onError(RongIMClient.ErrorCode errorCode) {
                promise.reject(errorCode.getValue() + "", errorCode.getMessage());
            }
        });
    }


    @ReactMethod
    public void searchConversations(String keyWord, final Promise promise) {
        ConversationType[] type = {formatConversationType(1), formatConversationType(3)};
        String[] objName = {"RC:TxtMsg"};
        RongIMClient.getInstance().searchConversations(keyWord, type, objName, new ResultCallback<List<SearchConversationResult>>() {
            @Override
            public void onError(RongIMClient.ErrorCode errorCode) {
                promise.reject(errorCode.getValue() + "", errorCode.getMessage());
            }

            @Override
            public void onSuccess(List<SearchConversationResult> messages) {
                WritableArray data = Arguments.createArray();
                if (messages != null && !messages.isEmpty()) {
                    for (int i = 0; i < messages.size(); i++) {
                        WritableMap msg = Arguments.createMap();

                        SearchConversationResult item = messages.get(i);
                        Conversation conversation = item.getConversation();
                        msg.putInt("conversationType", conversation.getConversationType().getValue());
                        msg.putString("targetId", conversation.getTargetId());
                        msg.putString("conversationTitle", conversation.getConversationTitle());
                        msg.putInt("unreadMessageCount", conversation.getUnreadMessageCount());
                        msg.putString("receivedTime", conversation.getReceivedTime() + "");
                        msg.putString("sentTime", conversation.getSentTime() + "");
                        msg.putString("senderUserId", conversation.getSenderUserId());
                        msg.putInt("lastestMessageId", conversation.getLatestMessageId());
                        msg.putInt("lastestMessageId", conversation.getLatestMessageId());
                        msg.putString("lastestMessageDirection", "");
                        // msg.putString("jsonDict", conversation.getLatestMessage().getJsonMentionInfo().toString());
                        // msg.putString("lastestMessage", conversation.getLatestMessage().getMentionedInfo().getMentionedContent());
                        MessageContent message = conversation.getLatestMessage();
                        if (message instanceof TextMessage) {
                            TextMessage textMessage = (TextMessage) message;
                            msg.putString("lastestMessage", textMessage.getContent());
                            msg.putString("msgType", "text");
                        } else if (message instanceof RichContentMessage || message instanceof ImageMessage) {
                            msg.putString("msgType", "image");
                        } else if (message instanceof VoiceMessage) {
                            msg.putString("msgType", "voice");
                        }
                        data.pushMap(msg);
                    }
                }
                promise.resolve(data);
            }
        });
    }

    @ReactMethod
    public void getConversationList(final Promise promise) {
        ConversationType[] type = {formatConversationType(1), formatConversationType(3)};
        RongIMClient.getInstance().getConversationList(new ResultCallback<List<Conversation>>() {
            @Override
            public void onSuccess(List<Conversation> conversations) {
                WritableArray data = Arguments.createArray();
                if (conversations != null && !conversations.isEmpty()) {
                    for (int i = 0; i < conversations.size(); i++) {
                        Conversation item = conversations.get(i);
                        WritableMap msg = Arguments.createMap();
                        msg.putInt("conversationType", item.getConversationType().getValue());
                        msg.putString("targetId", item.getTargetId());
                        msg.putString("conversationTitle", item.getConversationTitle());
                        msg.putInt("unreadMessageCount", item.getUnreadMessageCount());
                        msg.putString("receivedTime", item.getReceivedTime() + "");
                        msg.putString("sentTime", item.getSentTime() + "");
                        msg.putString("senderUserId", item.getSenderUserId());
                        msg.putInt("lastestMessageId", item.getLatestMessageId());
                        msg.putInt("lastestMessageId", item.getLatestMessageId());
                        msg.putString("lastestMessageDirection", "");
                        // msg.putString("jsonDict", item.getLatestMessage().getJsonMentionInfo().toString());
//                        type 是个字符串 'text'  'image'  'voice'
                        MessageContent message = item.getLatestMessage();
                        if (message instanceof TextMessage) {
                            TextMessage textMessage = (TextMessage) message;
                            msg.putString("lastestMessage", textMessage.getContent());
                            msg.putString("msgType", "text");
                        } else if (message instanceof RichContentMessage || message instanceof ImageMessage) {
                            msg.putString("msgType", "image");
                        } else if (message instanceof VoiceMessage) {
                            msg.putString("msgType", "voice");
                        }

                        data.pushMap(msg);
                    }
                }
                promise.resolve(data);
            }

            @Override
            public void onError(RongIMClient.ErrorCode errorCode) {
                promise.reject(errorCode.getValue() + "", errorCode.getMessage());
            }
        }, type);
    }

    @ReactMethod
    public void sendTextMessage(int mType, String targetId, String content, String pushContent, String extra, final Promise promise) {
        TextMessage textMessage = TextMessage.obtain(content);
        textMessage.setExtra(extra);
        ConversationType type = formatConversationType(mType);
        String pushData = "";
        RongIMClient.getInstance().sendMessage(type, targetId, textMessage, pushContent, pushData, new IRongCallback.ISendMessageCallback() {
            @Override
            public void onAttached(Message message) {

            }

            @Override
            public void onSuccess(Message message) {
                promise.resolve(message.getMessageId() + "");
            }

            @Override
            public void onError(Message message, RongIMClient.ErrorCode errorCode) {
                promise.reject("发送失败", "发送失败");
            }
        });
    }

    @ReactMethod
    public void sendImageMessage(int mType, String targetId, String imageUrl, String pushContent, String extra, final Promise promise) {

        imageUrl = ImgCompressUtils.compress(context, imageUrl);//压缩图片处理
//        Log.e("isme","inthis: "+imageUrl);
        if (imageUrl.startsWith("content")) {
            imageUrl = "file://" + BitmapUtils.getRealFilePath(context, Uri.parse(imageUrl));
        } else {
            imageUrl = "file://" + imageUrl;
        }
//        Log.e("isme","path:  "+imageUrl);
        ConversationType type = formatConversationType(mType);

        Uri uri = Uri.parse(imageUrl);
        ImageMessage imageMessage = ImageMessage.obtain(uri, uri, true);
        imageMessage.setExtra(extra);
        RongIMClient.getInstance().sendImageMessage(type, targetId, imageMessage, null, null, new RongIMClient.SendImageMessageCallback() {
            @Override
            public void onAttached(Message message) {

            }

            @Override
            public void onError(Message message, RongIMClient.ErrorCode errorCode) {
                promise.reject("error", "error");
            }

            @Override
            public void onSuccess(Message message) {
//                Log.e("isme","发送成功");
                promise.resolve(message.getMessageId() + "");
            }

            @Override
            public void onProgress(Message message, int i) {

            }
        });
    }

    @ReactMethod
    public void sendVoiceMessage(int mType, String targetId, String voiceData, int duration, String pushContent, String extra, final Promise promise) {
        VoiceMessage voiceMessage = VoiceMessage.obtain(Uri.parse(voiceData), duration);
        voiceMessage.setExtra(extra);
        ConversationType type = formatConversationType(mType);
        String pushData = "";
        RongIMClient.getInstance().sendMessage(type, targetId, voiceMessage, pushContent, pushData, new IRongCallback.ISendMessageCallback() {
            @Override
            public void onAttached(Message message) {

            }

            @Override
            public void onSuccess(Message message) {
                promise.resolve(message.getMessageId() + "");
            }

            @Override
            public void onError(Message message, RongIMClient.ErrorCode errorCode) {
                promise.reject("发送失败", "发送失败");
            }
        });
    }


    //开始播放
    @ReactMethod
    public void audioPlayStart(String filePath, Promise promise) {
        try {
            AudioPlayUtils.start(filePath);
            promise.resolve("success");
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }

    //停止播放
    @ReactMethod
    public void audioPlayStop(Promise promise) {
        try {
            AudioPlayUtils.stop();
            promise.resolve("success");
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }

    @ReactMethod
    public void clearUnreadMessage(int mType, String targetId, Promise promise) {
        try {
            ConversationType type = formatConversationType(mType);
            boolean is = RongIMClient.getInstance().clearMessagesUnreadStatus(type, targetId);
            promise.resolve(is);
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }

    //停止播放
    @ReactMethod
    public void getFCMToken(Promise promise) {
        try {
            String appId = FirebaseInstanceId.getInstance().getToken();
            if (!TextUtils.isEmpty(appId)) {
                promise.resolve(appId);
            } else {
                promise.reject("error", "error");
            }
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }


    /**
     * @param message
     * @return
     */
    protected WritableMap formatMessage(Message message) {
        WritableMap msg = Arguments.createMap();
        msg.putInt("conversationType", message.getConversationType().getValue());
        msg.putString("targetId", message.getTargetId());
        msg.putString("messageId", message.getMessageId() + "");
        msg.putString("receivedTime", message.getReceivedTime() + "");
        msg.putString("sentTime", message.getSentTime() + "");
        msg.putString("senderUserId", message.getSenderUserId());
        msg.putString("messageUId", message.getUId());
        msg.putInt("messageDirection", message.getMessageDirection().getValue());

        if (message.getContent() instanceof TextMessage) {
            TextMessage textMessage = (TextMessage) message.getContent();
            msg.putString("type", "text");
            msg.putString("content", textMessage.getContent());
            msg.putString("extra", textMessage.getExtra());
        } else if (message.getContent() instanceof ImageMessage) {
            ImageMessage richContentMessage = (ImageMessage) message.getContent();
            msg.putString("type", "image");
            if (richContentMessage != null && richContentMessage.getRemoteUri() != null) {
                msg.putString("imageUrl", richContentMessage.getRemoteUri().toString());
            } else {
                msg.putString("imageUrl", "");
            }
            msg.putString("extra", richContentMessage.getExtra());
        } else if (message.getContent() instanceof VoiceMessage) {
            VoiceMessage voiceMessage = (VoiceMessage) message.getContent();
            msg.putString("type", "voice");
            if (voiceMessage != null && voiceMessage.getUri() != null) {
                msg.putString("wavAudioData", voiceMessage.getUri().toString());
            } else {
                msg.putString("wavAudioData", "");
            }
            msg.putString("duration", voiceMessage.getDuration() + "");
            msg.putString("extra", voiceMessage.getExtra());
        }

        return msg;
    }

    protected Conversation.ConversationType ConversationType(String type) {
        Conversation.ConversationType conversationType;
        if (type == "PRIVATE") {
            conversationType = Conversation.ConversationType.PRIVATE;
        } else if (type == "DISCUSSION") {
            conversationType = Conversation.ConversationType.DISCUSSION;
        } else {
            conversationType = Conversation.ConversationType.SYSTEM;
        }
        return conversationType;
    }

    protected void sendMessage(ConversationType type, String targetId, MessageContent content, String pushContent, final Promise promise) {
        String pushData = "";
        RongIMClient.getInstance().sendMessage(type, targetId, content, pushContent, pushData, new IRongCallback.ISendMessageCallback() {
            @Override
            public void onAttached(Message message) {

            }

            @Override
            public void onSuccess(Message message) {
                promise.resolve(message.getMessageId() + "");
            }

            @Override
            public void onError(Message message, RongIMClient.ErrorCode errorCode) {
                promise.reject("发送失败", "发送失败");
            }
        });
    }

    @ReactMethod
    public void voiceBtnPressIn(int mType, String targetId, String pushContent, String extra, final Promise promise) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                int state = context.checkSelfPermission(Manifest.permission.RECORD_AUDIO);
                if (state != PackageManager.PERMISSION_GRANTED) {
                    promise.reject("permission_error", "error");
                }
            }

            if (mType >= 0) {
                this.Atype = mType;
            }
            if (targetId != null && targetId.length() > 0) {
                this.AtargId = targetId;
            }
            if (pushContent != null && pushContent.length() > 0) {
                this.aPushContent = pushContent;
            }
            if (extra != null && extra.length() > 0) {
                this.extra = extra;
            }

            addAudioListener();
            recoderUtils.startRecord();
            promise.resolve("success");
        } catch (Exception e) {
            promise.reject("permission_error", "error");
        }
    }

    @ReactMethod
    public void voiceBtnPressOut(int mType, String targetId, String pushContent, String extra, final Promise promise) {
        try {
            if (mType >= 0) {
                this.Atype = mType;
            }
            if (targetId != null && targetId.length() > 0) {
                this.AtargId = targetId;
            }
            if (pushContent != null && pushContent.length() > 0) {
                this.aPushContent = pushContent;
            }
            if (extra != null && extra.length() > 0) {
                this.extra = extra;
            }
            if (promise != null) {
                this.Apromise = promise;
            }

            if (recoderUtils == null) {
                return;
            }
            recoderUtils.stopRecord();
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }

    @ReactMethod
    public void voiceBtnPressCancel(int mType, String targetId, final Promise promise) {
        try {
            if (recoderUtils == null) {
                return;
            }
            recoderUtils.cancelRecord();
            promise.resolve("success");
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }


    //设置会话消息提醒 isBlocked（true 屏蔽  false 新消息提醒）  （return  0:（屏蔽） 1:（新消息提醒））
    @ReactMethod
    public void setConversationNotificationStatus(int mType, String targetId, boolean isBlocked, final Promise promise) {
        try {
            ConversationType type = formatConversationType(mType);
            Conversation.ConversationNotificationStatus status = isBlocked ?
                    Conversation.ConversationNotificationStatus.DO_NOT_DISTURB ://勿扰 屏蔽
                    Conversation.ConversationNotificationStatus.NOTIFY;//消息通知
            RongIMClient.getInstance().setConversationNotificationStatus(type, targetId, status, new ResultCallback<Conversation.ConversationNotificationStatus>() {
                @Override
                public void onSuccess(Conversation.ConversationNotificationStatus state) {
                    int isNotify = state == Conversation.ConversationNotificationStatus.NOTIFY ? 1 : 0;
                    promise.resolve(isNotify);//1:（新消息提醒） 0:（屏蔽）
                }

                @Override
                public void onError(RongIMClient.ErrorCode errorCode) {
                    promise.reject("error", "error");
                }
            });
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }

    //获取会话消息提醒状态  （return 1:（新消息提醒） 0:（屏蔽） ）
    @ReactMethod
    public void getConversationNotificationStatus(int mType, String targetId, final Promise promise) {
        try {
            ConversationType type = formatConversationType(mType);

            RongIMClient.getInstance().getConversationNotificationStatus(type, targetId, new ResultCallback<Conversation.ConversationNotificationStatus>() {
                @Override
                public void onSuccess(Conversation.ConversationNotificationStatus state) {
                    int isNotify = state == Conversation.ConversationNotificationStatus.NOTIFY ? 1 : 0;
                    promise.resolve(isNotify);//1:（新消息提醒） 0:（屏蔽）
                }

                @Override
                public void onError(RongIMClient.ErrorCode errorCode) {
                    promise.reject("error", "error");
                }
            });
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }


    ////屏蔽全局新消息提醒
    @ReactMethod
    public void screenGlobalNotification(final Promise promise) {
        try {

            RongIMClient.getInstance().setNotificationQuietHours("00:00:00", 1339, new RongIMClient.OperationCallback() {
                @Override
                public void onSuccess() {
                    promise.resolve("success");
                }

                @Override
                public void onError(RongIMClient.ErrorCode errorCode) {
                    promise.reject("error", "error");
                }
            });
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }

    //移除全局新消息屏蔽
    @ReactMethod
    public void removeScreenOfGlobalNotification(final Promise promise) {
        try {
            RongIMClient.getInstance().removeNotificationQuietHours(new RongIMClient.OperationCallback() {
                @Override
                public void onSuccess() {
                    promise.resolve("success");
                }

                @Override
                public void onError(RongIMClient.ErrorCode errorCode) {
                    promise.reject("error", "error");
                }
            });
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }

    ////获取全局新消息提醒状态 （return  0:(全局消息屏蔽)  1:(全局新消息提醒)）
    @ReactMethod
    public void getGlobalNotificationStatus(final Promise promise) {
        try {
            RongIMClient.getInstance().getNotificationQuietHours(new RongIMClient.GetNotificationQuietHoursCallback() {
                @Override
                public void onSuccess(String s, int i) {
                    if (i > 0) {
                        promise.resolve(0);
                    } else {
                        promise.resolve(1);
                    }
                }

                @Override
                public void onError(RongIMClient.ErrorCode errorCode) {
                    promise.reject("error", "error");
                }
            });
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }

    @ReactMethod
    public void getTotalUnreadCount(final Promise promise) {
        try {
            RongIMClient.getInstance().getTotalUnreadCount(new ResultCallback<Integer>() {
                @Override
                public void onSuccess(Integer integer) {
                    promise.resolve(integer);
                }

                @Override
                public void onError(RongIMClient.ErrorCode errorCode) {
                    promise.reject("error", "error");
                }
            });
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }

    // 获取某个会话类型的target 的未读消息数
    @ReactMethod
    public void getTargetUnreadCount(int mType, String targetId, final Promise promise) {
        try {
            ConversationType type = formatConversationType(mType);
            RongIMClient.getInstance().getUnreadCount(type, targetId, new ResultCallback<Integer>() {
                @Override
                public void onSuccess(Integer integer) {
                    promise.resolve(integer);
                }

                @Override
                public void onError(RongIMClient.ErrorCode errorCode) {
                    promise.reject("error", "error");
                }
            });
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }

    // 获取某些会话类型（conversationTypes为数组）的未读消息数
    @ReactMethod
    public void getConversationsUnreadCount(int[] conversationTypes, final Promise promise) {
        try {
            List<ConversationType> lists = new ArrayList<>();
            for (int t : conversationTypes) {
                ConversationType type = formatConversationType(t);
                lists.add(type);
            }
            ConversationType[] types = (ConversationType[]) lists.toArray(new ConversationType[lists.size()]);

            RongIMClient.getInstance().getUnreadCount(types, new ResultCallback<Integer>() {
                @Override
                public void onSuccess(Integer integer) {
                    promise.resolve(integer);
                }

                @Override
                public void onError(RongIMClient.ErrorCode errorCode) {
                    promise.reject("error", "error");
                }
            });
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }


    // 删除消息
    @ReactMethod
    public void deleteTargetMessages(int mType, String targetId, final Promise promise) {
        try {
            ConversationType type = formatConversationType(mType);
            RongIMClient.getInstance().deleteMessages(type, targetId, new ResultCallback<Boolean>() {
                @Override
                public void onSuccess(Boolean aBoolean) {
                    promise.resolve(aBoolean);
                }

                @Override
                public void onError(RongIMClient.ErrorCode errorCode) {
                    promise.reject(String.valueOf(errorCode.getValue()), errorCode.getMessage());
                }
            });
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }


    // Discussion start

    /**
     * 创建讨论组
     *
     * @param name       讨论组名称，如：当前所有成员的名字的组合。
     * @param userIdList 讨论组成员 Id 列表。
     * @param promise    创建讨论组成功后的回调。
     */
    @ReactMethod
    public void createDiscussion(String name, String[] userIdList, final Promise promise) {
        try {
            String newName = name.length() > 40 ? name.substring(0, 40) : name;
            List<String> userList = Arrays.asList(userIdList);
            RongIMClient.getInstance().createDiscussion(newName, userList, new RongIMClient.CreateDiscussionCallback() {
                @Override
                public void onSuccess(String s) {
                    promise.resolve(s);
                }

                @Override
                public void onError(RongIMClient.ErrorCode errorCode) {
                    promise.reject(String.valueOf(errorCode.getValue()), errorCode.getMessage());
                }
            });
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }

    /**
     * 添加一名或者一组用户加入讨论组
     *
     * @param discussionId 讨论组 Id。
     * @param userIdList   邀请的用户 Id 列表。
     * @param promise      执行操作的回调。
     */
    @ReactMethod
    public void addMemberToDiscussion(String discussionId, String[] userIdList, final Promise promise) {
        try {
            List<String> userList = Arrays.asList(userIdList);
            RongIMClient.getInstance().addMemberToDiscussion(discussionId, userList, new RongIMClient.OperationCallback() {
                @Override
                public void onSuccess() {
                    promise.resolve("success");
                }

                @Override
                public void onError(RongIMClient.ErrorCode errorCode) {
                    promise.reject(String.valueOf(errorCode.getValue()), errorCode.getMessage());
                }
            });
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }

    /**
     * 供创建者将某用户移出讨论组。
     * 如果当前登陆用户不是此讨论组的创建者并且此讨论组没有开放加人权限，则会返回错误 {@link RongIMClient.ErrorCode}。
     * 不能使用此接口将自己移除，否则会返回错误 {@link RongIMClient.ErrorCode}。
     * 如果您需要退出该讨论组，可以使用 {@link #quitDiscussion(String, Promise)} 方法
     *
     * @param discussionId 讨论组 Id。
     * @param userId       用户 Id。
     * @param promise      执行操作的回调
     */
    @ReactMethod
    public void removeMemberFromDiscussion(String discussionId, String userId, final Promise promise) {
        try {
            RongIMClient.getInstance().removeMemberFromDiscussion(discussionId, userId, new RongIMClient.OperationCallback() {
                @Override
                public void onSuccess() {
                    promise.resolve("success");
                }

                @Override
                public void onError(RongIMClient.ErrorCode errorCode) {
                    promise.reject(String.valueOf(errorCode.getValue()), errorCode.getMessage());
                }
            });
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }


    /**
     * 退出当前用户所在的某讨论组
     *
     * @param discussionId 讨论组 Id
     * @param promise      执行操作的回调
     */
    @ReactMethod
    public void quitDiscussion(String discussionId, final Promise promise) {
        try {
            RongIMClient.getInstance().quitDiscussion(discussionId, new RongIMClient.OperationCallback() {
                @Override
                public void onSuccess() {
                    promise.resolve("success");
                }

                @Override
                public void onError(RongIMClient.ErrorCode errorCode) {
                    promise.reject(String.valueOf(errorCode.getValue()), errorCode.getMessage());
                }
            });
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }


    /**
     * 获取讨论组信息和设置。
     *
     * @param discussionId 讨论组 Id。
     * @param promise      获取讨论组的回调。
     */
    @ReactMethod
    public void getDiscussion(String discussionId, final Promise promise) {
        try {
            RongIMClient.getInstance().getDiscussion(discussionId, new ResultCallback<Discussion>() {
                @Override
                public void onSuccess(Discussion discussion) {
                    try {
                        WritableMap dis = Arguments.createMap();
                        WritableArray memberIdList = Arguments.createArray();
                        List<String> userList = discussion.getMemberIdList();
                        for (String userId : userList) {
                            memberIdList.pushString(userId);
                        }
                        dis.putString("id", discussion.getId());
                        dis.putString("name", discussion.getName());
                        dis.putString("creatorId", discussion.getCreatorId());
                        dis.putBoolean("isOpen", discussion.isOpen());
                        dis.putArray("memberIdList", memberIdList);
                        promise.resolve(dis);
                    } catch (Exception e) {
                        promise.reject("error", "error");
                    }
                }

                @Override
                public void onError(RongIMClient.ErrorCode errorCode) {
                    promise.reject(String.valueOf(errorCode.getValue()), errorCode.getMessage());
                }
            });
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }

    /**
     * 设置讨论组名称。
     *
     * @param discussionId 讨论组 Id。
     * @param name         讨论组名称。
     * @param promise      设置讨论组的回调。
     */
    @ReactMethod
    public void setDiscussionName(String discussionId, String name, final Promise promise) {
        try {
            RongIMClient.getInstance().setDiscussionName(discussionId, name, new RongIMClient.OperationCallback() {
                @Override
                public void onSuccess() {
                    promise.resolve("success");
                }

                @Override
                public void onError(RongIMClient.ErrorCode errorCode) {
                    promise.reject(String.valueOf(errorCode.getValue()), errorCode.getMessage());
                }
            });
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }

    /**
     * 设置讨论组成员邀请权限。
     * 讨论组默认开放加人权限，即所有成员都可以加人。
     * 如果关闭加人权限之后，只有讨论组的创建者有加人权限。
     *
     * @param discussionId 讨论组 Id。
     * @param isOpen       邀请状态，默认为开放。
     * @param promise      设置权限的回调。
     */
    @ReactMethod
    public void setDiscussionInviteStatus(String discussionId, int isOpen, final Promise promise) {
        try {
            RongIMClient.DiscussionInviteStatus status = RongIMClient.DiscussionInviteStatus.setValue(isOpen);
            RongIMClient.getInstance().setDiscussionInviteStatus(discussionId, status, new RongIMClient.OperationCallback() {
                @Override
                public void onSuccess() {
                    promise.resolve("success");
                }

                @Override
                public void onError(RongIMClient.ErrorCode errorCode) {
                    promise.reject(String.valueOf(errorCode.getValue()), errorCode.getMessage());
                }
            });
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }

    // Discussion end


    protected void sendEvent(String eventName, @Nullable WritableMap params) {
        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
    }


    private ConversationType formatConversationType(int type) {
        switch (type) {
            case 1:
                return ConversationType.PRIVATE;
            case 3:
                return ConversationType.GROUP;
            default:
                return ConversationType.GROUP;
        }
    }

    private RongCommonDefine.GetMessageDirection getMessageDirection(int direction) {
        if (direction == RongCommonDefine.GetMessageDirection.BEHIND.ordinal()) {
            return RongCommonDefine.GetMessageDirection.BEHIND;
        }

        return RongCommonDefine.GetMessageDirection.FRONT;
    }
}
