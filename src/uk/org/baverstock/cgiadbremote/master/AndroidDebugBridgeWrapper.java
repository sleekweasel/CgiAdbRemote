package uk.org.baverstock.cgiadbremote.master;

import com.android.ddmlib.AndroidDebugBridge;
import com.android.ddmlib.IDevice;

/**
 * Wraps ADB because Google don't believe in letting people test-drive their code.
 */

public interface AndroidDebugBridgeWrapper {
    AndroidDebugBridge getBridge();
    IDevice[] getDevices();

    class Noop implements AndroidDebugBridgeWrapper {
        @Override
        public AndroidDebugBridge getBridge() {
            return null;
        }

        @Override
        public IDevice[] getDevices() {
            return null;
        }

        public static AndroidDebugBridgeWrapper bridgeWithDevices(final IDevice... devices) {
            return new AndroidDebugBridgeWrapper.Noop() {
                @Override
                public IDevice[] getDevices() {
                    return devices;
                }
            };
        }
    };

    class Real implements AndroidDebugBridgeWrapper {
        @Override
        public AndroidDebugBridge getBridge() {
            return AndroidDebugBridgeSingleton.getAndroidDebugBridge();
        }

        @Override
        public IDevice[] getDevices() {
            return getBridge().getDevices();
        }
    }
}
