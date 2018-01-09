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

// DeviceEventEmitter.addListener('onRongMessageReceived', (resp) => {
//     typeof (_onRongCloudMessageReceived) === 'function' && _onRongCloudMessageReceived(resp);
// });

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
    getTotalUnreadCount() {
        return RongCloudIMLib.getTotalUnreadCount();
    },
    getTargetUnreadCount(conversationType, targetId) {
    	// 获取某个会话类型的target 的未读消息数
        return RongCloudIMLib.getTargetUnreadCount(conversationType, targetId);
    },
    getConversationsUnreadCount(conversationTypes) {
    	// 获取某些会话类型（conversationTypes为数组）的未读消息数
        return RongCloudIMLib.getConversationsUnreadCount(conversationTypes);
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
    	//设置会话消息提醒 isBlocked（true 屏蔽  false 新消息提醒）  （return  0:（屏蔽） 1:（新消息提醒））
    	return RongCloudIMLib.setConversationNotificationStatus(conversationType, targetId, isBlocked);
    },
    getConversationNotificationStatus(conversationType, targetId) {
    	//获取会话消息提醒状态  （return  0:（屏蔽） 1:（新消息提醒））
    	return RongCloudIMLib.getConversationNotificationStatus(conversationType, targetId);
    },
    screenGlobalNotification() {
    	//屏蔽全局新消息提醒
    	return RongCloudIMLib.screenGlobalNotification();
    },
    removeScreenOfGlobalNotification() {
    	//移除全局新消息屏蔽
    	return RongCloudIMLib.removeScreenOfGlobalNotification();
    },
    getGlobalNotificationStatus() {
    	//获取全局新消息提醒状态 （return  true:(全局消息屏蔽)  false:(全局新消息提醒)）
    	return RongCloudIMLib.getGlobalNotificationStatus();
    },
    //isReceivePush-true 开启后台推送 false-关闭后台推送
    disconnect(isReceivePush) {
        return RongCloudIMLib.disconnect(isReceivePush);
    },
    logout(){
        return RongCloudIMLib.logout();
    },
    getFCMToken() {
        if(Platform.OS === 'android'){
            return RongCloudIMLib.getFCMToken();
        }else{
            return '';
        }
    },

    
};
