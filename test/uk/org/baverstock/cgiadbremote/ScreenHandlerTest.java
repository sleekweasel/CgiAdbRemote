package uk.org.baverstock.cgiadbremote;


import com.android.ddmlib.IDevice;
import com.android.ddmlib.RawImage;
import fi.iki.elonen.NanoHTTPD;
import org.junit.Test;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.equalTo;
import static uk.org.baverstock.cgiadbremote.AndroidDebugBridgeWrapper.Noop.bridgeWithDevices;
import static uk.org.baverstock.cgiadbremote.FakeIDevice.anIDevice;

public class ScreenHandlerTest {
    @Test
    public void returnsDeviceRawImageAsPng() {
        RawImage screenshot = new RawImage();
        IDevice device = anIDevice().withName("device1").withSerialNumber("serial1").withScreenshot(screenshot).build();
        AndroidDebugBridgeWrapper bridge = bridgeWithDevices(device);
        ScreenHandler handler = new ScreenHandler(bridge);
        NanoHTTPD.HTTPSession session = new NullHttpSession();

        NanoHTTPD.Response response = handler.handle(session);

        assertThat(response.getMimeType(), equalTo("image/png"));
        assertThat(response.getData(), );
    }
}
