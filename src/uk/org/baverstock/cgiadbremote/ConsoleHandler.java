package uk.org.baverstock.cgiadbremote;

import fi.iki.elonen.NanoHTTPD;

/**
 * Returns the main device console page.
 */

public class ConsoleHandler implements PathHandler {
    public ConsoleHandler() {}

    @Override
    public NanoHTTPD.Response handle(NanoHTTPD.HTTPSession session) {
        String serial = session.getParms().get("device");
        return new NanoHTTPD.Response("<img src='/screen?device=" + serial + "' />");
    }
}
