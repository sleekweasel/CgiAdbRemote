package uk.org.baverstock.cgiadbremote.master;

import uk.org.baverstock.cgiadbremote.CgiAdbRemote;

import java.io.*;
import java.lang.management.ManagementFactory;
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
            try {
                process.exitValue();
                drop(monkey, new RuntimeException("Monkey already dead"));
                monkey = null;
            } catch (IllegalThreadStateException e) {
            }
        }
        if (monkey == null) {
            List<String> inputArguments = ManagementFactory.getRuntimeMXBean().getInputArguments();
            List<String> monkeyArgs = new ArrayList<String>(inputArguments);
            monkeyArgs.add("-Dslave="+serial);
            try {
                CodeSource codeSource = CgiAdbRemote.class.getProtectionDomain().getCodeSource();
                File jarFile = new File(codeSource.getLocation().toURI().getPath());
                if (jarFile.getPath().endsWith(".jar")) {
                    monkeyArgs.add("-jar");
                    monkeyArgs.add(jarFile.getPath());
                    monkeyArgs.add(0, "java");
                } else {
                    monkeyArgs.add("uk.org.baverstock.cgiadbremote.CgiAdbRemote");
                    monkeyArgs.add(0, System.getProperty("java.class.path"));
                    monkeyArgs.add(0, "-cp");
                    monkeyArgs.add(0, "java");
                }
            } catch (URISyntaxException e) {
                throw new RuntimeException(e);
            }
            System.out.println(monkeyArgs);
            ProcessBuilder processBuilder = new ProcessBuilder(monkeyArgs);
            try {
                final Process process = processBuilder.start();
                InputStream inputStream1 = process.getInputStream();
                System.out.println(inputStream1.toString());
                BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(inputStream1));
                for (int times = 10; times > 0 && monkey == null; --times) {
//                    try {
//                        Thread.sleep(1000);
//                    } catch (InterruptedException e) {
//                        e.printStackTrace();
//                    }
                    String line = bufferedReader.readLine();
                    System.out.println(line);
                    if (line != null)
                    try {
                        monkey = Integer.parseInt(line.split(" ")[0]);
                    }
                    catch (Exception e) {
                        System.out.println(e.toString());
                    }
                }
                final Integer slavePort = monkey;
                System.out.println("Monkey port " + monkey + " for " + serial);
                add(slavePort, process, serial);
                final InputStream inputStream = process.getErrorStream();
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
                            drop(slavePort, e);
                        }
                    }
                }).start();
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }
        return monkey;
    }

    private void add(Integer port, Process process, String serial) {
        synchronized (portToProcess) {
            if (portToProcess.containsKey(port)) {
                System.out.println(String.format("Attempt to re-chimp %s on %d!", serial, port));
            }
            else {
                System.out.println(String.format("Chimping %s on %d!", serial, port));
                portToProcess.put(port, process);
                serialToPort.put(serial, port);
                portToSerial.put(port, serial);
            }
        }
    }

    private void drop(Integer monkey, Exception e) {
        synchronized (portToProcess) {
            if (portToProcess.containsKey(monkey)) {
                portToProcess.remove(monkey);
                String serial = portToSerial.remove(monkey);
                serialToPort.remove(serial);
                System.out.println(String.format("De-chimped %s on %d because...", serial, monkey));
                e.printStackTrace();
            } else {
                System.out.println("Unmapped port has no monkey: " + monkey + " because...");
                e.printStackTrace();
            }
        }
    }


    public void killAllTheMonkeys() {
        for (Process process : portToProcess.values()) {
            for (Map.Entry<Integer, Process> integerProcessEntry : portToProcess.entrySet()) {
                if (integerProcessEntry.getValue().equals(process)) {
                    System.err.println("Dechimping " + integerProcessEntry.getKey());
                }
            }
            process.destroy();
        }
        portToProcess.clear();
        serialToPort.clear();
        portToSerial.clear();
    }
}
