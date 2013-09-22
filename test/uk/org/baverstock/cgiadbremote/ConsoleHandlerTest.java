package uk.org.baverstock.cgiadbremote;

import fi.iki.elonen.NanoHTTPD;
import org.junit.Test;
import uk.org.baverstock.cgiadbremote.master.ConsoleHandler;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.core.StringContains.containsString;
import static uk.org.baverstock.cgiadbremote.StatusMatchers.holdsString;

public class ConsoleHandlerTest {

    @Test
    public void consoleIncludesScreenshot() {
        ConsoleHandler handler = new ConsoleHandler(TestBeans.BRIDGE, null);
        NanoHTTPD.IHTTPSession session = TestBeans.sessionWithParams("device", "serial1");

        NanoHTTPD.Response response = handler.handle(session);

        assertThat(response.getData(), holdsString(containsString("<img src='" + "/screendump" + "?device=serial1'")));
    }
}
