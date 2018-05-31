package com.lomocoin.imlib;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.util.Log;

import io.rong.imlib.ipc.RongService;
import io.rong.push.RongPushClient;
import io.rong.push.notification.PushMessageReceiver;
import io.rong.push.notification.PushNotificationMessage;

/**
 * Created by qiaojiayan on 17/10/31.
 */

public class RongNotificationReceiver extends PushMessageReceiver {
    @Override
    public boolean onNotificationMessageArrived(Context context, PushNotificationMessage pushNotificationMessage) {
        Log.e("isme", "rong msg init");
        return false;
    }

    @Override
    public boolean onNotificationMessageClicked(Context context, PushNotificationMessage msg) {
        Log.e("isme", "rong msg click");

        // fait otc
        if (msg.getPushData() != null && msg.getPushData().length() > 0) {
            String pushData = msg.getPushData();
            if (pushData.contains("FiatOrder") && pushData.contains("orderId")) {
                Intent intent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
                intent.putExtra("action", "fiat_otc_push");
                intent.putExtra("data", pushData);
                context.startActivity(intent);
                return true;
            }
        }

        return false;
    }
}
