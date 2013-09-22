package uk.org.baverstock.cgiadbremote;

import com.android.ddmlib.AndroidDebugBridge;
import com.android.ddmlib.IDevice;

/**
* Does... nothing. Exciting, huh?
*/
class NullDeviceChangeListener implements AndroidDebugBridge.IDeviceChangeListener {
    @Override
    public void deviceConnected(IDevice device) {
    }

    @Override
    public void deviceDisconnected(IDevice device) {
    }

    @Override
    public void deviceChanged(IDevice device, int changeMask) {
    }
}
