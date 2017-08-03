package org.lovebing.reactnative.rongcloud;

import java.util.List;

import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;

import android.net.Uri;
import android.support.annotation.Nullable;

import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import android.util.Log;

import io.rong.imlib.IRongCallback;
import io.rong.imlib.RongIMClient;
import io.rong.imlib.RongIMClient.ResultCallback;
import io.rong.imlib.model.Conversation;
import io.rong.imlib.model.Conversation.ConversationType;
import io.rong.imlib.model.Message;
import io.rong.imlib.model.MessageContent;
import io.rong.imlib.model.SearchConversationResult;
import io.rong.message.RichContentMessage;
import io.rong.message.TextMessage;
import io.rong.message.VoiceMessage;

/**
 * 融云原生功能模块
 *
 * @author qiaojiayan
 * @date 17/8/2 下午5:34
 */
public class RongCloudIMLibModule extends ReactContextBaseJavaModule {

    protected ReactApplicationContext context;

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
        Log.e("isme", "rong init appkey:" + appKey);
        RongIMClient.init(context, appKey);
    }

    @ReactMethod
    public void connectWithToken(String token, final Promise promise) {
        final RongCloudIMLibModule instance = this;
        RongIMClient.setOnReceiveMessageListener(new RongIMClient.OnReceiveMessageListener() {
            @Override
            public boolean onReceived(Message message, int i) {

                WritableMap map = Arguments.createMap();
                WritableMap msg = instance.formatMessage(message);

                map.putMap("message", msg);
                map.putString("left", "0");
                map.putString("errcode", "0");

                instance.sendEvent("onRongCloudMessageReceived", map);
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
                Log.e("isme", "rong 连接融云成功 userid:" + userid);
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
                        } else if (message instanceof RichContentMessage) {
                            msg.putString("lastestMessage", "图片");
                        } else if (message instanceof VoiceMessage) {
                            msg.putString("lastestMessage", "语音");
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

                        MessageContent message = item.getLatestMessage();
                        if (message instanceof TextMessage) {
                            TextMessage textMessage = (TextMessage) message;
                            msg.putString("lastestMessage", textMessage.getContent());
                        } else if (message instanceof RichContentMessage) {
                            msg.putString("lastestMessage", "图片");
                        } else if (message instanceof VoiceMessage) {
                            msg.putString("lastestMessage", "语音");
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
    public void sendTextMessage(int mType, String targetId, String content, String pushContent,final Promise promise) {
        TextMessage textMessage = TextMessage.obtain(content);
        ConversationType type = formatConversationType(mType);
        String pushData = "";
        RongIMClient.getInstance().sendMessage(type, targetId, textMessage, pushContent, pushData, new IRongCallback.ISendMessageCallback() {
            @Override
            public void onAttached(Message message) {

            }

            @Override
            public void onSuccess(Message message) {
                promise.resolve(message.getMessageId()+"");
            }

            @Override
            public void onError(Message message, RongIMClient.ErrorCode errorCode) {
                promise.reject("发送失败","发送失败");
            }
        });
    }

    @ReactMethod
    public void sendImageMessage(int mType, String targetId, String imageUrl, String pushContent,final Promise promise) {
        RichContentMessage richContentMessage = RichContentMessage.obtain("","",imageUrl);
        ConversationType type = formatConversationType(mType);
        String pushData = "";
        RongIMClient.getInstance().sendMessage(type, targetId, richContentMessage, pushContent, pushData, new IRongCallback.ISendMessageCallback() {
            @Override
            public void onAttached(Message message) {

            }

            @Override
            public void onSuccess(Message message) {
                promise.resolve(message.getMessageId()+"");
            }

            @Override
            public void onError(Message message, RongIMClient.ErrorCode errorCode) {
                promise.reject("发送失败","发送失败");
            }
        });
    }

    @ReactMethod
    public void sendVoiceMessage(int mType, String targetId, String voiceData,int duration, String pushContent,final Promise promise) {
        VoiceMessage voiceMessage = VoiceMessage.obtain(Uri.parse(voiceData),duration);
        ConversationType type = formatConversationType(mType);
        String pushData = "";
        RongIMClient.getInstance().sendMessage(type, targetId, voiceMessage, pushContent, pushData, new IRongCallback.ISendMessageCallback() {
            @Override
            public void onAttached(Message message) {

            }

            @Override
            public void onSuccess(Message message) {
                promise.resolve(message.getMessageId()+"");
            }

            @Override
            public void onError(Message message, RongIMClient.ErrorCode errorCode) {
                promise.reject("发送失败","发送失败");
            }
        });
    }

    @ReactMethod
    public void disconnect(boolean isReceivePush) {
        RongIMClient.getInstance().disconnect(isReceivePush);
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
        } else if (message.getContent() instanceof RichContentMessage) {
            RichContentMessage richContentMessage = (RichContentMessage) message.getContent();
            msg.putString("type", "image");
            msg.putString("imageUrl", richContentMessage.getImgUrl());
            msg.putString("extra", richContentMessage.getExtra());
        } else if (message.getContent() instanceof VoiceMessage) {
            VoiceMessage voiceMessage = (VoiceMessage) message.getContent();
            msg.putString("type", "voice");
            msg.putString("data", voiceMessage.getUri().toString());
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
                promise.resolve(message.getMessageId()+"");
            }

            @Override
            public void onError(Message message, RongIMClient.ErrorCode errorCode) {
                promise.reject("发送失败","发送失败");
            }
        });

        //文件上传的
//        RongIMClient.getInstance().sendMessage(type, targetId, content, pushContent, pushData, new RongIMClient.SendMediaMessageCallback() {
//            @Override
//            public void onAttached(Message message) {
//
//            }
//
//            @Override
//            public void onError(Message message, RongIMClient.ErrorCode errorCode) {
//
//            }
//
//            @Override
//            public void onSuccess(Message message) {
//
//            }
//
//            @Override
//            public void onProgress(Message message, int i) {
//
//            }
//        });

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