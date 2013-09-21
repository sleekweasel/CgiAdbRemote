package uk.org.baverstock.cgiadbremote;

/**
 * Represents points
 */
class Point {
    public int x;
    public int y;

    public Point(int x, int y) {
        this.x = x;
        this.y = y;
    }

    static Point fromString(String coords) {
        if (coords == null) {
            return null;
        }
        try {
            if (coords.charAt(0) == '?') {
                coords = coords.substring(1);
            }
            String[] pair = coords.split(",");
            return new Point(Integer.parseInt(pair[0]), Integer.parseInt(pair[1]));
        }
        catch (NumberFormatException e) {
            return null;
        }
    }
}
