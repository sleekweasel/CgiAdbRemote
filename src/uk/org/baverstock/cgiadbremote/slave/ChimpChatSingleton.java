package uk.org.baverstock.cgiadbremote.slave;

import com.android.chimpchat.ChimpChat;
import uk.org.baverstock.cgiadbremote.MiscUtils;

import java.util.HashMap;
import java.util.Map;

/**
* Provides a ChimpChat.
*/
public class ChimpChatSingleton {
    private static ChimpChat chimpChat;

    public static synchronized ChimpChat getChimpChat() {
        if (chimpChat == null) {
            chimpChat = init();
        }
        return chimpChat;
    }

    private static ChimpChat init() {
        Map<String, String> chimpy = new HashMap<String, String>();
        String adb = MiscUtils.getAdbCmd().getAbsolutePath();
        chimpy.put("adbLocation", adb);
        chimpy.put("noInitAdb", "true");
        chimpy.put("backend", "adb");
        return ChimpChat.getInstance(chimpy);
    }
}
