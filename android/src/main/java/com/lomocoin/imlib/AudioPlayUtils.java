package com.lomocoin.imlib;

import android.media.MediaPlayer;

/**
 * 播放语音消息工具类
 */
public class AudioPlayUtils {
    private static MediaPlayer mediaPlayer;
    private static String path = "";

    private static MediaPlayer getInstance(){
        if(mediaPlayer == null){
            mediaPlayer = new MediaPlayer();
        }
        return mediaPlayer;
    }

    /**
     * filePath  js 传入的样式为  file:///data/data/com.lomocoin.lomocoin/files/100082/voice/128.amr
     * @param filePath
     */
    public static void start(String filePath){
        try {
            if(!filePath.startsWith("file:///")){
                return;
            }
            //截取文件路径
            filePath = filePath.substring("file://".length(),filePath.length());
            MediaPlayer mp = getInstance();
            mp.reset();
            mp.setDataSource(filePath);
            mp.prepare();
            mp.start();
        }catch (Exception e){

        }
    }


    //在 application 中，app 结束的时候调用
    public static void stop(){
        try {
            if (mediaPlayer != null) {
                mediaPlayer.stop();
                //释放资源
                mediaPlayer.release();
            }
        }catch (Exception e){ }
    }
}
