package uk.org.baverstock.cgiadbremote;

import com.android.ddmlib.*;
import com.android.ddmlib.log.LogReceiver;

import java.io.IOException;
import java.util.Map;

public class FakeIDevice implements IDevice {
    private final RawImage screenshot;
    private String serialNumber;
    private String name;
    private String avdName;

    public FakeIDevice(Builder builder) {
        serialNumber = builder.serialNumber;
        name = builder.name;
        screenshot = builder.screenshot;
        avdName = builder.avdName;
    }

    public static FakeIDevice.Builder anIDevice() {
        return new FakeIDevice.Builder();
    }

    @Override
    public String getSerialNumber() {
        return serialNumber;
    }

    @Override
    public String getAvdName() {
        return avdName;
    }

    @Override
    public DeviceState getState() {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public Map<String, String> getProperties() {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public int getPropertyCount() {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public String getProperty(String s) {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public boolean arePropertiesSet() {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public String getPropertySync(
            String s
    ) throws TimeoutException, AdbCommandRejectedException, ShellCommandUnresponsiveException, IOException
    {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public String getPropertyCacheOrSync(
            String s
    ) throws TimeoutException, AdbCommandRejectedException, ShellCommandUnresponsiveException, IOException
    {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public String getMountPoint(String s) {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public boolean isOnline() {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public boolean isEmulator() {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public boolean isOffline() {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public boolean isBootLoader() {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public boolean hasClients() {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public Client[] getClients() {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public Client getClient(String s) {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public SyncService getSyncService() throws TimeoutException, AdbCommandRejectedException, IOException {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public FileListingService getFileListingService() {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public RawImage getScreenshot() throws TimeoutException, AdbCommandRejectedException, IOException {
        return screenshot;
    }

    @Override
    public void executeShellCommand(
            String s, IShellOutputReceiver iShellOutputReceiver
    ) throws TimeoutException, AdbCommandRejectedException, ShellCommandUnresponsiveException, IOException
    {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public void runEventLogService(
            LogReceiver logReceiver
    ) throws TimeoutException, AdbCommandRejectedException, IOException
    {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public void runLogService(
            String s, LogReceiver logReceiver
    ) throws TimeoutException, AdbCommandRejectedException, IOException
    {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public void createForward(int i, int i2) throws TimeoutException, AdbCommandRejectedException, IOException {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public void createForward(
            int i, String s, DeviceUnixSocketNamespace deviceUnixSocketNamespace
    ) throws TimeoutException, AdbCommandRejectedException, IOException
    {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public void removeForward(int i, int i2) throws TimeoutException, AdbCommandRejectedException, IOException {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public void removeForward(
            int i, String s, DeviceUnixSocketNamespace deviceUnixSocketNamespace
    ) throws TimeoutException, AdbCommandRejectedException, IOException
    {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public String getClientName(int i) {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public void pushFile(
            String s, String s2
    ) throws IOException, AdbCommandRejectedException, TimeoutException, SyncException
    {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public void pullFile(
            String s, String s2
    ) throws IOException, AdbCommandRejectedException, TimeoutException, SyncException
    {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public String installPackage(String s, boolean b, String... strings) throws InstallException {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public String syncPackageToDevice(
            String s
    ) throws TimeoutException, AdbCommandRejectedException, IOException, SyncException
    {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public String installRemotePackage(String s, boolean b, String... strings) throws InstallException {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public void removeRemotePackage(String s) throws InstallException {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public String uninstallPackage(String s) throws InstallException {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public void reboot(String s) throws TimeoutException, AdbCommandRejectedException, IOException {
    }

    @Override
    public Integer getBatteryLevel() throws TimeoutException, AdbCommandRejectedException, IOException, ShellCommandUnresponsiveException {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public Integer getBatteryLevel(
            long l
    ) throws TimeoutException, AdbCommandRejectedException, IOException, ShellCommandUnresponsiveException
    {
        throw new RuntimeException("unimplemented");
    }

    @Override
    public String getName() {
        return name;
    }

    @Override
    public void executeShellCommand(
            String s, IShellOutputReceiver iShellOutputReceiver, int i
    ) throws TimeoutException, AdbCommandRejectedException, ShellCommandUnresponsiveException, IOException
    {
        throw new RuntimeException("unimplemented");

    }

    public static class Builder {
        public String serialNumber;
        public String name;
        private RawImage screenshot;
        private String avdName;

        public Builder withName(String name) {
            this.name = name;
            return this;
        }

        public Builder withSerialNumber(String serialNumber) {
            this.serialNumber = serialNumber;
            return this;
        }

        public Builder withScreenshot(String screenshot) {
            this.screenshot = new RawImage();
            this.screenshot.data = screenshot.getBytes();
            return this;
        }

        public Builder withAvdName(String avdName) {
            this.avdName = avdName;
            return this;
        }

        public IDevice build() {
            return new FakeIDevice(this);
        }
    }
}
