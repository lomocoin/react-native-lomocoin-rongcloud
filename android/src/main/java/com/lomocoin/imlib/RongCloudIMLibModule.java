package com.lomocoin.imlib;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;

import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;

import android.app.Activity;
import android.app.ActivityManager;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
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
import io.rong.imlib.RongIMClient;
import io.rong.imlib.RongIMClient.ResultCallback;
import io.rong.imlib.model.Conversation;
import io.rong.imlib.model.Conversation.ConversationType;
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
                sendVoiceMessage(Atype, AtargId, filePath, duration, aPushContent, Apromise);
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
        }catch (Exception e){
            promise.reject("error","error");
        }
    }

    @ReactMethod
    public void disconnect(final Promise promise) {
        try {
            RongIMClient.getInstance().disconnect();
            promise.resolve("success");
        }catch (Exception e){
            promise.reject("error","error");
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
                            if (isBackground(activity)) {
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
    public void searchConversations(String keyWord, final Promise promise) {
        ConversationType[] type = {formatConversationType(1)};//只搜索私有消息
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
                        } else if (message instanceof RichContentMessage) {
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
                        } else if (message instanceof RichContentMessage) {
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
    public void sendTextMessage(int mType, String targetId, String content, String pushContent, final Promise promise) {
        TextMessage textMessage = TextMessage.obtain(content);
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
    public void sendImageMessage(int mType, String targetId, String imageUrl, String pushContent, final Promise promise) {

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
    public void sendVoiceMessage(int mType, String targetId, String voiceData, int duration, String pushContent, final Promise promise) {
        VoiceMessage voiceMessage = VoiceMessage.obtain(Uri.parse(voiceData), duration);
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

    @ReactMethod
    public void disconnect(boolean isReceivePush) {
        RongIMClient.getInstance().disconnect(isReceivePush);
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
        ConversationType type = formatConversationType(mType);
        boolean is = RongIMClient.getInstance().clearMessagesUnreadStatus(type, targetId);
        promise.resolve(is);
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
        msg.putString("messageUId", "");
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
    public void voiceBtnPressIn(int mType, String targetId, String pushContent, final Promise promise) {
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

            addAudioListener();
            recoderUtils.startRecord();
            promise.resolve("success");
        } catch (Exception e) {
            promise.reject("error", "error");
        }
    }

    @ReactMethod
    public void voiceBtnPressOut(int mType, String targetId, String pushContent, final Promise promise) {
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
                public void onSuccess(Conversation.ConversationNotificationStatus conversationNotificationStatus) {
                    String state = conversationNotificationStatus ==
                            Conversation.ConversationNotificationStatus.DO_NOT_DISTURB ?
                            "0" : "1";
                    promise.resolve(state);
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

    //获取会话消息提醒状态  （return  0:（屏蔽） 1:（新消息提醒））
    @ReactMethod
    public void getConversationNotificationStatus(int mType, String targetId, final Promise promise) {
        try {
            ConversationType type = formatConversationType(mType);

            RongIMClient.getInstance().getConversationNotificationStatus(type, targetId, new ResultCallback<Conversation.ConversationNotificationStatus>() {
                @Override
                public void onSuccess(Conversation.ConversationNotificationStatus conversationNotificationStatus) {
                    String state = conversationNotificationStatus ==
                            Conversation.ConversationNotificationStatus.DO_NOT_DISTURB ?
                            "0" : "1";
                    promise.resolve(state);
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

    //移除全局新消息提醒
    @ReactMethod
    public void removeGlobalNotification(final Promise promise) {
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

    ////获取全局新消息提醒状态 （return  true:(全局消息屏蔽)  false:(全局新消息提醒)）
    @ReactMethod
    public void getGlobalNotificationStatus(final Promise promise) {
        try {
            RongIMClient.getInstance().getNotificationQuietHours(new RongIMClient.GetNotificationQuietHoursCallback() {
                @Override
                public void onSuccess(String s, int i) {
                    if(i > 0){
                        promise.resolve(true);
                    }else{
                        promise.resolve(false);
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
    public void getTargetUnreadCount(int mType, String targetId,final Promise promise) {
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
    public void getConversationsUnreadCount(int[] conversationTypes,final Promise promise) {
        try {
            List<ConversationType> lists = new ArrayList<>();
            for(int t : conversationTypes){
                ConversationType type = formatConversationType(t);
                lists.add(type);
            }
            ConversationType[] types = (ConversationType[])lists.toArray(new ConversationType[lists.size()]);

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
}