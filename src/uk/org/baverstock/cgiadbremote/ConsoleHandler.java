package uk.org.baverstock.cgiadbremote;

import com.android.ddmlib.IDevice;
import com.github.mustachejava.DefaultMustacheFactory;
import com.github.mustachejava.Mustache;
import fi.iki.elonen.NanoHTTPD;

import java.io.Reader;
import java.io.StringReader;
import java.io.StringWriter;
import java.io.Writer;

/**
 * Returns the main device console page.
 */

public class ConsoleHandler implements PathHandler {
    private AndroidDebugBridgeWrapper bridge;

    public ConsoleHandler(AndroidDebugBridgeWrapper bridge) {
        this.bridge = bridge;
    }

    @Override
    public NanoHTTPD.Response handle(NanoHTTPD.HTTPSession session) {
        DefaultMustacheFactory mustacheFactory = new DefaultMustacheFactory();
        Reader reader = new StringReader(
                "<h1>Device {{getName}}</h1>" +
                        "<a href='/'>Devices</a><br>" +
                        "<a href='/console?device={{getSerialNumber}}&coords='>" +
                        "<img src='/screendump?device={{getSerialNumber}}' ismap />" +
                        "</a>" +
                        "");
        IDevice device = MiscUtils.getDevice(session, bridge);
        Writer writer = new StringWriter();

        Mustache deviceList = mustacheFactory.compile(reader, "device");
        deviceList.execute(writer, device);
        return new NanoHTTPD.Response(writer.toString());
    }
}
