package uk.org.baverstock.cgiadbremote;

import com.android.chimpchat.core.IChimpDevice;

/**
 * Thing that returns a device for a serial number
 */

public interface DeviceConnectionMap {
    IChimpDevice getDeviceBySerial(String serial);

    void resetDeviceOfSerial(String serial);
}
