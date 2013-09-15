package uk.org.baverstock.cgiadbremote;

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

    public Response serve(HTTPSession session) {
        System.err.println(String.format("%s: %s %s%s", new Date(), session.getMethod(), session.getPath(),
                hashAsParms(session.getParms())));
        PathHandler pathHandler = pathHandlerMap.get(session.getPath());
        if (pathHandler != null) {
            return pathHandler.handle(session);
        }
        return new Response(Response.Status.NOT_FOUND, "text/plain", "Not found: " + session.getPath());
    }

    public static void main(String[] args) {
        CgiAdbRemote cgiAdbRemote = new CgiAdbRemote(8080, getPathHandlers());
        ServerRunner.executeInstance(cgiAdbRemote);
    }

    private static HashMap<String, PathHandler> getPathHandlers() {
        HashMap<String, PathHandler> pathHandlers = new HashMap<String, PathHandler>();

        AndroidDebugBridgeWrapper.Real bridge = new AndroidDebugBridgeWrapper.Real();
        pathHandlers.put(ROOT_PATH, new DeviceListHandler(bridge));
        pathHandlers.put(CONSOLE_PATH, new ConsoleHandler(bridge));
        pathHandlers.put(SCREEN_PATH, new ScreenHandler(bridge, new ScreenshotToInputStream()));

        return pathHandlers;
    }
}
