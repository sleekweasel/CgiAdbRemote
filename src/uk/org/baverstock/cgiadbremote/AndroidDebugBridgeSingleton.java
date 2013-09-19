package uk.org.baverstock.cgiadbremote;

import com.android.ddmlib.AndroidDebugBridge;

/**
 * Provides an initialised ADB.
 */

public class AndroidDebugBridgeSingleton {
    private static AndroidDebugBridge bridge;
    public static synchronized AndroidDebugBridge getAndroidDebugBridge() {
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
            bridge = adbExec != null
                    ? AndroidDebugBridge.createBridge(adbExec, false)
                    : AndroidDebugBridge.createBridge();
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
