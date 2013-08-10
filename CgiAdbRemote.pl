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

  sub Ref {
    my $d = shift;
    my $i = shift || "";
    my $x = shift || "";
    my $ref = ref $d;
    if ($ref eq 'ARRAY') {
      my $ret = "";
      for (@$d) {
        $ret .= "," if $ret;
        $ret .= "$i$x". Ref($_, "$i$x", $x);
      }
      $ret .= $i if $ret;
      return "[$ret]";
    }
    elsif ($ref eq 'HASH') {
      my $ret = "";
      for my $k (sort keys %$d) {
        $ret .= "," if $ret;
        $ret .= "$i$x$k => ". Ref($$d{$k}, "$i$x", $x);
      }
      $ret .= "$i" if $ret;
      return "{$ret}";
    }
    elsif ($ref eq 'REF') {
      return " \\ " . Ref($d, "$i$x", $x);
    }
    else {
      return "'$d'";
    }
  }

  sub loadRef {
    my $ext = shift;
    my $who = shift;
    if (open FILE, "$0.devices/$who.$ext") {
      return eval <FILE>;
    }
    return undef;
  }

  sub saveRef {
    my $ref = shift;
    my $ext = shift;
    my $who = shift;
    mkdir("$0.devices");
    if (open FILE, ">$0.devices/$who.$ext") {
      print FILE Ref($ref);
      close FILE;
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

# ####################### SERVER #################

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

  sub decodeGetEvent {
    my @data = qx($_[0]);
    my $event = {};
    s/\015//g for @data;
    while ($_ = shift @data) {
      next if /^\s+\*/;
      if (/add device \d+: (\/dev\/.*)$/) {
        $device = $1;
        $name = undef;
      }
      elsif (/^\s+name:\s+"(.*)"\s*/) {
        $name = $1;
      }
      elsif (/^\s+events:\s+$/) {
        $_ = shift @data;
        while (s/^\s+(\w+)\s+\((\w+)\)://) {
          my @values = ();
          do {
            if (/(\w+)\s+:\s+(.*)/) {
              my $name = $1;
              my $pairs = $2;
              unshift @values, { NAME => $name, split(/,?\s+/, $pairs) };
            }
            else {
              unshift @values, map { { NAME => $_ } } split(" ", $_);
            }
            $_ = shift @data;
          } while (!/:\s*$/ && !/^\s+\w+\s+\(\w+\):/);
          $$event{"$device:$name"} = \@values;
        }
      }
    }
    return $event;
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
        my $cmdw = decodeGetEvent("adb -s $who shell getevent -lp");
        my $cmdn = decodeGetEvent("adb -s $who shell getevent -p");
        my %event;
        for my $k ( keys %$cmdw ) {
          my ( $dev, $desc ) = split(/:/, $k);
          my $w = $$cmdw{$k};
          my $n = $$cmdn{$k};
          for my $l (0..((scalar @$w)-1)) {
            my $name = $$w[$l]{NAME};
            my $h = $$w[$l];
            $$h{CODE} = $$n[$l]{NAME};
            $$h{DEV} = $dev;
            $$h{DESC} = $desc;
            $event{$name} = $h;
          }
        }
        saveRef(\%event, "getevent", $who);
        $getevent{$who} = \%event;
      }

    saveRef($q, "flags", $who);
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

opendir DIR, "$0.devices";
for (readdir DIR) {
  my ( $who, $ext ) = split(/\./);
  if ( $ext eq 'getevent' ) {
    $getevent{$who}=loadRef($ext, $who);
  }
  elsif ( @ext eq 'flags' ) {
    $flags{$who}=loadRef($ext, $who);
  }
  else {
    warn "Unknown config file $_\n";
  }
}
closedir DH;

print MyWebServer::Ref($getevent, "\n ", ". "), "\n";

# start the server on $port
if ($foreground) {
  print "Ctrl-C to interrupt the server\n";
  MyWebServer->new($port)->run();
}
else {
  my $pid = MyWebServer->new($port)->background();
  print "Use 'kill $pid' to stop server running on port $port.\n";
}

