package uk.org.baverstock.cgiadbremote;

import fi.iki.elonen.NanoHTTPD;

import java.io.File;
import java.io.IOException;

/**
* Does...
*/
public class AdbKillHandler implements PathHandler {
    @Override
    public NanoHTTPD.Response handle(NanoHTTPD.IHTTPSession session) {
        File adbcmd = new File(System.getProperty("cgiadbremote.adbexec", "adb"));
        for (String path : System.getenv("PATH").split(":")) {
            File cmd = new File(new File(path), "adb");
            System.out.println("Trying " + cmd + " can " + cmd.canExecute() + cmd.canRead());
            if (cmd.canRead() && adbcmd.canExecute()) {
                adbcmd = cmd;
                break;
            }
        }
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
