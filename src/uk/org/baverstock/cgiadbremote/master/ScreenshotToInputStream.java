package uk.org.baverstock.cgiadbremote.master;

import com.android.ddmlib.AdbCommandRejectedException;
import com.android.ddmlib.IDevice;
import com.android.ddmlib.RawImage;
import com.android.ddmlib.TimeoutException;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.*;

/**
* Gets a screenshot from the device and squirts the PNG of it to the stream.
*/
public class ScreenshotToInputStream implements DeviceToInputStream {
    @Override
    public InputStream convert(final IDevice device) throws AdbCommandRejectedException, IOException, TimeoutException {
        final PipedInputStream inputStream = new PipedInputStream();
        final OutputStream outputStream = new PipedOutputStream(inputStream);
        final RawImage rawImage = device.getScreenshot();
        new Thread(new Runnable() {
            @Override
            public void run() {
                BufferedImage image = new BufferedImage(rawImage.width, rawImage.height,
                        BufferedImage.TYPE_INT_ARGB);
                int index = 0;
                int IndexInc = rawImage.bpp >> 3;
                for (int y = 0; y < rawImage.height; y++) {
                    for (int x = 0; x < rawImage.width; x++) {
                        int value = rawImage.getARGB(index);
                        index += IndexInc;
                        image.setRGB(x, y, value);
                    }
                }
                try {
                    try {
                        ImageIO.write(image, "png", outputStream);
                    }
                    finally {
                        outputStream.close();
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                    System.err.println("Failed: " + e);
                    System.err.flush();
                }
            }
        }).start();
        return inputStream;
    }
}
