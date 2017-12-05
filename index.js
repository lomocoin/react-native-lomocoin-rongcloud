'use strict';
import {
    NativeModules,
    DeviceEventEmitter,
    NativeEventEmitter,
    Platform
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
    sendTextMessage(conversationType, targetId, content, pushContent) {
        return RongCloudIMLib.sendTextMessage(conversationType, targetId, content, pushContent);
    },
    sendImageMessage(conversationType, targetId, imageUrl, pushContent) {
        return RongCloudIMLib.sendImageMessage(conversationType, targetId, imageUrl, pushContent);
    },
    voiceBtnPressIn(conversationType, targetId, pushContent) {
        return RongCloudIMLib.voiceBtnPressIn(conversationType, targetId, pushContent);
    },
    voiceBtnPressOut(conversationType, targetId, pushContent) {
        return RongCloudIMLib.voiceBtnPressOut(conversationType, targetId, pushContent);
    },
    voiceBtnPressCancel(conversationType, targetId) {
        return RongCloudIMLib.voiceBtnPressCancel(conversationType, targetId);
    },
    audioPlayStart(filePath) {
        return RongCloudIMLib.audioPlayStart(filePath);
    },
    audioPlayStop() {
        return RongCloudIMLib.audioPlayStop();
    },
    setConversationNotificationStatus(conversationType, targetId, isBlocked) {
    	return RongCloudIMLib.setConversationNotificationStatus(conversationType, targetId, isBlocked);
    },
    getConversationNotificationStatus(conversationType, targetId) {
    	return RongCloudIMLib.getConversationNotificationStatus(conversationType, targetId);
    },
    screenGlobalNotification() {
    	return RongCloudIMLib.screenGlobalNotification();
    },
    removeGlobalNotification() {
    	return RongCloudIMLib.removeGlobalNotification();
    },
    getGlobalNotificationStatus() {
    	return RongCloudIMLib.getGlobalNotificationStatus();
    },
    disconnect(disconnect) {
        return RongCloudIMLib.disconnect(disconnect);
    },
    getFCMToken() {
        if(Platform.OS === 'android'){
            return RongCloudIMLib.getFCMToken();
        }else{
            return '';
        }
    },

    
};
