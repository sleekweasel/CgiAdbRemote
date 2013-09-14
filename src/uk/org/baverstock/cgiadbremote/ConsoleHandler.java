package uk.org.baverstock.cgiadbremote;

import fi.iki.elonen.NanoHTTPD;

/**
 * Returns the main device console page.
 */

public class ConsoleHandler implements PathHandler {
    @Override
    public NanoHTTPD.Response handle(NanoHTTPD.HTTPSession session) {
        String serial = session.getParms().get(CgiAdbRemote.PARAM_SERIAL);
        return new NanoHTTPD.Response("<img src='" + CgiAdbRemote.SCREEN_PATH + "?" + CgiAdbRemote.PARAM_SERIAL + "=" + serial + "' />");
    }
}
