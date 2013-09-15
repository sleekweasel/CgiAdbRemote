package uk.org.baverstock.cgiadbremote;

import fi.iki.elonen.NanoHTTPD;
import org.junit.Test;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.allOf;
import static org.hamcrest.Matchers.containsString;
import static uk.org.baverstock.cgiadbremote.StatusMatchers.holdsString;

public class DeviceListHandlerTest {

    @Test
    public void returnsPageListingCurrentDevices() {
        DeviceListHandler handler = new DeviceListHandler(TestBeans.BRIDGE);
        NanoHTTPD.HTTPSession session = new NullHttpSession();

        NanoHTTPD.Response response = handler.handle(session);

        assertThat(response.getData(), holdsString(allOf(
                containsString("<a href='/console?device=serial1'>serial1</a> device1"),
                containsString("<a href='/console?device=serial2'>serial2</a> device2"))));
    }
}
