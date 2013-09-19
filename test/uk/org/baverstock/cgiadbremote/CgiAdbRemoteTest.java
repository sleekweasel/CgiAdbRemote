package uk.org.baverstock.cgiadbremote;

import fi.iki.elonen.NanoHTTPD;
import org.junit.Test;

import java.util.HashMap;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.junit.Assert.assertThat;
import static uk.org.baverstock.cgiadbremote.StatusMatchers.hasStatus;

public class CgiAdbRemoteTest {

    public static final String UNKNOWN_PATH = "unknown_path";

    public static final String KNOWN_PATH = "/some_thing";
    public static final String KNOWN_RESPONSE = "known response";

    private final HashMap<String,PathHandler> testMap = new HashMap<String, PathHandler>();
    {
        testMap.put(KNOWN_PATH, new PathHandler() {
            @Override
            public NanoHTTPD.Response handle(NanoHTTPD.IHTTPSession session) {
                return new NanoHTTPD.Response(KNOWN_RESPONSE);
            }
        });
    }

    private final CgiAdbRemote cgiAdbRemote = new CgiAdbRemote(8080, testMap);

    private NullHttpSession pathHttpSession(final String path) {
        return new NullHttpSession() {
            @Override
            public String getPath() {
                return path;
            }
        };
    }

    @Test
    public void returns404ForUnknownPaths() {
        NanoHTTPD.Response serve = cgiAdbRemote.serve(pathHttpSession(UNKNOWN_PATH));
        assertThat(serve, hasStatus(NanoHTTPD.Response.Status.NOT_FOUND));
    }

    @Test
    public void returnsResponseOfPathHandler() {
        NanoHTTPD.Response serve = cgiAdbRemote.serve(pathHttpSession(KNOWN_PATH));
        assertThat(serve.getStatus(), equalTo(NanoHTTPD.Response.Status.OK));
        assertThat(serve.getData(), StatusMatchers.holdsString(equalTo(KNOWN_RESPONSE)));
    }
}
