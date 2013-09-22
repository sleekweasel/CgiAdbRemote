package uk.org.baverstock.cgiadbremote.slave;

import com.android.chimpchat.core.IChimpDevice;
import com.android.chimpchat.core.PhysicalButton;
import com.android.chimpchat.core.TouchPressType;
import fi.iki.elonen.NanoHTTPD;
import uk.org.baverstock.cgiadbremote.CgiAdbRemote;
import uk.org.baverstock.cgiadbremote.PathHandler;

/**
 * Hack this - bored.
 */

public class TextHandler implements PathHandler {
    private IChimpDevice iChimpDevice;
    private String serial;

    public TextHandler(IChimpDevice iChimpDevice, String serial) {
        this.iChimpDevice = iChimpDevice;
        this.serial = serial;
    }

    @Override
    public NanoHTTPD.Response handle(NanoHTTPD.IHTTPSession session) {
        NanoHTTPD.Response serialError = ChimpUtils.checkSerial(session, serial);
        if (serialError != null) {
            return serialError;
        }

        String key = session.getParms().get("key");
        int code = Integer.parseInt(key);
        synchronized (iChimpDevice) {
            switch (code) {
                case 3:
                    iChimpDevice.press(PhysicalButton.HOME, TouchPressType.DOWN_AND_UP);
                    break;
                case 82:
                    iChimpDevice.press(PhysicalButton.MENU, TouchPressType.DOWN_AND_UP);
                    break;
                case 4:
                    iChimpDevice.press(PhysicalButton.BACK, TouchPressType.DOWN_AND_UP);
                    break;
                case 26:
                    iChimpDevice.wake();
                    break;
                case -1:
                    iChimpDevice.reboot(null);
                    break;
                default:
                    return new NanoHTTPD.Response(NanoHTTPD.Response.Status.CONFLICT, "text/plain", "Unknown key=" + key);
            }
        }

        return new NanoHTTPD.Response("Pressed key=" + key);
    }
}
