# THIS IS A HORRIBLE BODGE - it downloads the github repo at build time. LOL.
FROM  ubuntu
RUN apt-get update && apt-get -y install git libhttp-server-simple-perl libhttp-daemon-perl
# Keep your key constant, so you only do the 'approve' thing once for devices
COPY adbkey /root/.android/adbkey
COPY adbkey.pub /root/.android/adbkey.pub
# I needed multiple internally-built adb versions for historical reasons - you can just use the one you need.
COPY adb-7aug-usbbus-maxemu-v40 /root/adb-7aug-usbbus-maxemu-v40
COPY adb-server_autostart_false-v39 /root/adb-server_autostart_false-v39
COPY adb-upstream-v41 /root/adb-upstream-v41
ENV ADB_SERVER_AUTOSTART=false
RUN mkdir    /root/git && cd /root/git/. && git clone https://github.com/sleekweasel/CgiAdbRemote.git && git -C CgiAdbRemote checkout multifork

# Run this with...
# NB: different ADB_SERVER_SOCKET and external port for each adb version.
# NB: --net=host and --pid=host for finding and using other localhostish adbd instances. Don't judge me.
#
# docker run --name cgi-bin-remote-instance-8080 \
#                --pid=host --net=host --privileged \
#                --detach \
#                -e ADB_SERVER_SOCKET=tcp:localhost:9134 \
#                --restart=unless-stopped \
#                -e ADB_SERVER_AUTOSTART=false \
#                YOUR-REPO-HERE/cgi-bin-remote \
#                 /root/git/CgiAdbRemote/CgiAdbRemote.pl \
#                   -foreground \
#                   -port=8080 \
#                   -adb=/root/adb-server_autostart_false-v39
