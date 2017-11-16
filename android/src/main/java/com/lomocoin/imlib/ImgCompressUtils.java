package com.lomocoin.imlib;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Environment;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.UUID;

/**
 * 图片压缩
 */
public class ImgCompressUtils {
    private static final int IMG_W = 960;
    private static final int IMG_H = 960;

    private static final String SD_PATH = "/sdcard/dskqxt/pic/";
    private static final String IN_PATH = "/dskqxt/pic/";

    /**
     * 图片压缩
     * @param imgPath 图片路径
     * @return
     */
    public static String compress(Context context,String imgPath){
//            Log.e("isme","imgPath:"+imgPath);
        try {
            if(imgPath.startsWith("content")){
                imgPath = BitmapUtils.getRealFilePath(context, Uri.parse(imgPath));
            }else if(imgPath.startsWith("file://")){
                imgPath = imgPath.substring("file://".length(),imgPath.length());
            }else{
//                Log.e("isme","图片uri无效");
                return imgPath;
            }

            final BitmapFactory.Options options = new BitmapFactory.Options();
            options.inJustDecodeBounds = true;
            BitmapFactory.decodeFile(imgPath, options);
            // Raw height and width of image
//            Log.e("isme","图片处理开始");
//            Log.e("isme","outHeight:"+options.outHeight +"--- outWidth:"+options.outWidth);
            if(options.outHeight <= IMG_H && options.outWidth <= IMG_W){
//                Log.e("isme","图片的尺寸已经符合 融云的要求了");
                String uri = BitmapUtils.getImageContentUri(context,new File(imgPath)).toString();
                return uri; //图片的尺寸已经符合 融云的要求了
            }

            Bitmap bitmap = BitmapUtils.getSmallBitmap(imgPath,IMG_W,IMG_H);

//            Log.e("isme","处理之后： w:"+bitmap.getWidth()+"  h:"+bitmap.getHeight());
            String newImgPath = BitmapUtils.onSaveBitmap(bitmap,context);
            bitmap.recycle();//回收bitmap
            return newImgPath;
        }catch (Exception e){
            Log.e("isme","compress error :"+imgPath);
            return imgPath;
        }
    }

    private static String generateFileName() {
        return UUID.randomUUID().toString();
    }

    /**
     * 保存bitmap到本地
     *
     * @param context
     * @param mBitmap
     * @return
     */
    private static String saveBitmap(Context context, Bitmap mBitmap) {
        String savePath;
        File filePic;
        if (Environment.getExternalStorageState().equals(
                Environment.MEDIA_MOUNTED)) {
            savePath = SD_PATH;
        } else {
            savePath = context.getApplicationContext().getFilesDir()
                    .getAbsolutePath()
                    + IN_PATH;
        }
        try {
            filePic = new File(savePath + generateFileName() + ".jpg");
            if (!filePic.exists()) {
                filePic.getParentFile().mkdirs();
                filePic.createNewFile();
            }
            FileOutputStream fos = new FileOutputStream(filePic);
            mBitmap.compress(Bitmap.CompressFormat.JPEG, 100, fos);
            fos.flush();
            fos.close();
        } catch (IOException e) {
            return null;
        }
        return filePic.getAbsolutePath();
    }
}
