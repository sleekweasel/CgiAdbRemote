package uk.org.baverstock.cgiadbremote;

import com.android.ddmlib.IDevice;

import java.util.HashMap;
import java.util.Map;

import static uk.org.baverstock.cgiadbremote.AndroidDebugBridgeWrapper.Noop.bridgeWithDevices;

public class TestBeans {
    public static final IDevice DEVICE_1 = FakeIDevice.anIDevice().withName("device1").withSerialNumber(
            "serial1").withScreenshot("screenshot1").withAvdName("avd1").build();
    public static final IDevice DEVICE_2 = FakeIDevice.anIDevice().withName("device2").withSerialNumber(
            "serial2").withScreenshot("screenshot2").withAvdName("avd2").build();
    public static final AndroidDebugBridgeWrapper BRIDGE = bridgeWithDevices(DEVICE_1, DEVICE_2);

    public static NullHttpSession sessionWithParams(final String... data) {
        return new NullHttpSession() {
            @Override
            public Map<String, String> getParms() {
                HashMap<String, String> map = new HashMap<String, String>();
                for (int i=0; i < data.length; i+=2) {
                    map.put(data[i], data[i+1]);
                }
                return map;
            }
        };
    }
}
