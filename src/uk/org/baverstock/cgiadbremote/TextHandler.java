package uk.org.baverstock.cgiadbremote;

import com.android.chimpchat.core.IChimpDevice;
import com.android.chimpchat.core.PhysicalButton;
import com.android.chimpchat.core.TouchPressType;
import fi.iki.elonen.NanoHTTPD;

/**
 * Hack this - bored.
 */

public class TextHandler implements PathHandler {

	private DeviceConnectionMap deviceConnectionMap;

	public TextHandler(DeviceConnectionMap deviceConnectionMap) {
		this.deviceConnectionMap = deviceConnectionMap;
	}

	@Override
	public NanoHTTPD.Response handle(NanoHTTPD.IHTTPSession session) {
		IChimpDevice iChimpDevice = deviceConnectionMap.getDeviceBySerial(session.getParms().get(
				CgiAdbRemote.PARAM_SERIAL));
		int key = Integer.parseInt(session.getParms().get("key"));
		synchronized (iChimpDevice) {
			switch (key) {
			case 3:
				iChimpDevice.press(PhysicalButton.HOME, TouchPressType.DOWN_AND_UP);
				break;
			case 82:
				iChimpDevice.press(PhysicalButton.MENU, TouchPressType.DOWN_AND_UP);
				break;
			case 4:
				iChimpDevice.press(PhysicalButton.BACK, TouchPressType.DOWN_AND_UP);
				break;
			case 84:
				iChimpDevice.press(PhysicalButton.SEARCH, TouchPressType.DOWN_AND_UP);
				break;
			case 19:
				iChimpDevice.press(PhysicalButton.DPAD_UP, TouchPressType.DOWN_AND_UP);
				break;
			case 20:
				iChimpDevice.press(PhysicalButton.DPAD_DOWN, TouchPressType.DOWN_AND_UP);
				break;
			case 21:
				iChimpDevice.press(PhysicalButton.DPAD_LEFT, TouchPressType.DOWN_AND_UP);
				break;
			case 22:
				iChimpDevice.press(PhysicalButton.DPAD_RIGHT, TouchPressType.DOWN_AND_UP);
				break;
			case 23:
				iChimpDevice.press(PhysicalButton.DPAD_CENTER, TouchPressType.DOWN_AND_UP);
				break;
			case 66:
				iChimpDevice.press(PhysicalButton.ENTER, TouchPressType.DOWN_AND_UP);
				break;
			case 26:
				iChimpDevice.wake();
				break;
			case -1:
				iChimpDevice.reboot(null);
				break;
			}
		}

		return new NanoHTTPD.Response("");
	}
}
