package uk.org.baverstock.cgiadbremote;

import com.android.ddmlib.IDevice;
import fi.iki.elonen.NanoHTTPD;

import java.io.*;

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
            IDevice device = getDevice(session);
            return new NanoHTTPD.Response(
                    NanoHTTPD.Response.Status.OK,
                    "image/png",
                    screenshotToInputStream.convert(device)
            );
        } catch (Exception e) {
            return getResponseForExcaption(e);
        }
    }

    private IDevice getDevice(NanoHTTPD.HTTPSession session) {
        String serial = session.getParms().get(CgiAdbRemote.PARAM_SERIAL);
        for (IDevice iDevice : bridge.getDevices()) {
            if(iDevice.getSerialNumber().equals(serial)) {
                return iDevice;
            }
        }
        throw new RuntimeException("No device connected with serial number '" + serial + "'");
    }

    private NanoHTTPD.Response getResponseForExcaption(Exception e) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        e.printStackTrace(new PrintStream(out));
        InputStream stackTrace = new ByteArrayInputStream(out.toByteArray());
        return new NanoHTTPD.Response(NanoHTTPD.Response.Status.INTERNAL_ERROR, "text/plain", stackTrace);
    }
}
