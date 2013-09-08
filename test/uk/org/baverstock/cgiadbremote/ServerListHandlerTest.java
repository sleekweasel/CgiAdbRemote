package uk.org.baverstock.cgiadbremote;

import com.android.ddmlib.IDevice;
import fi.iki.elonen.NanoHTTPD;
import org.junit.Test;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.allOf;
import static org.hamcrest.Matchers.containsString;
import static uk.org.baverstock.cgiadbremote.AndroidDebugBridgeWrapper.Noop.bridgeWithDevices;
import static uk.org.baverstock.cgiadbremote.StatusMatchers.holdsString;

public class ServerListHandlerTest {
    @Test
    public void returnsPageListingCurrentDevices() {
        final IDevice device1 = FakeIDevice.anIDevice().withName("device1").withSerialNumber("serial1").build();
        final IDevice device2 = FakeIDevice.anIDevice().withName("device2").withSerialNumber("serial2").build();
        AndroidDebugBridgeWrapper bridge = bridgeWithDevices(device1, device2);

        ServerListHandler handler = new ServerListHandler(bridge);
        NanoHTTPD.HTTPSession session = new NullHttpSession();

        NanoHTTPD.Response response = handler.handle(session);

        assertThat(response.getData(), holdsString(allOf(
                containsString("<a href='/console?device=serial1'>device1</a>"),
                containsString("<a href='/console?device=serial2'>device2</a>"))));
    }
}
