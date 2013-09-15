package uk.org.baverstock.cgiadbremote;

import com.android.ddmlib.IDevice;
import fi.iki.elonen.NanoHTTPD;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.PrintStream;

public class MiscUtils {
    public static IDevice deviceFromSerial(String serial, AndroidDebugBridgeWrapper bridge) {
        for (IDevice iDevice : bridge.getDevices()) {
            if(iDevice.getSerialNumber().equals(serial)) {
                return iDevice;
            }
        }
        throw new RuntimeException("No device connected with serial number '" + serial + "'");
    }

    public static IDevice getDevice(NanoHTTPD.HTTPSession session, AndroidDebugBridgeWrapper bridge) {
        String serial = session.getParms().get(CgiAdbRemote.PARAM_SERIAL);
        return deviceFromSerial(serial, bridge);
    }

    public static NanoHTTPD.Response getResponseForException(Exception e) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        e.printStackTrace(new PrintStream(out));
        InputStream stackTrace = new ByteArrayInputStream(out.toByteArray());
        return new NanoHTTPD.Response(NanoHTTPD.Response.Status.INTERNAL_ERROR, "text/plain", stackTrace);
    }
}
