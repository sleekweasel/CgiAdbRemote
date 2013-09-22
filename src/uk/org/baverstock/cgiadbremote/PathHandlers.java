package uk.org.baverstock.cgiadbremote;

import uk.org.baverstock.cgiadbremote.master.ResourceHandler;

import java.util.HashMap;
import java.util.Map;

/**
 * Packages path handling and shutdown
 */

public class PathHandlers {
    Map<String, PathHandler> handlers = new HashMap<String, PathHandler>();

    public void stop() {
    }

    public void put(String path, PathHandler pathHandler) {
        handlers.put(path, pathHandler);
    }

    public PathHandler get(String path) {
        return handlers.get(path);
    }
}
