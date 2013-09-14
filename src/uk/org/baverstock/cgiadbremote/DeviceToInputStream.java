package uk.org.baverstock.cgiadbremote;

import com.android.ddmlib.AdbCommandRejectedException;
import com.android.ddmlib.IDevice;
import com.android.ddmlib.TimeoutException;

import java.io.IOException;
import java.io.InputStream;

/**
 * Does...
 */

public interface DeviceToInputStream {
    InputStream convert(IDevice device) throws AdbCommandRejectedException, IOException, TimeoutException;
}
