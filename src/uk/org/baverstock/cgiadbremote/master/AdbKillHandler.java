package uk.org.baverstock.cgiadbremote.master;

import fi.iki.elonen.NanoHTTPD;
import uk.org.baverstock.cgiadbremote.MiscUtils;
import uk.org.baverstock.cgiadbremote.PathHandler;

import java.io.File;
import java.io.IOException;

/**
* Runs adb kill-server to reset everything!
*/
public class AdbKillHandler implements PathHandler {
    @Override
    public NanoHTTPD.Response handle(NanoHTTPD.IHTTPSession session) {
        File adbcmd = MiscUtils.getAdbCmd();
        ProcessBuilder adb = new ProcessBuilder(adbcmd.getAbsolutePath(), "kill-server");
        adb.redirectErrorStream(true);
        try {
            Process process = adb.start();
            return new NanoHTTPD.Response(NanoHTTPD.Response.Status.OK, "text/plain", process.getInputStream());
        } catch (IOException e) {
            return MiscUtils.getResponseForThrowable(e);
        }
    }
}
