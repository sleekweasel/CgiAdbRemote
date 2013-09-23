package uk.org.baverstock.cgiadbremote;

import com.android.chimpchat.core.IChimpDevice;
import com.android.ddmlib.AndroidDebugBridge;
import com.android.ddmlib.DdmPreferences;
import fi.iki.elonen.NanoHTTPD;
import fi.iki.elonen.ServerRunner;
import uk.org.baverstock.cgiadbremote.master.*;
import uk.org.baverstock.cgiadbremote.master.AdbCmdHandler;
import uk.org.baverstock.cgiadbremote.slave.ChimpChatWrapper;
import uk.org.baverstock.cgiadbremote.slave.TextHandler;
import uk.org.baverstock.cgiadbremote.slave.TouchHandler;

import java.util.Date;

/**
 * Provide access to this host's Android devices over HTTP.
 */
public class CgiAdbRemote extends NanoHTTPD {

    public static final String PARAM_SERIAL = "device";

    private final PathHandlers pathHandlers;

    public CgiAdbRemote(int port, PathHandlers PathHandlerMap) {
        super(port);
        pathHandlers = PathHandlerMap;
    }

    @Override
    public void stop() {
        super.stop();
        pathHandlers.stop();
    }

    @Override
    public Response serve(IHTTPSession session) {
        Response response = getResponse(session);

        System.err.println(String.format("%s: %d %s %03d %s ? %s",
                new Date(), this.getListeningPort(), session.getMethod(), response.getStatus().getRequestStatus(), session.getPath(),
                session.getParms().get(NanoHTTPD.QUERY_STRING_PARAMETER)));

        return response;
    }

    private Response getResponse(IHTTPSession session) {
        PathHandler pathHandler = pathHandlers.get(session.getPath());
        if (pathHandler != null) {
            try {
                return pathHandler.handle(session);
            } catch (Throwable t) {
                t.printStackTrace();
                return MiscUtils.getResponseForThrowable(t);
            }
        }
        return new Response(Response.Status.NOT_FOUND, "text/plain", "Not found: " + session.getPath());
    }

    static public int getInt(String key, int defaultInt) {
        try {
            String value = System.getProperty(key, "" + defaultInt);
            return Integer.parseInt(value);
        } catch (NumberFormatException e) {
            e.printStackTrace();
            return defaultInt;
        }
    }

    public static void main(String[] args) {
        final CgiAdbRemote cgiAdbRemote;
        String slave = System.getProperty("slave");
        if (slave == null) {
            System.out.println("Master...");
            cgiAdbRemote = new CgiAdbRemote(getInt("port", 8080), masterPathHandlers());
        } else {
            System.out.println("Slave...");
            PathHandlers pathHandlers = slavePathHandlers(
                    new ChimpChatWrapper.Real(), slave);
            cgiAdbRemote = new CgiAdbRemote(0, pathHandlers);
            pathHandlers.put("/quit", new PathHandler() {
                @Override
                public Response handle(IHTTPSession session) {
                    cgiAdbRemote.stop();
                    return null;
                }
            });
        }
        ServerRunner.executeInstance(cgiAdbRemote);
    }

    private static PathHandlers masterPathHandlers() {
        PathHandlers pathHandlers = new PathHandlers();
        DdmPreferences.setTimeOut(10 * 1000);

        AndroidDebugBridgeWrapper.Real bridge = new AndroidDebugBridgeWrapper.Real();
        AndroidDebugBridge.addDeviceChangeListener(new NullDeviceChangeListener());

        pathHandlers.put("/resource", new ResourceHandler());
        pathHandlers.put("/killServer", new AdbKillHandler());

        pathHandlers.put("/", new DeviceListHandler(bridge));
        final MonkeySlaveProvider slaver = new MonkeySlaveProvider();
        Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
            @Override
            public void run() {
                slaver.killAllTheMonkeys();
            }
        }));
        pathHandlers.put("/console", new ConsoleHandler(bridge, slaver));
        pathHandlers.put("/adbCmd", new AdbCmdHandler(bridge));
        pathHandlers.put("/screendump", new ScreenHandler(bridge, new ScreenshotToInputStream()));

        return pathHandlers;
    }

    private static PathHandlers slavePathHandlers(final ChimpChatWrapper real, String serial)
    {
        PathHandlers pathHandlers = new PathHandlers() {
            @Override
            public void stop() {
                real.getChimpChat().shutdown();
            }
        };
        IChimpDevice chimp = real.getChimpChat().waitForConnection(10 * 1000, serial);
        pathHandlers.put("/touch", new TouchHandler(chimp, serial));
        pathHandlers.put("/text", new TextHandler(chimp, serial));

        return pathHandlers;
    }

}
