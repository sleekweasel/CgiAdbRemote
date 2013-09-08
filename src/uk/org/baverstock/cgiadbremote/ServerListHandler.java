package uk.org.baverstock.cgiadbremote;

import com.android.ddmlib.IDevice;
import fi.iki.elonen.NanoHTTPD;

/**
 * Returns a list of console links to the currently connected devices.
 */

public class ServerListHandler implements PathHandler {
    private AndroidDebugBridgeWrapper bridge;

    public ServerListHandler(AndroidDebugBridgeWrapper bridge) {
        this.bridge = bridge;
    }

    @Override
    public NanoHTTPD.Response handle(NanoHTTPD.HTTPSession session) {
        IDevice[] devices = bridge.getDevices();
        StringBuilder result = new StringBuilder();
        for (IDevice device : devices) {
            result.append(String.format("<br><a href='" + CgiAdbRemote.CONSOLE_PATH + "?device=%s'>%s</a>", device.getSerialNumber(),
                    device.getName()));
        }
        return new NanoHTTPD.Response(result.toString());
    }
}
