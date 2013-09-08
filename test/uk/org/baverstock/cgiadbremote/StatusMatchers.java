package uk.org.baverstock.cgiadbremote;

import fi.iki.elonen.NanoHTTPD;
import org.hamcrest.Description;
import org.hamcrest.Matcher;
import org.hamcrest.TypeSafeDiagnosingMatcher;

import java.io.*;

/**
 * Does...
 */

public class StatusMatchers {
    public static Matcher<NanoHTTPD.Response> hasStatus(final NanoHTTPD.Response.Status expected) {
        return new TypeSafeDiagnosingMatcher<NanoHTTPD.Response>() {
            @Override
            protected boolean matchesSafely(NanoHTTPD.Response response, Description but) {
                NanoHTTPD.Response.Status actual = response.getStatus();
                but.appendText("had status " + actual);
                return expected == actual;
            }

            @Override
            public void describeTo(Description expecting) {
                expecting.appendText("status to be " + expected);
            }
        };
    }

    public static Matcher<InputStream> holdsString(final Matcher<String> stringMatcher) {
        return new TypeSafeDiagnosingMatcher<InputStream>() {

            private String heldString;

            @Override
            protected boolean matchesSafely(InputStream inputStream, Description but) {
                final char[] buffer = new char[8192];
                final StringBuilder out = new StringBuilder();
                try {
                    final Reader in = new InputStreamReader(inputStream, "UTF-8");
                    try {
                        for (; ; ) {
                            int rsz = in.read(buffer, 0, buffer.length);
                            if (rsz < 0)
                                break;
                            out.append(buffer, 0, rsz);
                        }
                    } finally {
                        in.close();
                    }
                } catch (UnsupportedEncodingException ex) {
                    throw new RuntimeException(ex);
                } catch (IOException ex) {
                    throw new RuntimeException(ex);
                }
                if (but instanceof Description.NullDescription) {
                    heldString = out.toString();
                }
                but.appendText("held string '" + heldString + "'");
                return stringMatcher.matches(heldString);
            }

            @Override
            public void describeTo(Description expecting) {
                expecting.appendText("holding string ").appendDescriptionOf(stringMatcher);
            }
        };
    }
}
