安卓返回数据 都没有long，时间返回都为String类型

1.getLatestMessages
    （1）VoiceMessage  android返回的是视屏的uri
            ios: dict[@"data"] = voiceMsg.wavAudioData;
            android: msg.putString("data", voiceMessage.getUri().toString());
    （2）ios 有 messageUId 属性
            ios     dict[@"messageUId"] = message.messageUId;
            andorid 没有，返回为空字符串

2.searchConversations
    (1) andorid 没有提供 lastestMessageDirection 属性
            android msg.putString("lastestMessageDirection","");
            ios     dict[@"lastestMessageDirection"] = @(result.conversation.lastestMessageDirection);

    (2) andorid lastestMessage 只返回 文字消息类型