#!/usr/bin/perl -s
#
#  Options:
die "Use -port=01, not -port 1\n" if $port eq '1';
die "Use -banner=Something, not -banner Something\n" if $banner eq '1';
die "Use -adb=Something, not -adb adb\n" if $adb eq '1';
die "use -autodelay=01, not -autodelay 1\n" if $autodelay eq '1';
die "use -touchdelay=01, not -touchdelay 1\n" if $touchdelay eq '1';

$port ||= 8080;
$foreground ||= 0;
$adb ||= 'adb';
$banner ||= "WARNING: TESTS MAY BE RUNNING";
$autodelay ||= 7;
$touchdelay ||= 1.5;

$autodelay *= 2; # Interval is 500ms
$touchdelay *= 2; # Interval is 500ms
{
  package MyWebServer;

  use HTTP::Server::Simple::CGI;
  use base qw( HTTP::Server::Simple::CGI );

  my %dispatch = (
      '/' => \&resp_root,
      '/screenshot' => \&resp_screenshot,
      '/console' => \&resp_console,
      '/killServer' => \&resp_killServer,
      '/touch' => \&resp_touch,
      '/text' => \&resp_text,
      '/setInputMode' => \&resp_setInputMode,
      '/adbCmd' => \&resp_adbCmd,
      # ...
  );

  sub logg {
    my $thing = shift;
    my $log = localtime() . ": $$: $thing\n";
    warn $log;
    print $log;
  }

  sub logw {
    my $thing = shift;
    my $log = localtime() . ": $$: $thing\n";
    warn $log;
  }

  sub errorRunning {
    my $cmd = shift;
    return "Error running '$cmd'; is adb available? "
        .(($::adb eq 'adb')?"which adb='".qx/which adb/."'":"adb=$::adb");
  }

  sub handle_request {
      my $self = shift;
      my $cgi  = shift;
    
      my $path = $cgi->path_info();
      my $handler = $dispatch{$path};
      logw $cgi->url(-query=>1, -path_info=>1);

      if (ref($handler) eq "CODE") {
          print "HTTP/1.0 200 OK\r\n";
          $handler->($cgi);
      }
      elsif (ref($handler) eq "HASH") {
          print "HTTP/1.0 $$handler{status}\r\n";
          $$handler{response}($cgi);
      }
      else {
          print "HTTP/1.0 404 Not found\r\n";
          print $cgi->header,
                $cgi->start_html('Not found'),
                $cgi->h1('Not found'),
                "The path $path was not found",
                $cgi->end_html;
      }
  }

  sub readFile {
        my $leafname = shift;
        my $filename = $0;
        $filename =~ s/[^\/]*$/$leafname/;
        return `cat $filename`;
  }

  sub execute {
    # Allow access to ?$ return code:
    local $SIG{'CHLD'} = 'DEFAULT';
    my $cmd = shift;
    return qx/$cmd/;
  }

  sub resp_root {
      my $cgi  = shift;   # CGI.pm object
      return if !ref $cgi;
      
      my $who = $cgi->param('name');
      $cmd="$::adb devices";
      @devices = execute $cmd;
      if ($? != 0) {
        push @devices, errorRunning($cmd);
      }
      
      print $cgi->header,
            $cgi->start_html("Devices");
      my $myself = $cgi->self_url;
      print $cgi->h1("$cmd ");
      print $cgi->start_ul();
      for (@devices) {
        if (/^(\S+)\s+device$/) {
            print $cgi->li($cgi->a({href=>"/console?device=$1"}, "$_"));
        }
        else {
            print $cgi->li($_);
        }
      }
      print $cgi->end_ul();
      my $killServer = readFile("killserver.html");
      $killServer=~s/(\$(::)?\w+)/eval $1/ge;
      print $killServer;
      print " " . localtime();
      print $cgi->end_html;
  }

  sub runCmd {
    my $cmd = shift;
    logg $cmd;
    print execute $cmd;
    if ($? != 0) {
        print errorRunning($cmd);
    }
  }

  sub runAdb {
    my $cmd = shift;
    runCmd "$::adb $cmd";
  }

  sub resp_console {
      my $cgi  = shift;   # CGI.pm object
      return if !ref $cgi;
      
      my $who = $cgi->param('device');

      my $myself = $cgi->self_url;

      print $cgi->header,
            $cgi->start_html("$who");
      my $console = readFile("console.html");
      $console=~s/(\$(::)?\w+)/eval $1/ge;
      print $console;
      print $cgi->end_html;
  }


  sub resp_touch {
      my $cgi  = shift;   # CGI.pm object
      return if !ref $cgi;
      
      my $who = $cgi->param('device');

      my %q;
 
      if (-f "$0.devices/$who") {
        for (qx"cat $0.devices/$who") {
          chomp;
          @q = split(/:/,$_,2);
          $q{$q[0]}=$q[1] if $q[0];
        }
      }
      $q{inputMode} ||= 0;

      my $coords = $cgi->param('coords');
      my $up = $cgi->param('swipe');
      my $down = $cgi->param('down');
      my $rot = $cgi->param('rot');
      my $img = $cgi->param('img');

      print $cgi->header,
            $cgi->start_html("$who");

      my $shell = "-s $who shell ";

      if ($coords =~ /\?(\d+),(\d+)$/) {
          runAdb "$shell input tap $1 $2";
          return;
      }
      # http://blog.softteco.com/2011/03/android-low-level-shell-click-on-screen.html
      $touch = $TOUCH[$q{inputMode}];
      if ("$down$up$img" =~ /^\?(\d+),(\d+)\?(\d+),(\d+)$/) {
        my $cmd = $touch->{down}($touch, $1, $2, $3, $4);
        runAdb "$shell \"$cmd\"" if $cmd;
        return;
      }
      if ("$down$up$img" =~ /^\?(\d+),(\d+)\?(\d+),(\d+)\?(\d+),(\d+)$/) {
        my $cmd = $touch->{downup}($touch, $3, $4, $1, $2, $5, $6);
        runAdb "$shell \"$cmd\"" if $cmd;
        return;
      }
  }

@TOUCH=(
  {
    down => sub {
      return '';
    },
    downup => sub {
      # my $self = $_[0];
      my $cmd = ($_[1] == $_[3] and $_[2] == $_[4])
        ? "input tap $_[1] $_[2]"
        : "input swipe $_[3] $_[4] $_[1] $_[2]";
      return $cmd;
    }
  },
  {
    locate => sub {
      return " sendevent /dev/input/event2 3 0 $_[1] ;".
             " sendevent /dev/input/event2 3 1 $_[2] ;";
    },
    push => sub {
      my $c = $_[0] ? 1 : 0;
      return " sendevent /dev/input/event2 1 330 $c ;". # 1 down 0 up
             " sendevent /dev/input/event2 0 0 0 ;";
    },
    down => sub {
      my $self = $_[0];
      return &{$self->{locate}}.&{$self->{push}}(1);
    },
    downup => sub {
      my $self = $_[0];
      return &{$self->{locate}}.&{$self->{push}}(0);
    }
  },
  {
## http://ktnr74.blogspot.co.uk/2013/06/emulating-touchscreen-interaction-with.html
## ABS_MT_POSITION_X (53) - x coordinate of the touch
## ABS_MT_POSITION_Y (54) - y coordinate of the touch
## ABS_MT_TOUCH_MAJOR (48) - basically width of your finger tip in pixels
## ABS_MT_PRESSURE (58) - pressure of the touch
## SYN_MT_REPORT (2) - end of separate touch data
## SYN_REPORT (0) - end of report
#    ABS (0003): ABS_MT_TOUCH_MAJOR    : value 0, min 0, max 30, fuzz 0, flat 0, resolution 0
#                ABS_MT_POSITION_X     : value 0, min 0, max 1023, fuzz 0, flat 0, resolution 0
#                ABS_MT_POSITION_Y     : value 0, min 0, max 1023, fuzz 0, flat 0, resolution 0
#                ABS_MT_TRACKING_ID    : value 0, min 0, max 4, fuzz 0, flat 0, resolution 0
#                ABS_MT_PRESSURE       : value 0, min 0, max 255, fuzz 0, flat 0, resolution 0
#
    locate => sub {
      return " sendevent /dev/input/event0 3 53 $_[0] ;". # x
             " sendevent /dev/input/event0 3 54 $_[1] ;"; # y
    },
    push => sub {
      my $c = $_[0] ? 50 : 0;
      return " sendevent /dev/input/event0 3 58 $c ;". # pressure
             " sendevent /dev/input/event0 3 48 5 ;". # width
             " sendevent /dev/input/event0 3 57 0 ;"; # finger id?
    },
    end => sub {
      return " sendevent /dev/input/event0 0 2 0 ;".
             " sendevent /dev/input/event0 0 0 0 ;";
    },
    down => sub {
      my $self = $_[0];
      my $w = $_[3];
      my $h = $_[4];
      my $x = int($_[1]*1024/$w);
      my $y = int($_[2]*1024/$h);
      return &{$self->{locate}}($x, $y).&{$self->{push}}(1).&{$self->{end}};
    },
    downup => sub {
      my $self = $_[0];
      my $w = $_[5];
      my $h = $_[6];
      my $x1 = int($_[1]*1024/$w);
      my $y1 = int($_[2]*1024/$h);
#      my $x2 = int($_[3]/$w*1024);
#      my $y2 = int($_[4]/$h*1024);
      return &{$self->{locate}}($x1,$y1).&{$self->{push}}(1).&{$self->{end}}.&{$self->{end}};
    }
  }
);

  sub resp_text {
      my $cgi  = shift;   # CGI.pm object
      return if !ref $cgi;
      
      my $who = $cgi->param('device');

      my $text = $cgi->param('text');
      my $key = $cgi->param('key');

      print $cgi->header,
            $cgi->start_html("$who");

      my $shell = "-s $who shell ";

      if ($text eq ' ') {
        $text = undef; $key = 62;
      }
      if ($text) {
          runAdb "$shell input text $text";
          return;
      }
      if ($key) {
          runAdb "$shell input keyevent $key";
          return;
      }
  }

  sub resp_screenshot {
      my $cgi  = shift;   # CGI.pm object
      return if !ref $cgi;
      
      my $who = $cgi->param('device');

      my $cmd = "$::adb -s $who  shell screencap -p";
      warn localtime().": $$: $cmd\n";
      my $image = execute $cmd;
      if ($? != 0) {
        print $cgi->header, errorRunning($cmd);
        return;
      }
      $image =~ s/\r\n/\n/g;
      $image =~ s/^\* daemon not running\. starting it now on port \d+ \*\s+\* daemon started successfully \*\s+//;
      print $cgi->header( -type => 'image/png' ), $image;
  }

  sub resp_killServer {
      my $cgi  = shift;   # CGI.pm object
      return if !ref $cgi;
      
      print $cgi->header,
            $cgi->start_html("$who");
      runAdb "kill-server";
  }

  sub readDeviceConfig {
    my %q;
    if (-f "$0.devices/$who") {
      for (qx"cat $0.devices/$who") {
        chomp;
        @q = split(/:/,$_,2);
        $q{$q[0]}=$q[1] if $q[0];
      }
    }
    return %q;
  }


# adb shell getevent -lp
#  * daemon not running. starting it now on port 5037 *
#  * daemon started successfully *
#  add device 1: /dev/input/event6
#    name:     "compass"
#    events:
#      REL (0002): REL_X                 REL_Y                 REL_Z                 REL_RX               
#                  REL_RY                REL_RZ                REL_HWHEEL            REL_DIAL             
#                  REL_WHEEL             REL_MISC             
#    input props:
#      <none>
#  add device 2: /dev/input/event5
#    name:     "cypress-touchkey"
#    events:
#      KEY (0001): KEY_HOME              KEY_MENU              KEY_BACK              KEY_SEARCH           
#    input props:
#      <none>
#  add device 3: /dev/input/event4
#    name:     "lightsensor-level"
#    events:
#      ABS (0003): ABS_MISC              : value 48, min 0, max 4095, fuzz 64, flat 0, resolution 0
#    input props:
#      <none>
#  add device 4: /dev/input/event3
#    name:     "proximity"
#    events:
#      ABS (0003): ABS_DISTANCE          : value 1, min 0, max 1, fuzz 0, flat 0, resolution 0
#    input props:
#      <none>
#  add device 5: /dev/input/event2
#    name:     "herring-keypad"
#    events:
#      KEY (0001): KEY_VOLUMEDOWN        KEY_VOLUMEUP          KEY_POWER            
#    input props:
#      <none>
#  add device 6: /dev/input/event1
#    name:     "gyro"
#    events:
#      REL (0002): REL_RX                REL_RY                REL_RZ               
#    input props:
#      <none>
#  add device 7: /dev/input/event0
#    name:     "mxt224_ts_input"
#    events:
#      ABS (0003): ABS_MT_TOUCH_MAJOR    : value 0, min 0, max 30, fuzz 0, flat 0, resolution 0
#                  ABS_MT_POSITION_X     : value 0, min 0, max 1023, fuzz 0, flat 0, resolution 0
#                  ABS_MT_POSITION_Y     : value 0, min 0, max 1023, fuzz 0, flat 0, resolution 0
#                  ABS_MT_TRACKING_ID    : value 0, min 0, max 4, fuzz 0, flat 0, resolution 0
#                  ABS_MT_PRESSURE       : value 0, min 0, max 255, fuzz 0, flat 0, resolution 0
#    input props:
#      <none>
#  
#  
# adb shell getevent -p
#  add device 1: /dev/input/event6
#    name:     "compass"
#    events:
#      REL (0002): 0000  0001  0002  0003  0004  0005  0006  0007 
#                  0008  0009 
#    input props:
#      <none>
#  add device 2: /dev/input/event5
#    name:     "cypress-touchkey"
#    events:
#      KEY (0001): 0066  008b  009e  00d9 
#    input props:
#      <none>
#  add device 3: /dev/input/event4
#    name:     "lightsensor-level"
#    events:
#      ABS (0003): 0028  : value 48, min 0, max 4095, fuzz 64, flat 0, resolution 0
#    input props:
#      <none>
#  add device 4: /dev/input/event3
#    name:     "proximity"
#    events:
#      ABS (0003): 0019  : value 1, min 0, max 1, fuzz 0, flat 0, resolution 0
#    input props:
#      <none>
#  add device 5: /dev/input/event2
#    name:     "herring-keypad"
#    events:
#      KEY (0001): 0072  0073  0074 
#    input props:
#      <none>
#  add device 6: /dev/input/event1
#    name:     "gyro"
#    events:
#      REL (0002): 0003  0004  0005 
#    input props:
#      <none>
#  add device 7: /dev/input/event0
#    name:     "mxt224_ts_input"
#    events:
#      ABS (0003): 0030  : value 0, min 0, max 30, fuzz 0, flat 0, resolution 0
#                  0035  : value 0, min 0, max 1023, fuzz 0, flat 0, resolution 0
#                  0036  : value 0, min 0, max 1023, fuzz 0, flat 0, resolution 0
#                  0039  : value 0, min 0, max 4, fuzz 0, flat 0, resolution 0
#                  003a  : value 0, min 0, max 255, fuzz 0, flat 0, resolution 0
#    input props:
#      <none>

  sub decodeGetEvent {
    my @data = qx($_[0]);
    s/\015//g for @data;
    while ($_ = shift @data) {
      next if /^\s+\*/;
      if (/add device \d+: (/dev/.*)$/) {
        $device = $1;
        $name = undef;
      }
      elsif (/^\s+name:\s+"(.*)"\s*/) {
        $name = $1;
      }
      elsif (/^\s+events:\s+$/) {
        $_ = shift;
        while (s/^\s+(\w+)\s+\((\w+)\)://) {
          my @values = ();
          do {
            if (/:/) {
              unshift @values, $_;
            }
            else {
              unshift @values, split(" ", $_);
            }
            $_ = shift;
          } while (!/:\s*$/ && !/^\s+\w+\s+\(\w+\):/);
          $event{"$device:$name"} = \@values;
        }
      }
    }
    return \%event;
  }

  sub resp_setInputMode {
      my $cgi  = shift;   # CGI.pm object
      return if !ref $cgi;
      
      my $who = $cgi->param('device');
      my $mode = $cgi->param('mode');

      my %q = readDeviceConfig();

      $q{inputMode}=$mode;

      print $cgi->header,
            $cgi->start_html("$who");
      logg "mode=$mode";

      if ($mode) {
        my $cmdw = decodeGetEvent("adb shell -d $who getevent -lp");
        my $cmdn = decodeGetEvent("adb shell -d $who getevent -p");
      }

      mkdir("$0.devices");
      if (open FILE, ">$0.devices/$who") {
        for (sort keys %q) {
          print FILE "$_:$q{$_}\n";
        }
        close FILE;
      }
  }
  sub resp_adbCmd {
      my $cgi  = shift;   # CGI.pm object
      return if !ref $cgi;
      
      my $who = $cgi->param('device');
      my $cmd = $cgi->param('cmd');

      print $cgi->header,
            $cgi->start_html("$who");
      runAdb "-s $who shell $cmd" if $cmd !~ /^\s*$/;
  }
}

# start the server on $port
if ($foreground) {
  print "Ctrl-C to interrupt the server\n";
  MyWebServer->new($port)->run();
}
else {
  my $pid = MyWebServer->new($port)->background();
  print "Use 'kill $pid' to stop server running on port $port.\n";
}

