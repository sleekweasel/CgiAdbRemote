package uk.org.baverstock.cgiadbremote;

import com.android.chimpchat.core.IChimpDevice;
import com.android.chimpchat.core.PhysicalButton;
import com.android.chimpchat.core.TouchPressType;
import fi.iki.elonen.NanoHTTPD;

/**
 * Hack this - bored.
 */

public class TextHandler implements PathHandler {
    private DeviceConnectionMap deviceConnectionMap;

    public TextHandler(DeviceConnectionMap deviceConnectionMap) {
        this.deviceConnectionMap = deviceConnectionMap;
    }

    @Override
    public NanoHTTPD.Response handle(NanoHTTPD.IHTTPSession session) {
        IChimpDevice device = deviceConnectionMap.getDeviceBySerial(
                session.getParms().get(CgiAdbRemote.PARAM_SERIAL));
        int key = Integer.parseInt(session.getParms().get("key"));
        switch (key) {
            case 3:
                device.press(PhysicalButton.HOME, TouchPressType.DOWN_AND_UP);
                break;
            case 82:
                device.press(PhysicalButton.MENU, TouchPressType.DOWN_AND_UP);
                break;
            case 4:
                device.press(PhysicalButton.BACK, TouchPressType.DOWN_AND_UP);
                break;
            case 26:
                device.wake();
                break;
        }

        return new NanoHTTPD.Response("");
    }
}
