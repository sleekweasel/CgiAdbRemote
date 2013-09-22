package uk.org.baverstock.cgiadbremote.master;

import com.android.chimpchat.adb.CommandOutputCapture;
import com.android.chimpchat.core.IChimpDevice;
import com.android.ddmlib.*;
import fi.iki.elonen.NanoHTTPD;
import uk.org.baverstock.cgiadbremote.CgiAdbRemote;
import uk.org.baverstock.cgiadbremote.DeviceConnectionMap;
import uk.org.baverstock.cgiadbremote.MiscUtils;
import uk.org.baverstock.cgiadbremote.PathHandler;
import uk.org.baverstock.cgiadbremote.master.AndroidDebugBridgeWrapper;

import java.io.IOException;
import java.io.OutputStream;
import java.io.PipedInputStream;
import java.io.PipedOutputStream;

/**
 * Hack...
 */

public class AdbCmdHandler implements PathHandler {
    private AndroidDebugBridgeWrapper bridge;

    public AdbCmdHandler(AndroidDebugBridgeWrapper bridge) {
        this.bridge = bridge;
    }

    @Override
    public NanoHTTPD.Response handle(NanoHTTPD.IHTTPSession session) {
        IDevice device = MiscUtils.getDeviceForSession(session, bridge);
        CommandOutputCapture receiver = new CommandOutputCapture();
            synchronized (device) {
                try {
                    device.executeShellCommand(session.getParms().get("cmd"), receiver);
                } catch (Exception e) {
                    return MiscUtils.getResponseForThrowable(e);
                }
            }
        return new NanoHTTPD.Response(NanoHTTPD.Response.Status.OK, "text/plain", receiver.toString());
    }
}
