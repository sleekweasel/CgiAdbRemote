package uk.org.baverstock.cgiadbremote;

import fi.iki.elonen.NanoHTTPD;

import java.io.InputStream;

/**
 * Returns resources
 */

public class ResourceHandler implements PathHandler {
    @Override
    public NanoHTTPD.Response handle(NanoHTTPD.IHTTPSession session) {
        InputStream stream = ResourceHandler.class.getResourceAsStream(session.getParms().get("name"));
        return new NanoHTTPD.Response(NanoHTTPD.Response.Status.OK, null, stream);
    }
}
