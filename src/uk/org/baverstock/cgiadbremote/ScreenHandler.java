package uk.org.baverstock.cgiadbremote;

import com.android.ddmlib.IDevice;
import fi.iki.elonen.NanoHTTPD;

/**
 * Replies with screen
 */

public class ScreenHandler implements PathHandler {
    private final DeviceToInputStream screenshotToInputStream;
    private final AndroidDebugBridgeWrapper bridge;

    public ScreenHandler(AndroidDebugBridgeWrapper bridge, DeviceToInputStream screenshotToInputStream) {
        this.bridge = bridge;
        this.screenshotToInputStream = screenshotToInputStream;
    }

    @Override
    public NanoHTTPD.Response handle(NanoHTTPD.HTTPSession session) {
        try {
            IDevice device = MiscUtils.getDevice(session, bridge);
            return new NanoHTTPD.Response(
                    NanoHTTPD.Response.Status.OK,
                    "image/png",
                    screenshotToInputStream.convert(device)
            );
        } catch (Exception e) {
            return MiscUtils.getResponseForException(e);
        }
    }
}
