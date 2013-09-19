package uk.org.baverstock.cgiadbremote;

import com.github.mustachejava.DefaultMustacheFactory;
import com.github.mustachejava.Mustache;
import fi.iki.elonen.NanoHTTPD;

import java.io.Reader;
import java.io.StringReader;
import java.io.StringWriter;
import java.io.Writer;

/**
 * Returns a list of console links to the currently connected devices.
 */

public class DeviceListHandler implements PathHandler {
    private AndroidDebugBridgeWrapper bridge;

    public DeviceListHandler(AndroidDebugBridgeWrapper bridge) {
        this.bridge = bridge;
    }

    @Override
    public NanoHTTPD.Response handle(NanoHTTPD.IHTTPSession session) {
        DefaultMustacheFactory mustacheFactory = new DefaultMustacheFactory();
        Reader reader = new StringReader(
                "<h1>ADB devices</h1>" +
                        "<ul>" +
                        "{{#getDevices}}" +
                        "<li><a href='/console?device={{getSerialNumber}}'>{{getSerialNumber}}</a> {{getName}} {{getAvdName}}" +
                        "{{/getDevices}}" +
                        "</ul>");
        Writer writer = new StringWriter();

        Mustache devicelist = mustacheFactory.compile(reader, "devicelist");
        devicelist.execute(writer, bridge);

        return new NanoHTTPD.Response(writer.toString());
    }
}
