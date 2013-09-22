package uk.org.baverstock.cgiadbremote.slave;

import com.android.chimpchat.core.TouchPressType;
import fi.iki.elonen.NanoHTTPD;

/**
 * Represents points
 */
public class Touch {

    static final String[] param = {"up", "move", "down"};
    static final TouchPressType[] type = {TouchPressType.UP, TouchPressType.MOVE, TouchPressType.DOWN};

    public int x;
    public int y;
    public TouchPressType touchPressType;

    public Touch(TouchPressType touchPressType, int x, int y) {
        this.touchPressType = touchPressType;
        this.x = x;
        this.y = y;
    }

    public static Touch fromString(TouchPressType touchPressType, String coords) {
        if (coords == null) {
            return null;
        }
        try {
            if (coords.charAt(0) == '?') {
                coords = coords.substring(1);
            }
            String[] pair = coords.split(",");
            return new Touch(touchPressType, Integer.parseInt(pair[0]), Integer.parseInt(pair[1]));
        }
        catch (NumberFormatException e) {
            return null;
        }
    }

    public static Touch fromParams(NanoHTTPD.IHTTPSession session) {
        for (int i = 0; i < param.length; ++i) {
            Touch touch = Touch.fromString(type[i], session.getParms().get(param[i]));
            if (touch != null) {
                return touch;
            }
        }
        return null;
    }
}
