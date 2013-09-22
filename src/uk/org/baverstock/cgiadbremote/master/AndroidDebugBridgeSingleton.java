package uk.org.baverstock.cgiadbremote.master;

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

    public static synchronized AndroidDebugBridge getAndroidDebugBridge() {
        return singleton();
    }

    private static AndroidDebugBridge singleton() {
        if (bridge == null) {
            AndroidDebugBridge.disconnectBridge();
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
        return bridge;
    }
}
