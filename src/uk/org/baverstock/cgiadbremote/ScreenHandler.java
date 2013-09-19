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
    public NanoHTTPD.Response handle(NanoHTTPD.IHTTPSession session) {
        try {
            IDevice device = MiscUtils.getDevice(session, bridge);
            NanoHTTPD.Response response = new NanoHTTPD.Response(
                    NanoHTTPD.Response.Status.OK,
                    "image/png",
                    screenshotToInputStream.convert(device)
            );
            response.setChunkedTransfer(true);
            return response;
        } catch (Exception e) {
            return MiscUtils.getResponseForException(e);
        }
    }
}
