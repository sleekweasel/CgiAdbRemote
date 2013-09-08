package uk.org.baverstock.cgiadbremote;

import fi.iki.elonen.NanoHTTPD;

/**
 * Replies with screen
 */

public class ScreenHandler implements PathHandler {
    private AndroidDebugBridgeWrapper bridge;

    public ScreenHandler(AndroidDebugBridgeWrapper bridge) {
        this.bridge = bridge;
    }

    @Override
    public NanoHTTPD.Response handle(NanoHTTPD.HTTPSession session) {

        /*
                // convert raw data to an Image
        BufferedImage image = new BufferedImage(rawImage.width, rawImage.height,
                BufferedImage.TYPE_INT_ARGB);
 
        int index = 0;
        int IndexInc = rawImage.bpp >> 3;
        for (int y = 0 ; y < rawImage.height ; y++) {
            for (int x = 0 ; x < rawImage.width ; x++) {
                int value = rawImage.getARGB(index);
                index += IndexInc;
                image.setRGB(x, y, value);
            }
        }
 
        if (!ImageIO.write(image, "png", new File(filepath))) {
            throw new IOException("Failed to find png writer");
        }/
         */

        throw new RuntimeException("unimplemented");
    }
}
