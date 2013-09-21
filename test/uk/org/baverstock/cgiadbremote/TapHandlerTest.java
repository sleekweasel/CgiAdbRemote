package uk.org.baverstock.cgiadbremote;

import com.android.chimpchat.core.IChimpDevice;
import com.android.chimpchat.core.TouchPressType;
import fi.iki.elonen.NanoHTTPD;
import org.jmock.Expectations;
import org.jmock.integration.junit4.JUnitRuleMockery;
import org.junit.Rule;
import org.junit.Test;

import static fi.iki.elonen.NanoHTTPD.Response.Status.CONFLICT;
import static fi.iki.elonen.NanoHTTPD.Response.Status.NO_CONTENT;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.core.IsEqual.equalTo;

public class TapHandlerTest {
    private static final String SERIAL = "22344";

    @Rule
    public JUnitRuleMockery mockery = new JUnitRuleMockery();
    private final DeviceConnectionMap deviceConnectionMap = mockery.mock(DeviceConnectionMap.class);
    private final IChimpDevice device = mockery.mock(IChimpDevice.class);

    @Test
    public void tapFromConsoleTapsOnCorrectMonkey() {
        mockery.checking(new Expectations(){{
            allowing(deviceConnectionMap).getDeviceBySerial(SERIAL); will(returnValue(device));
            oneOf(device).touch(10, 50, TouchPressType.DOWN_AND_UP);
        }});

        PathHandler handler = new TapHandler(deviceConnectionMap);

        NanoHTTPD.Response response = handler.handle(TestBeans.sessionWithParams(
                CgiAdbRemote.PARAM_COORDS, "?10,50",
                CgiAdbRemote.PARAM_SERIAL, SERIAL
        ));

        assertThat(response.getStatus(), equalTo(NO_CONTENT));
    }

    @Test
    public void tapFromConsoleWithoutCoordsExplodes() {
        mockery.checking(new Expectations(){{
            allowing(deviceConnectionMap).getDeviceBySerial(SERIAL); will(returnValue(device));
        }});

        PathHandler handler = new TapHandler(deviceConnectionMap);

        NanoHTTPD.Response response = handler.handle(TestBeans.sessionWithParams(
//                CgiAdbRemote.PARAM_COORDS, "?10,50",
                CgiAdbRemote.PARAM_SERIAL, SERIAL
        ));

        assertThat(response.getStatus(), equalTo(CONFLICT));
    }

    @Test
    public void tapFromConsoleWithoutMappedMonkeyExplodes() {
        mockery.checking(new Expectations(){{
            allowing(deviceConnectionMap).getDeviceBySerial(SERIAL); will(returnValue(null));
        }});

        PathHandler handler = new TapHandler(deviceConnectionMap);

        NanoHTTPD.Response response = handler.handle(TestBeans.sessionWithParams(
                CgiAdbRemote.PARAM_COORDS, "?10,50",
                CgiAdbRemote.PARAM_SERIAL, SERIAL
        ));

        assertThat(response.getStatus(), equalTo(CONFLICT));
    }

    @Test
    public void tapFromConsoleWithoutSerialExplodes() {
        PathHandler handler = new TapHandler(deviceConnectionMap);

        NanoHTTPD.Response response = handler.handle(TestBeans.sessionWithParams(
                CgiAdbRemote.PARAM_COORDS, "?10,50"
        ));

        assertThat(response.getStatus(), equalTo(CONFLICT));
    }
}
