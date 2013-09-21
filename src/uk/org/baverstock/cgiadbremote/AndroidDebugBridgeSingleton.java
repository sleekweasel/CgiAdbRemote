package uk.org.baverstock.cgiadbremote;

import com.android.chimpchat.ChimpChat;
import com.android.chimpchat.adb.AdbBackend;
import com.android.ddmlib.AndroidDebugBridge;

import java.util.HashMap;
import java.util.Map;

/**
 * Provides an initialised ADB, and AdbBackend.
 */

public class AndroidDebugBridgeSingleton {
    private static AndroidDebugBridge bridge;
    private static ChimpChat chimpChat;

    public static synchronized AndroidDebugBridge getAndroidDebugBridge() {
        init();
        return bridge;
    }

    public static synchronized ChimpChat getChimpChat() {
        init();
        return chimpChat;
    }

    private static void init() {
        if (bridge == null) {
            AndroidDebugBridge.init(false);
            AndroidDebugBridge.addDebugBridgeChangeListener(new AndroidDebugBridge.IDebugBridgeChangeListener() {
                @Override
                public void bridgeChanged(AndroidDebugBridge androidDebugBridge) {
                    System.err.println("Bridge changed");
                    bridge = androidDebugBridge;
                }
            });
            String adbExec = System.getProperty("cgiadbremote.adbexec");
            System.err.println(String.format("With cgiadbremote.adbexec=%s", adbExec));
            boolean forceNewBridge = false;
            Map<String, String> chimpy = new HashMap<String, String>();
            chimpy.put("adbLocation", adbExec);
            chimpy.put("noInitAdb", "true");
            chimpy.put("backend", "adb");
            chimpChat = ChimpChat.getInstance(chimpy);
            bridge = AndroidDebugBridge.createBridge(adbExec, forceNewBridge);
        }
        while (!bridge.isConnected() && !bridge.hasInitialDeviceList()) {
            System.err.println("Waiting for connection/device list...");
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            }
        }
    }
}
