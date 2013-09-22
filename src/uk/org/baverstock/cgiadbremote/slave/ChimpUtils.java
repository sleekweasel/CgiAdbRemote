package uk.org.baverstock.cgiadbremote.slave;

import fi.iki.elonen.NanoHTTPD;
import uk.org.baverstock.cgiadbremote.CgiAdbRemote;

import static fi.iki.elonen.NanoHTTPD.Response.Status.CONFLICT;
import static java.lang.String.format;

/**
 * Misc thingies
 */

public class ChimpUtils {
    static public NanoHTTPD.Response checkSerial(NanoHTTPD.IHTTPSession session, String serial) {
        String requestSerial = session.getParms().get(CgiAdbRemote.PARAM_SERIAL);
        if (!serial.equals(requestSerial)) {
            final String message = format("Request for device %s sent to chimp for device %s", requestSerial, serial);
            return new NanoHTTPD.Response(CONFLICT, null, message);
        }
        return null;
    }
}
