'use strict';
import {
    NativeModules,
    DeviceEventEmitter,
    NativeEventEmitter
}
    from 'react-native';

const RongCloudIMLib = NativeModules.RongCloudIMLibModule;

var _onRongCloudMessageReceived = function (resp) {
    console.log("融云接受消息:" + JSON.stringify(resp));
}

DeviceEventEmitter.addListener('onRongMessageReceived', (resp) => {
    typeof (_onRongCloudMessageReceived) === 'function' && _onRongCloudMessageReceived(resp);
});

const RongCloudIMLibEmitter = new NativeEventEmitter(RongCloudIMLib);

const subscription = RongCloudIMLibEmitter.addListener(
    'onRongMessageReceived',
    (resp) => {
        typeof (_onRongCloudMessageReceived) === 'function' && _onRongCloudMessageReceived(resp);
    }
);


const ConversationType = {
    PRIVATE: 'PRIVATE',
    DISCUSSION: 'DISCUSSION',
    SYSTEM: 'SYSTEM'
};

export default {
    ConversationType: ConversationType,
    onReceived(callback) {
        _onRongCloudMessageReceived = callback;
    },
    initWithAppKey(appKey) {
        return RongCloudIMLib.initWithAppKey(appKey);
    },
    connectWithToken(token) {
        return RongCloudIMLib.connectWithToken(token);
    },
    clearUnreadMessage(conversationType, targetId){
        return RongCloudIMLib.clearUnreadMessage(conversationType, targetId);
    },
    searchConversations(keyword) {
        return RongCloudIMLib.searchConversations(keyword);
    },
    getConversationList() {
        return RongCloudIMLib.getConversationList();
    },
    getLatestMessages(type, targetId, count) {
        return RongCloudIMLib.getLatestMessages(type, targetId, count);
    },
    sendTextMessage(conversationType, targetId, content) {
        return RongCloudIMLib.sendTextMessage(conversationType, targetId, content, content);
    },
    sendImageMessage(conversationType, targetId, imageUrl) {
        return RongCloudIMLib.sendImageMessage(conversationType, targetId, imageUrl, '');
    },
    voiceBtnPressIn(conversationType, targetId) {
        return RongCloudIMLib.voiceBtnPressIn(conversationType, targetId);
    },
    voiceBtnPressOut(conversationType, targetId) {
        return RongCloudIMLib.voiceBtnPressOut(conversationType, targetId);
    },
    disconnect(disconnect) {
        return RongCloudIMLib.disconnect(disconnect);
    },
};
