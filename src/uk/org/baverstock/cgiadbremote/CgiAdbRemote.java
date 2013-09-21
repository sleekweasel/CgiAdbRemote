package uk.org.baverstock.cgiadbremote;

import com.android.ddmlib.AndroidDebugBridge;
import fi.iki.elonen.NanoHTTPD;
import fi.iki.elonen.ServerRunner;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;

/**
 * Provide access to this host's Android devices over HTTP.
 */
public class CgiAdbRemote extends NanoHTTPD {

    public static final String ROOT_PATH = "/";
    public static final String CONSOLE_PATH = "/console";
    public static final String SCREEN_PATH = "/screendump";
    public static final String TOUCH_PATH = "/touch";
    public static final String TEXT_PATH = "/text";
    public static final String ADBKILL_PATH = "/killServer";
    public static final String RESOURCE_PATH = "/resource";
    public static final String ADBCMD_PATH = "/adbCmd";
    public static final String PARAM_SERIAL = "device";

    private final Map<String, PathHandler> pathHandlerMap;

    public CgiAdbRemote(int port, Map<String, PathHandler> PathHandlerMap) {
        super(port);
        pathHandlerMap = PathHandlerMap;
    }

    private String hashAsParms(Map<String, String> parms) {
        StringBuilder sb = new StringBuilder();
        if (parms != null) {
            for (Map.Entry<String, String> entry : parms.entrySet()) {
                sb.append(sb.length() > 0 ? " & " : "? ");
                sb.append(entry.getKey()).append("=").append(entry.getValue());
            }
        }
        return sb.toString();
    }

    @Override
    public Response serve(IHTTPSession session) {
        System.err.println(String.format("%s: %s %s%s", new Date(), session.getMethod(), session.getPath(),
                hashAsParms(session.getParms())));
        PathHandler pathHandler = pathHandlerMap.get(session.getPath());
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

    @Override
    public void stop() {
        super.stop();
        new ChimpChatWrapper.Real().getChimpChat().shutdown();
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
        int port = getInt("port", 8080);
        CgiAdbRemote cgiAdbRemote = new CgiAdbRemote(port, getPathHandlers(
                new CachingListingDeviceConnectionMap(new ChimpChatWrapper.Real())));
        ServerRunner.executeInstance(cgiAdbRemote);
    }

    private static HashMap<String, PathHandler> getPathHandlers(CachingListingDeviceConnectionMap deviceConnectionMap) {
        HashMap<String, PathHandler> pathHandlers = new HashMap<String, PathHandler>();

        AndroidDebugBridgeWrapper.Real bridge = new AndroidDebugBridgeWrapper.Real();
        AndroidDebugBridge.addDeviceChangeListener(deviceConnectionMap);
        pathHandlers.put(ROOT_PATH, new DeviceListHandler(bridge));
        pathHandlers.put(CONSOLE_PATH, new ConsoleHandler(bridge));
        pathHandlers.put(TOUCH_PATH, new TouchHandler(deviceConnectionMap));
        pathHandlers.put(TEXT_PATH, new TextHandler(deviceConnectionMap));
        pathHandlers.put(ADBKILL_PATH, new AdbKillHandler());
        pathHandlers.put(RESOURCE_PATH, new ResourceHandler());
        pathHandlers.put(ADBCMD_PATH, new AdbCmdHandler(deviceConnectionMap));
        pathHandlers.put(SCREEN_PATH, new ScreenHandler(bridge, new ScreenshotToInputStream()));

        return pathHandlers;
    }

}
