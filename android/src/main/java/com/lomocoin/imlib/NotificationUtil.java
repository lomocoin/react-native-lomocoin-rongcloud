package com.lomocoin.imlib;

import android.app.Notification;
import android.app.PendingIntent;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.drawable.BitmapDrawable;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;
import android.text.TextUtils;

import java.lang.reflect.Method;

import io.rong.push.notification.RongNotificationInterface;

/**
 * Created by qiaojiayan on 17/11/9.
 */

public class NotificationUtil {
    public static Notification createNotification(Context context, String title, PendingIntent pendingIntent, String content) {
        String tickerText = context.getResources().getString(context.getResources().getIdentifier("rc_notification_ticker_text", "string", context.getPackageName()));

        Notification notification;
        if(Build.VERSION.SDK_INT < 11) {
            try {
                notification = new Notification(context.getApplicationInfo().icon, tickerText, System.currentTimeMillis());
                Class smallIcon = Notification.class;
                Method isLollipop = smallIcon.getMethod("setLatestEventInfo", new Class[]{Context.class, CharSequence.class, CharSequence.class, PendingIntent.class});
                isLollipop.invoke(notification, new Object[]{context, title, content, pendingIntent});
                notification.flags = 16;
                notification.defaults = -1;
            } catch (Exception var14) {
                var14.printStackTrace();
                return null;
            }
        } else {
            boolean isLollipop1 = Build.VERSION.SDK_INT >= 21;
            int smallIcon1 = context.getResources().getIdentifier("notification_small_icon", "drawable", context.getPackageName());
            if(smallIcon1 <= 0 || !isLollipop1) {
                smallIcon1 = context.getApplicationInfo().icon;
            }

            byte defaults = 1;
            Uri sound = null;
            BitmapDrawable bitmapDrawable = (BitmapDrawable)context.getApplicationInfo().loadIcon(context.getPackageManager());
            Bitmap appIcon = bitmapDrawable.getBitmap();
            Notification.Builder builder = new Notification.Builder(context);
            builder.setLargeIcon(appIcon);


            builder.setSmallIcon(smallIcon1);
            builder.setTicker(tickerText);
            builder.setContentTitle(title);
            builder.setContentText(content);
            builder.setContentIntent(pendingIntent);
            builder.setAutoCancel(true);
            builder.setSound(sound);
            builder.setDefaults(defaults);
            notification = builder.getNotification();
        }

        return notification;
    }
}
