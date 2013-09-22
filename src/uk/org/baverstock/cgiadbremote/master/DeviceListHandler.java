package uk.org.baverstock.cgiadbremote.master;

import com.github.mustachejava.DefaultMustacheFactory;
import com.github.mustachejava.Mustache;
import fi.iki.elonen.NanoHTTPD;
import uk.org.baverstock.cgiadbremote.PathHandler;

import java.io.*;

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
        InputStream resourceAsStream = DeviceListHandler.class.getResourceAsStream("DeviceListHandler.html");
        Reader reader = new InputStreamReader(resourceAsStream);

        Mustache deviceList = mustacheFactory.compile(reader, "devicelist");

        Writer writer = new StringWriter();
        deviceList.execute(writer, bridge);

        return new NanoHTTPD.Response(writer.toString());
    }
}
