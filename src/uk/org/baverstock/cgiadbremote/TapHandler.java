package uk.org.baverstock.cgiadbremote;

import com.android.chimpchat.core.IChimpDevice;
import com.android.chimpchat.core.TouchPressType;
import fi.iki.elonen.NanoHTTPD;

/**
 * Sends taps to the phone, via ChimpChat
 */

public class TapHandler implements PathHandler {

    private DeviceConnectionMap deviceConnectionMap;

    public TapHandler(DeviceConnectionMap deviceConnectionMap) {
        this.deviceConnectionMap = deviceConnectionMap;
    }

    @Override
    public NanoHTTPD.Response handle(NanoHTTPD.IHTTPSession session) {
        Point xy = Point.fromString(session.getParms().get("coords"));
        String serial = session.getParms().get(CgiAdbRemote.PARAM_SERIAL);
        IChimpDevice iChimpDevice = serial == null ? null : deviceConnectionMap.getDeviceBySerial(serial);
        if (xy == null || iChimpDevice == null) {
            return new NanoHTTPD.Response(NanoHTTPD.Response.Status.CONFLICT, null, "");
        }
        iChimpDevice.touch(xy.x, xy.y, TouchPressType.DOWN_AND_UP);
        return new NanoHTTPD.Response(NanoHTTPD.Response.Status.NO_CONTENT, null, "");
    }
}
