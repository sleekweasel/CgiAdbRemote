package uk.org.baverstock.cgiadbremote;

import com.android.chimpchat.core.IChimpDevice;
import com.android.chimpchat.core.TouchPressType;
import fi.iki.elonen.NanoHTTPD;
import org.jmock.Expectations;
import org.jmock.integration.junit4.JUnitRuleMockery;
import org.junit.Rule;
import org.junit.Test;
import uk.org.baverstock.cgiadbremote.slave.TouchHandler;

import static fi.iki.elonen.NanoHTTPD.Response.Status.CONFLICT;
import static fi.iki.elonen.NanoHTTPD.Response.Status.NO_CONTENT;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.core.IsEqual.equalTo;

public class TouchHandlerTest {
    private static final String SERIAL = "22344";

    @Rule
    public JUnitRuleMockery mockery = new JUnitRuleMockery();
    private final IChimpDevice device = mockery.mock(IChimpDevice.class);

    @Test
    public void tapFromConsoleTapsOnCorrectMonkey() {
        mockery.checking(new Expectations(){{
            oneOf(device).touch(10, 50, TouchPressType.UP);
        }});

        PathHandler handler = new TouchHandler(device, SERIAL);

        NanoHTTPD.Response response = handler.handle(TestBeans.sessionWithParams(
                "up", "?10,50",
                CgiAdbRemote.PARAM_SERIAL, SERIAL
        ));

        assertThat(response.getStatus(), equalTo(NO_CONTENT));
    }

    @Test
    public void tapFromConsoleWithoutCoordsExplodes() {
        PathHandler handler = new TouchHandler(device, SERIAL);

        NanoHTTPD.Response response = handler.handle(TestBeans.sessionWithParams(
                CgiAdbRemote.PARAM_SERIAL, SERIAL
        ));

        assertThat(response.getStatus(), equalTo(CONFLICT));
    }

    @Test
    public void tapFromConsoleWithWrongMonkeyExplodes() {
        PathHandler handler = new TouchHandler(device, "qwert");

        NanoHTTPD.Response response = handler.handle(TestBeans.sessionWithParams(
                "down", "?10,50",
                CgiAdbRemote.PARAM_SERIAL, SERIAL
        ));

        assertThat(response.getStatus(), equalTo(CONFLICT));
    }

    @Test
    public void tapFromConsoleWithoutSerialExplodes() {
        PathHandler handler = new TouchHandler(device, SERIAL);

        NanoHTTPD.Response response = handler.handle(TestBeans.sessionWithParams(
                "move", "?10,50"
        ));

        assertThat(response.getStatus(), equalTo(CONFLICT));
    }
}
