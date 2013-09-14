package uk.org.baverstock.cgiadbremote;


import com.android.ddmlib.AdbCommandRejectedException;
import com.android.ddmlib.IDevice;
import com.android.ddmlib.TimeoutException;
import fi.iki.elonen.NanoHTTPD;
import org.junit.Test;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;
import static uk.org.baverstock.cgiadbremote.AndroidDebugBridgeWrapper.Noop.bridgeWithDevices;
import static uk.org.baverstock.cgiadbremote.FakeIDevice.anIDevice;

public class ScreenHandlerTest {

    public static final String YOUR_PNG_FILE = "Your PNG file";
    private final DeviceToInputStream screenshotToInputStream = new DeviceToInputStream() {
        @Override
        public InputStream convert(
                IDevice device
        ) throws AdbCommandRejectedException, IOException, TimeoutException
        {
            return new ByteArrayInputStream(YOUR_PNG_FILE.getBytes());
        }
    };
    private final IDevice device = anIDevice().withName("device1").withSerialNumber("serial1").build();
    private final AndroidDebugBridgeWrapper bridge = bridgeWithDevices(device);
    private final ScreenHandler handler = new ScreenHandler(bridge, screenshotToInputStream);

    @Test
    public void returnsDeviceRawImageAsPng() {
        NanoHTTPD.HTTPSession session = new NullHttpSession() {
            @Override
            public Map<String, String> getParms() {
                HashMap<String, String> map = new HashMap<String, String>();
                map.put(CgiAdbRemote.PARAM_SERIAL, "serial1");
                return map;
            }
        };

        NanoHTTPD.Response response = handler.handle(session);

        assertThat(response.getData(), StatusMatchers.holdsString(equalTo(YOUR_PNG_FILE)));
        assertThat(response.getMimeType(), equalTo("image/png"));
    }

    @Test
    public void returns404OnError() {
        NanoHTTPD.HTTPSession session = new NullHttpSession() {
            @Override
            public Map<String, String> getParms() {
                return new HashMap<String, String>();
            }
        };

        NanoHTTPD.Response response = handler.handle(session);

        assertThat(response.getMimeType(), equalTo("text/plain"));
        assertThat(response.getData(), StatusMatchers.holdsString(containsString("No device connected with serial number 'null'")));
    }
}
