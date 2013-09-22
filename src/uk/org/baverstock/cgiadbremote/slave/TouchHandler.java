package uk.org.baverstock.cgiadbremote.slave;

import com.android.chimpchat.core.IChimpDevice;
import fi.iki.elonen.NanoHTTPD;
import uk.org.baverstock.cgiadbremote.*;

import static fi.iki.elonen.NanoHTTPD.Response.Status.CONFLICT;
import static fi.iki.elonen.NanoHTTPD.Response.Status.NO_CONTENT;
import static java.lang.String.format;

/**
 * Sends taps to the phone, via ChimpChat
 */

public class TouchHandler implements PathHandler {
    private IChimpDevice iChimpDevice;
    private String serial;

    public TouchHandler(IChimpDevice iChimpDevice, String serial) {
        this.iChimpDevice = iChimpDevice;
        this.serial = serial;
    }

    @Override
    public NanoHTTPD.Response handle(NanoHTTPD.IHTTPSession session) {
        NanoHTTPD.Response serialError = ChimpUtils.checkSerial(session, serial);
        if (serialError != null) {
            return serialError;
        }

        Touch touch = Touch.fromParams(session);
        if (touch == null) {
            return new NanoHTTPD.Response(CONFLICT, null, "Coordinate parameters missing.");
        }

        try {
            synchronized (iChimpDevice) {
                iChimpDevice.touch(touch.x, touch.y, touch.touchPressType);
            }
            return new NanoHTTPD.Response(NO_CONTENT, null, "");
        } catch (Exception e) {
            e.printStackTrace();
            return MiscUtils.getResponseForThrowable(e);
        }
    }
}
