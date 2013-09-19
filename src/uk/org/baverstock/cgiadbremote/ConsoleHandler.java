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
        IDevice device = MiscUtils.getDevice(session, bridge);
        Mustache console = mustacheFactory.compile(reader, "device");
        Writer writer = new StringWriter();
        console.execute(writer, device);
        return new NanoHTTPD.Response(writer.toString());
    }
}
