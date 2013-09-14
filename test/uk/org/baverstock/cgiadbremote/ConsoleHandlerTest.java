package uk.org.baverstock.cgiadbremote;

import fi.iki.elonen.NanoHTTPD;
import org.junit.Test;

import java.util.HashMap;
import java.util.Map;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.core.StringContains.containsString;
import static uk.org.baverstock.cgiadbremote.StatusMatchers.holdsString;

public class ConsoleHandlerTest {

    @Test
    public void consoleIncludesScreenshot() {
//        IDevice iDevice = anIDevice().withName("device1").withSerialNumber("serial1").build();
//        AndroidDebugBridgeWrapper bridge = bridgeWithDevices(iDevice);

        ConsoleHandler handler = new ConsoleHandler();
        NanoHTTPD.HTTPSession session = sessionWithParams("device", "serial1");

        NanoHTTPD.Response response = handler.handle(session);

        assertThat(response.getData(), holdsString(containsString("<img src='" + CgiAdbRemote.SCREEN_PATH + "?device=serial1' />")));
    }

    private NullHttpSession sessionWithParams(final String... data) {
        return new NullHttpSession() {
            @Override
            public Map<String, String> getParms() {
                HashMap<String, String> map = new HashMap<String, String>();
                for (int i=0; i < data.length; i+=2) {
                    map.put(data[i], data[i+1]);
                }
                return map;
            }
        };
    }
}
