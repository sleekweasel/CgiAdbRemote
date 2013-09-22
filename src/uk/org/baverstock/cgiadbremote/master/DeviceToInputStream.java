package uk.org.baverstock.cgiadbremote.master;

import com.android.ddmlib.AdbCommandRejectedException;
import com.android.ddmlib.IDevice;
import com.android.ddmlib.TimeoutException;

import java.io.IOException;
import java.io.InputStream;

/**
 * Bridge-style device returns a stream - e.g. screenshot.
 */

public interface DeviceToInputStream {
    InputStream convert(IDevice device) throws AdbCommandRejectedException, IOException, TimeoutException;
}
