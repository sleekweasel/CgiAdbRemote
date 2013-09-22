package uk.org.baverstock.cgiadbremote.master;

import uk.org.baverstock.cgiadbremote.CgiAdbRemote;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.lang.management.ManagementFactory;
import java.net.ServerSocket;
import java.net.URISyntaxException;
import java.security.CodeSource;
import java.util.*;

/**
 * Creates and curates monkey slaves associated with particular serial numbers.
 */

public class MonkeySlaveProvider {

    private Map<String, Integer> serialToPort = new HashMap<String, Integer>();
    private Map<Integer, Process> portToProcess = new HashMap<Integer, Process>();
    private Map<Integer, String> portToSerial = new HashMap<Integer, String>();

    public int getMonkeyPort(String serial) {
        Integer monkey = serialToPort.get(serial);
        if (monkey != null) {
            Process process = portToProcess.get(monkey);
            if (!processLives(process)) {
                drop(monkey);
                monkey = null;
            }
        }
        if (monkey == null) {
            List<String> inputArguments = ManagementFactory.getRuntimeMXBean().getInputArguments();
            List<String> monkeyArgs = new ArrayList<String>(inputArguments);
            final int slavePort = getFreeSocket();
            if (slavePort == -1) {
                return slavePort;
            }
            monkeyArgs.add("-Dslave=" + slavePort);
            try {
                CodeSource codeSource = CgiAdbRemote.class.getProtectionDomain().getCodeSource();
                File jarFile = new File(codeSource.getLocation().toURI().getPath());
                if (jarFile.getPath().endsWith(".jar")) {
                    monkeyArgs.add(0, jarFile.getPath());
                    monkeyArgs.add(0, "-jar");
                    monkeyArgs.add(0, "java");
                } else {
                    monkeyArgs.add(0, "uk.org.baverstock.cgiadbremote.CgiAdbRemote");
                    monkeyArgs.add(0, System.getProperty("java.class.path"));
                    monkeyArgs.add(0, "-cp");
                    monkeyArgs.add(0, "java");
                }
            } catch (URISyntaxException e) {
                throw new RuntimeException(e);
            }
            System.out.println(monkeyArgs);
            ProcessBuilder processBuilder = new ProcessBuilder(monkeyArgs);
            processBuilder.redirectErrorStream(true);
            try {
                final Process process = processBuilder.start();
                add(monkey, process, serial);
                final InputStream inputStream = process.getInputStream();
                new Thread(new Runnable() {
                    @Override
                    public void run() {
                        int size = 8192;
                        byte buffer[] = new byte[size];
                        try {
                            for (int read = 0; read != -1; read = inputStream.read(buffer)) {
                                System.err.write(buffer, 0, read);
                            }
                        } catch (IOException e) {
                            process.destroy();
                            drop(slavePort);
                        }
                    }
                }).start();
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
            monkey = slavePort;
        }
        return monkey;
    }

    private int getFreeSocket() {
        for (int retry = 10; retry > 0; --retry) {
            ServerSocket serverSocket = null;
            try {
                serverSocket = new ServerSocket(0);
                int slavePort = serverSocket.getLocalPort() + 1; // Haha. No way.
                serverSocket.close();
                if (slavePort > 0) {
                    return slavePort;
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        return -1;
    }

    private void add(Integer port, Process process, String serial) {
        synchronized (portToProcess) {
            if (!portToProcess.containsKey(port)) {
                portToProcess.put(port, process);
                serialToPort.put(serial, port);
                portToSerial.put(port, serial);
            }
        }
    }

    private void drop(Integer monkey) {
        synchronized (portToProcess) {
            if (portToProcess.containsKey(monkey)) {
                portToProcess.remove(monkey);
                String serial = portToSerial.remove(monkey);
                serialToPort.remove(serial);
            }
        }
    }

    private boolean processLives(Process process) {
        try {
            process.exitValue();
            return true;
        }
        catch (IllegalThreadStateException e) {
            return false;
        }
    }

    public void killAllTheMonkeys() {
        for (Process process : portToProcess.values()) {
            process.destroy();
        }
        portToProcess.clear();
        serialToPort.clear();
        portToSerial.clear();
    }
}
