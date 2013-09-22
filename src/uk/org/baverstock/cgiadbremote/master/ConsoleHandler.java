package uk.org.baverstock.cgiadbremote.master;

import com.android.ddmlib.IDevice;
import com.github.mustachejava.DefaultMustacheFactory;
import com.github.mustachejava.Mustache;
import fi.iki.elonen.NanoHTTPD;
import uk.org.baverstock.cgiadbremote.CgiAdbRemote;
import uk.org.baverstock.cgiadbremote.MiscUtils;
import uk.org.baverstock.cgiadbremote.PathHandler;

import java.io.*;
import java.util.Map;

import static fi.iki.elonen.NanoHTTPD.Response.Status.INTERNAL_ERROR;

/**
 * Returns the main device console page.
 *
 * Starts a new monkey slave if we don't already have one for this serial number.
 */

public class ConsoleHandler implements PathHandler {
    private AndroidDebugBridgeWrapper bridge;
    private MonkeySlaveProvider slaver;

    public ConsoleHandler(AndroidDebugBridgeWrapper bridge, MonkeySlaveProvider slaver) {
        this.bridge = bridge;
        this.slaver = slaver;
    }

    @Override
    public NanoHTTPD.Response handle(NanoHTTPD.IHTTPSession session) {
        DefaultMustacheFactory mustacheFactory = new DefaultMustacheFactory();
        InputStream resourceAsStream = ConsoleHandler.class.getResourceAsStream("ConsoleHandler.html");
        Reader reader = new InputStreamReader(resourceAsStream);
        Mustache console = mustacheFactory.compile(reader, "device");

        String serial = session.getParms().get(CgiAdbRemote.PARAM_SERIAL);
        int port = slaver.getMonkeyPort(serial);
        if (port == -1) {
            return new NanoHTTPD.Response(INTERNAL_ERROR, "text/plain", "Unable to allocate a free port for this monkey.");
        }
        String host = session.getHeaders().get("host").split(":")[0] + ":" + port;
        for (Map.Entry<String, String> stringStringEntry : session.getHeaders().entrySet()) {
            System.err.println(stringStringEntry.getKey() + "=" + stringStringEntry.getValue());
        }


        Extras extras = new Extras(host);
        IDevice device = MiscUtils.getDeviceForSession(session, bridge);
        Writer writer = new StringWriter();
        console.execute(writer, new Object[] { device, extras });
        return new NanoHTTPD.Response(writer.toString());
    }

    private class Extras {
        String getBanner;
        String touchDelay;
        String refreshNum;
        String idledelay;
        String monkeyHostPort;

        public Extras(String monkeyHostPort) {
            this.monkeyHostPort = monkeyHostPort;
            getBanner = System.getProperty("cgiadbremote.banner", "Tests may be running");
            touchDelay = System.getProperty("cgiadbremote.touchdelay", "2");
            idledelay = System.getProperty("cgiadbremote.idledelay", "4");
            refreshNum = System.getProperty("cgiadbremote.refreshes", "10");
        }
    }
}
