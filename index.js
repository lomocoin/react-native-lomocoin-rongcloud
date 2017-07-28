'use strict';
import { NativeEventEmitter,
    NativeModules }
from 'react-native';

const RongCloudIMLib = NativeModules.RongCloudIMLibModule;

var _onRongCloudMessageReceived = function(resp) {

}

// NativeEventEmitter.addListener('onRongMessageReceived', (resp) => {
//     typeof(_onRongCloudMessageReceived) === 'function' && _onRongCloudMessageReceived(resp);
// });

const ConversationType = {
    PRIVATE: 'PRIVATE',
    DISCUSSION: 'DISCUSSION',
    SYSTEM: 'SYSTEM'
};

export default {
    ConversationType: ConversationType,
    onReceived (callback) {
//         _onRongCloudMessageReceived = callback;
    },
    initWithAppKey (appKey) {
        return RongCloudIMLib.initWithAppKey(appKey);
    },
    connectWithToken (token) {
        return RongCloudIMLib.connectWithToken(token);
    },
    getConversationList(){
        return RongCloudIMLib.getConversationList();
    },
    getConversation(targetId){
        return RongCloudIMLib.getConversation(targetId);
    },
    sendTextMessage (conversationType, targetId, content) {
        return RongCloudIMLib.sendTextMessage(conversationType, targetId, content, content);
    },
    sendImageMessage (conversationType, targetId, imageUrl) {
        return RongCloudIMLib.sendImageMessage(conversationType, targetId, imageUrl, '');
    },
    sendVoiceMessage (conversationType, targetId, voiceData, duration) {
        return RongCloudIMLib.sendVoiceMessage(conversationType, targetId, voiceData, duration, '');
    },
    disconnect (disconnect) {
        return RongCloudIMLib.disconnect(disconnect);
    },
};
