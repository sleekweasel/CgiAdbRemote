package uk.org.baverstock.cgiadbremote;

import com.android.ddmlib.IDevice;
import fi.iki.elonen.NanoHTTPD;
import uk.org.baverstock.cgiadbremote.master.AndroidDebugBridgeWrapper;

import java.io.*;

public class MiscUtils {
    public static IDevice deviceFromSerial(String serial, AndroidDebugBridgeWrapper bridge) {
        for (IDevice iDevice : bridge.getDevices()) {
            if(iDevice.getSerialNumber().equals(serial)) {
                return iDevice;
            }
        }
        throw new RuntimeException("No device connected with serial number '" + serial + "'");
    }

    public static IDevice getDeviceForSession(NanoHTTPD.IHTTPSession session, AndroidDebugBridgeWrapper bridge) {
        String serial = session.getParms().get(CgiAdbRemote.PARAM_SERIAL);
        return deviceFromSerial(serial, bridge);
    }

    public static NanoHTTPD.Response getResponseForThrowable(Throwable t) {
        StringWriter out = new StringWriter();
        t.printStackTrace(new PrintWriter(out));
        return new NanoHTTPD.Response(NanoHTTPD.Response.Status.INTERNAL_ERROR, "text/plain", out.toString());
    }

    public static File getAdbCmd() {
        return getCmd("adb", "cgiadbremote.adbexec");
    }

    public static File getCmd(String name, String key) {
        File adbcmd = new File(key == null ? name : System.getProperty(key, name));
        for (String path : System.getenv("PATH").split(":")) {
            File cmd = new File(new File(path), name);
            System.out.println("Trying " + cmd + " can " + cmd.canExecute() + cmd.canRead());
            if (cmd.canRead() && cmd.canExecute()) {
                adbcmd = cmd;
                break;
            }
        }
        return adbcmd;
    }
}
