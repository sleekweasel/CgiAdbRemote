package uk.org.baverstock.cgiadbremote;

import com.android.chimpchat.core.IChimpDevice;
import com.android.ddmlib.AndroidDebugBridge;
import com.android.ddmlib.IDevice;

import java.util.HashMap;
import java.util.Map;

/**
 * Maintains a serial-device mapping, listening for device connection and disconnection.
 */
class CachingListingDeviceConnectionMap implements DeviceConnectionMap, AndroidDebugBridge.IDeviceChangeListener {
    private Map<String, IChimpDevice> cache = new HashMap<String, IChimpDevice>();
    private ChimpChatWrapper chimpChat;

    public CachingListingDeviceConnectionMap(ChimpChatWrapper chimpChat) {
        this.chimpChat = chimpChat;
    }

    @Override
    public synchronized IChimpDevice getDeviceBySerial(String serial) {
        IChimpDevice iChimpDevice = cache.get(serial);
        if (iChimpDevice == null) {
            iChimpDevice = chimpChat.getChimpChat().waitForConnection(10 * 1000, serial);
            cache.put(serial, iChimpDevice);
        }
        return iChimpDevice;
    }

    @Override
    public void deviceConnected(IDevice device) {
    }

    @Override
    public synchronized void deviceDisconnected(IDevice device) {
        String serialNumber = device.getSerialNumber();
        IChimpDevice disconnected = cache.get(serialNumber);
        if (disconnected != null) {
            disconnected.dispose();
            cache.remove(serialNumber);
            cache.remove(disconnected);
        }
    }

    @Override
    public void deviceChanged(IDevice device, int changeMask) {
    }
}
