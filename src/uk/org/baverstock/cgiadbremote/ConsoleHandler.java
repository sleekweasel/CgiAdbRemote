package uk.org.baverstock.cgiadbremote;

import com.android.ddmlib.IDevice;
import com.github.mustachejava.DefaultMustacheFactory;
import com.github.mustachejava.Mustache;
import fi.iki.elonen.NanoHTTPD;

import java.io.*;

/**
 * Returns the main device console page.
 */

public class ConsoleHandler implements PathHandler {
    private AndroidDebugBridgeWrapper bridge;

    public ConsoleHandler(AndroidDebugBridgeWrapper bridge) {
        this.bridge = bridge;
    }

    @Override
    public NanoHTTPD.Response handle(NanoHTTPD.IHTTPSession session) {
        DefaultMustacheFactory mustacheFactory = new DefaultMustacheFactory();
        InputStream resourceAsStream = ConsoleHandler.class.getResourceAsStream("ConsoleHandler.html");
        Reader reader = new InputStreamReader(resourceAsStream);
        Extras extras = new Extras();
        IDevice device = MiscUtils.getDevice(session, bridge);
        Mustache console = mustacheFactory.compile(reader, "device");
        Writer writer = new StringWriter();
        console.execute(writer, new Object[] { device, extras });
        return new NanoHTTPD.Response(writer.toString());
    }

    private class Extras {
        String getBanner;
        String touchDelay;
        String refreshNum;
        String idledelay;
        {
            getBanner = System.getProperty("cgiadbremote.banner", "Tests may be running");
            touchDelay = System.getProperty("cgiadbremote.touchdelay", "2");
            idledelay = System.getProperty("cgiadbremote.idledelay", "4");
            refreshNum = System.getProperty("cgiadbremote.refreshes", "10");
        }
    }
}
