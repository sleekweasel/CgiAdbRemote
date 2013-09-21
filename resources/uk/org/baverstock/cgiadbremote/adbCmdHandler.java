package uk.org.baverstock.cgiadbremote;

import com.android.chimpchat.core.IChimpDevice;
import fi.iki.elonen.NanoHTTPD;

/**
 * Hack...
 */

public class adbCmdHandler implements PathHandler {
    private DeviceConnectionMap deviceConnectionMap;

    public adbCmdHandler(DeviceConnectionMap deviceConnectionMap) {
        this.deviceConnectionMap = deviceConnectionMap;
    }

    @Override
    public NanoHTTPD.Response handle(NanoHTTPD.IHTTPSession session) {
        IChimpDevice device = deviceConnectionMap.getDeviceBySerial(
                session.getParms().get(CgiAdbRemote.PARAM_SERIAL));
        String result = device.shell(session.getParms().get("cmd"));
        return new NanoHTTPD.Response(String.format("<pre>%s</pre>",result));
    }
}
