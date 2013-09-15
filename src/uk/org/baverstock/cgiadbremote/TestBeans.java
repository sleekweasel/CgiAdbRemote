package uk.org.baverstock.cgiadbremote;

import com.android.ddmlib.IDevice;

import static uk.org.baverstock.cgiadbremote.AndroidDebugBridgeWrapper.Noop.bridgeWithDevices;

public class TestBeans {
    public static final IDevice DEVICE_1 = FakeIDevice.anIDevice().withName("device1").withSerialNumber(
            "serial1").withAvdName(
            "avd1").build();
    public static final IDevice DEVICE_2 = FakeIDevice.anIDevice().withName("device2").withSerialNumber(
            "serial2").withAvdName(
            "avd2").build();
    public static final AndroidDebugBridgeWrapper BRIDGE = bridgeWithDevices(DEVICE_1, DEVICE_2);
}
