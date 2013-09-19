package uk.org.baverstock.cgiadbremote;

import fi.iki.elonen.NanoHTTPD;

/**
 * Returns a response associated with some path.
 */
public interface PathHandler {
    NanoHTTPD.Response handle(NanoHTTPD.IHTTPSession session);
}
