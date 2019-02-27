#!/usr/bin/perl -s
#
#  Options:
die "Use -port=01, not -port 1\n" if $port eq '1';
die "Use -banner=Something, not -banner Something\n" if $banner eq '1';
die "Use -adb=Something, not -adb adb\n" if $adb eq '1';
die "use -autodelay=01, not -autodelay 1\n" if $autodelay eq '1';
die "use -touchdelay=01, not -touchdelay 1\n" if $touchdelay eq '1';
die "use -view_only=01, not -view_only 1\n" if $view_only eq '1';

$port ||= 8080;
$foreground ||= 0;
$adb ||= 'adb';
$banner ||= "WARNING: TESTS MAY BE RUNNING";
$autodelay ||= 7;
$touchdelay ||= 1.5;
$view_only ||= 0;

$autodelay *= 2; # Interval is 500ms
$touchdelay *= 2; # Interval is 500ms
{
  use Scalar::Util qw( reftype );

  sub Ref {
    my $d = shift;
    my $i = shift || "";
    my $x = shift || "";
    my $max = shift;
    return "TOO DEEP max=$max vs 0: " . ( $max == 0 ) if defined $max && !$max;
    $max ||= 30;
    my $ref = reftype $d;
    if ($ref eq 'ARRAY') {
      my $ret = "";
      for (@$d) {
        $ret .= "," if $ret;
        $ret .= "$i$x". Ref($_, "$i$x", $x, $max-1);
      }
      $ret .= $i if $ret;
      return "[$ret]";
    }
    elsif ($ref eq 'HASH') {
      my $ret = "";
      for my $k (sort keys %$d) {
        $ret .= "," if $ret;
        $ret .= "$i$x'$k' => ". Ref($$d{$k}, "$i$x", $x, $max-1);
      }
      $ret .= "$i" if $ret;
      return "{ ".(ref($d) =~ /:/ && ref($d))."$ret}";
    }
    elsif ($ref eq 'SCALAR') {
      return " \\ " . Ref($$d, "$i$x", $x, $max-1);
    }
    else {
      return "'$d'"
    }
  }


package CGParams;
sub new {
  my $class = shift;
  my $this = { params => { @_ } };
  bless $this, (ref($class) || $class);
  return $this;
}
sub param {
  my $this = shift;
  my $that = shift;
  $this->{params}{$that};
}
sub start_html{
  "<html><head><title>@_</title></head><body>"
}
sub end_html{ "</body></html>" }
1;

  package MyWebServer;

  use HTTP::Daemon;
  use IO::Socket::INET;
  use Data::Dumper;

#  use HTTP::Server::Simple::CGI;
#  use base qw( HTTP::Server::Simple::CGI );

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
        .(($::adb eq 'adb')?"which adb='".qx/which adb|tr -cd ' -~'/."'":"adb=$::adb");
  }

  sub loadRef {
    my $ext = shift;
    my $who = shift;
    if (open FILE, "$0.devices/$who.$ext") {
      return eval join("", <FILE>);
    }
    else {
      warn "$who.$ext: $!\n";
    }
    return {};
  }

  sub saveRef {
    my $ref = shift;
    my $ext = shift;
    my $who = shift;
    mkdir("$0.devices");
    if (open FILE, ">$0.devices/$who.$ext") {
      print FILE ::Ref($ref, "\n", " ");
      close FILE;
    }
    else {
      warn "$who.$ext: $!\n";
    }
  }

  sub readFile {
    my $filename = shift;
    unless ($filename =~ /^\//) {
      my $basename = $0;
      $basename =~ s/[^\/]*$/$filename/;
      $filename = $basename;
    }
    local $/=undef;
    open FILE, "<$filename" or die "Open $filename failed: $!";
    binmode FILE;
    $data = <FILE>;
    close FILE;
    return $data;
  }

  # Unfortunately, not all emulators have timeout - maybe deploy that adaptively.
  $TIMELIMIT='';
  if (qx(which timelimit)) {
      $TIMELIMIT='timelimit -t 20 -T 10 '
  } elsif (qx(which timeout)) {
      $TIMELIMIT='timeout -k10s 20s '
  }

  sub execute {
    my $cmd = shift;
    my $timeout = shift || 15;
    my $w = wantarray;
    eval {
        # Allow access to ?$ return code:
        local $SIG{'CHLD'} = 'DEFAULT';
        local $SIG{'ALRM'} = sub { die "alarm\n" }; # NB: \n required
        alarm $timeout;
        $cmd = "$TIMELIMIT$cmd" unless $cmd =~ /$TIMELIMIT/;
        $ret = $w ? [ qx/$cmd/ ] : qx/$cmd/;
        alarm 0;
    };
    if ($@) {
      die unless $@ eq 'alarm\n';
      return "TIMEDOUT: $cmd";
    }
    return $w ? @$ret : $ret;
  }

  sub runCmd {
    my $cmd = shift;
    logg $cmd;
    my $data = execute $cmd;
    if ($? != 0) {
        $data = errorRunning($cmd);
    }
    $data;
  }

  sub runAdb {
    my $cmd = shift;
    runCmd "$::adb $cmd";
  }

# ####################### SERVER #################

  my %dispatch = (
      '/' => \&resp_root,
      '/browsedir' => \&resp_browsedir,
      '/pullfile' => \&resp_pullfile,
      '/screenshot' => \&resp_screenshot,
      '/console' => \&resp_console,
      '/killServer' => \&resp_killServer,
      '/quitquitquit' => \&resp_quitThis,
      '/touch' => \&resp_touch,
      '/keyboard' => \&resp_keyboard,
      '/settings' => \&resp_settings,
      '/text' => \&resp_text,
      '/reboot' => \&resp_reboot,
      '/setInputMode' => \&resp_setInputMode,
      '/adbCmd' => \&resp_adbCmd,
      # ...
  );


sub NEW_SERVER {
  $cmd_server_port = 8084;
  $httpd=HTTP::Daemon->new(
    LocalPort => $cmd_server_port,
    Timeout => 5, # Seconds
    ReuseAddr => 1
  ) || die "$! for miniserver ANDROID_ADB_SERVER_PORT=$ENV{'ANDROID_ADB_SERVER_PORT'} - port $cmd_server_port";

  $MINIPID=$$;

  %requeue = ();

  while ((my $clientConn = $httpd->accept) || true) {
    unless (defined $clientConn) {
      # Tick - ensure someone's going to service outstanding requests.
      next;
    }
    my $req = $clientConn->get_request;
    unless ($req) {
      $clientConn->close if $clientComm;
      undef $clientConn;
      next
    }

    $clientConn->force_last_request; # For simplicity: this isn't high throughput.

    $res = HTTP::Response->new(200, "OK");
    $res->content_type("text/html");
    $cgi = new CGParams($req->uri->query_form);
    $path = $req->uri->path;
    $method = $req->method;
    $cmdfd = undef;

    my ( $nowt, $pc1, $pcr ) = split("/", $path);
    my $handler = $dispatch{"/$pc1"};
    logw $req->uri;

# Single-thread for now; later either fork for everything, or hybrid fork-queue for sequential-sensitive (UI) operations.
#
#    if ($pid = fork) { $clientConn->close; undef $clientConn ; next }
#    unless (defined $pid) {
#      $res = HTTP::Response->new(500, "Fork failed on server");
#    }

    if (ref($handler) eq "CODE") {
        $handler->($res, $cgi, $req);
    }
    elsif (ref($handler) eq "HASH") {
        print "HASH\n";
        $res->content($$handler{response}($res, $cgi, $req))
    }
    else {
      $res = HTTP::Response->new(404, "Path or method not known $path $method");
      $res->header("Content-type" => "text/plain");
      $res->content(
        "Dunno $method $path yet\n".
        "\nTry one of:\n".
                qx{ perl -nle 'print "\$1  \$2\t\$3" if /m[\{=]\\^([^:]+):(\\S+).\\)[^#]*(#.*)?/' $0 }.
        "\n\n".Dumper($req))
    }
    if ($chunk_cmd) {
      $res->content(
        open($cmdfd, "($chunk_cmd ; date '+== end %clientConn') 2>&1 |") ? sub { $l = <$cmdfd> } : $!
      );
    }
    $res->header("XPID" => $$);
    $clientConn->send_response($res);
    close $cmdfd if $cmdfd;
    $clientConn->close if $clientComm; undef $clientConn;
  }
}

  sub handle_request {
      my $self = shift;
      my $cgi  = shift;

      my $path = $cgi->path_info();
      my ( $nowt, $pc1, $pcr ) = split("/", $path);
      my $handler = $dispatch{"/$pc1"};
      logw $cgi->url(-query=>1, -path_info=>1);

      if (ref($handler) eq "CODE") {
          print "HTTP/1.0 200 OK\r\n";
          $handler->($cgi, $pcr);
      }
      elsif (ref($handler) eq "HASH") {
          print "HTTP/1.0 $$handler{status}\r\n";
          $$handler{response}($cgi, $pcr);
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

  sub who_param_port {
    my $who = shift;
    my @bits = split(':', $who);
    my $swho = "-s $bits[-1]";
    $swho .= " -P $bits[-2]" if $bits[-2];
    $swho .= " -H $bits[-3]" if $bits[-3];
    return $swho
  }


  sub resp_root {
      my $res = shift;   # HTTP::Response
      my $cgi = shift;  # Queries
      my $who = $cgi->param('name');

      @server_sockets = $cgi->param('adb_server_socket') ||
                        $ENV['ADB_SERVER_SOCKET'] ||
                        ($cgi->param('android_adb_server_port') && "tcp:localhost:".$cgi->param('android_adb_server_port') ) ||
                        (map { /-L tcp:(?:localhost:)?(\d+)|-P (\d+)/ && "tcp:localhost:".( $1 || $2 ) }
                          grep { /\badb\b.*\bserver\b/ }
                          qx{ps -axopid,command});

      $res->add_content("<html><head><title>Devices</title></head><body>");

      for $ssocket ( @server_sockets ) {
        $::ssocket = $ssocket;
        next unless $ssocket;
        $cmd = "$::adb -L $ssocket devices";
        $res->add_content("<h1>$cmd</h1>");
        @devices = execute "$cmd 2>&1";
        push @devices, errorRunning($cmd) if ($? != 0);

      $res->add_content("<style><!--"
            ." table { border: solid 1px; border-collapse: collapse }"
            ." td { border:1px solid }"
            ." th { border:1px solid }"
            ." --></style>"
            ."<a href='/?lsusb=1'>USB PROBE</a> $ENV{OSTYPE}"
            ."<a href='/?historical=1'>HISTORICAL</a>"
            ."<table>"
            ."<tr><th colspan='2'>Devices</th><th>fs</th><th>Asset</th><th>model</th><th>brand</th><th>manufr</th><th>summary</th></tr>\n");
      %online = ();
      for (@devices) {
        if (/^(\S+)\s+device$/) {
          $who="$ssocket:$1";
            $online{$who} = 1;
        }
        else {
            $res->add_content("<tr><td colspan=9>$_</tr>\n") if $_ =~ /\S/;
        }
      }

      %lsusb = ();
      if ($cgi->param('lsusb')) {
        my $OSTYPE = `uname`;
        if (${OSTYPE} =~ /darwin/i) {
          $res->add_content("<tr>darwin</tr>");
          %lsusb = map { $_ => 1 } map {
              /^\s*Serial Number:\s*(\S+)/ && ($1) || ()
          } execute "system_profiler SPUSBDataType|grep Serial";
        }
        elsif (${OSTYPE} =~ /linux/i) {
          $res->add_content("<tr>linux</tr>");
          %lsusb = map { $_ => 1 } map {
                /^\s*iSerial\s+\d+\s+(\S+)/ && ($1) || ()
          } execute "lsusb -v 2>&1 | grep iSerial";
        }
      }

      %historical = ();
      if ($cgi->param('historical')) {
        %historical = map { $_ => 1 } ( @serial, keys %product );
      }

      $count = 0;
      %ids = map { $_ => 1 }
                    grep { /\w/  && $_ || () }
                    ( keys %online, keys %lsusb, keys %historical );
      @deviceids = sort { lc($a) cmp lc($b) }
                    keys %ids;
      for my $who ( @deviceids ) {
        my $swho = who_param_port($who);
        unless ($product{$who}) {
          my $summary = "";
          my @props = execute "$::adb $swho shell cat /system/build.prop /sdcard/asset";
          for (@props) {
            next if /^\s*#/;
            s/\s+$//;
            my @p = split("=", $_);
            $product{$who}{$p[0]}=$p[1] if $p[0] =~ /\S/;
            if ($p[0] =~ /ro.product/) {
              $summary .= " $p[1]" unless $summary =~ /$p[1]/;
            }
          }
          $product{$who}{SUMMARY} = $summary;
          $product{$who}{'sdcard.asset'} ||= "no sdcard.asset";
          saveRef($product{$who}, "product", $who);
        }
        unless ($product{$who}{'sdcard.asset'} !~ /sdcard/) {
          my @props = execute "$::adb $swho shell cat /sdcard/asset 2>/dev/null";
          for (@props) {
            next if /^\s*#/;
            s/\s+$//;
            my @p = split("=", $_);
            $product{$who}{$p[0]}=$p[1] if $p[0] =~ /\S/;
          }
          saveRef($product{$who}, "product", $who);
        }
        $product{$who}{'sdcard.asset'} ||= "no /sdcard/asset";
        my $href = "/console?view_only=$::view_only&device=$who#mode=".$flags{$who}{inputMode};
        $res->add_content( "<tr><td>"
            .($online{$who} ? (++$count) . "<td><a href='$href'>$who</a> device</td>" : "-<td>offline/absent: <a href='$href'>$who</a>")
            ."<td><a href=\"/browsedir?device=$who\">fs</a>"
            ."<td>$product{$who}{'sdcard.asset'}"
            ."<td>$product{$who}{'ro.product.model'}"
            ."<td>$product{$who}{'ro.product.brand'}"
            ."<td>$product{$who}{'ro.product.manufacturer'}</td>"
            ."<td>($product{$who}{SUMMARY})</td>");
      }
      $res->add_content("</table>");
      my $killServer = readFile("killserver.html");
      $killServer=~s/(\$(::)?\w+)/eval $1/ge;
      $res->add_content($killServer);
    }
      $res->add_content(" " . localtime()
                         ."<pre>" . join(", ", sort keys %dispatch) . "</pre>"
                         ."</html>");
  }

  sub resp_console {
      my $res = shift;
      my $cgi = shift;

      my $who = $cgi->param('device');
      my $screenflags = $cgi->param('screenflags');
      $::disabled = $cgi->param('view_only') ? 'disabled="disabled"' : "";

      $res->add_content("<html><head><title>$who</title></head>");
      my $console = readFile("console.html");
      $::product = $product{$who}{SUMMARY} || "unknown";
      $console=~s/(\$(::)?\w+)/eval $1/ge;
      $res->add_content($console);
  }

@TOUCH=(
  {
    down => sub {
      return '';
    },
    downup => sub {
      # my $self = $_[0];
      my $cmd = ($_[2] == $_[4] and $_[3] == $_[5])
        ? "input tap $_[2] $_[3]"
        : "input swipe $_[4] $_[5] $_[2] $_[3]";
      return $cmd;
    }
  },
  {
    locate => sub {
      return " sendevent /dev/input/event2 3 0 $_[2] ;".
             " sendevent /dev/input/event2 3 1 $_[3] ;";
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
## https://www.kernel.org/doc/Documentation/input/multi-touch-protocol.txt

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
      my $who = $_[0];
      my $xx = $getevent{$who}{ABS_MT_POSITION_X};
      my $yy = $getevent{$who}{ABS_MT_POSITION_Y};
      return " sendevent $$xx{DEV} $$xx{EVENT10} $$xx{CODE10} $_[1] ;". # x
             " sendevent $$yy{DEV} $$yy{EVENT10} $$yy{CODE10} $_[2] ;"; # y
    },
    push => sub {
      my $who = $_[0];
      my $wi = $getevent{$who}{ABS_MT_TOUCH_MAJOR};
      my $pr = $getevent{$who}{ABS_MT_PRESSURE};
      my $tr = $getevent{$who}{ABS_MT_TRACKING_ID};
      my $c = $_[1] ? 50 : 0;
      return " sendevent $$pr{DEV} $$pr{EVENT10} $$pr{CODE10} $c ;". # pressure
             " sendevent $$wi{DEV} $$wi{EVENT10} $$wi{CODE10} 5 ;". # width
             " sendevent $$tr{DEV} $$tr{EVENT10} $$tr{CODE10} 0 ;"; # finger id?
    },
    sync => sub {
      my $who = $_[1];
      my $tr = $getevent{$who}{ABS_MT_TRACKING_ID};
      return " sendevent $$tr{DEV} 0 0 0 ;";
    },
    end => sub {
      my $who = $_[1];
      my $tr = $getevent{$who}{ABS_MT_TRACKING_ID};
      return " sendevent $$tr{DEV} $$tr{EVENT10} $$tr{CODE10} ".0xffffffff." ;"
            ." sendevent $$tr{DEV} 0 0 0 ;";
    },
    down => sub {
      my $self = $_[0];
      my $who = $_[1];
      my $w = $_[4];
      my $h = $_[5];
      my $x = int($_[2]*$getevent{$who}{ABS_MT_POSITION_X}{max}/$w);
      my $y = int($_[3]*$getevent{$who}{ABS_MT_POSITION_Y}{max}/$h);
      return &{$self->{locate}}($who,$x,$y)
            .&{$self->{push}}($who,1)
            .&{$self->{sync}};
    },
    downup => sub {
      my $self = $_[0];
      my $who = $_[1];
      my $w = $_[6];
      my $h = $_[7];
      my $x1 = int($_[2]*$getevent{$who}{ABS_MT_POSITION_X}{max}/$w);
      my $y1 = int($_[3]*$getevent{$who}{ABS_MT_POSITION_Y}{max}/$h);
      my $x2 = int($_[4]/$w*1024);
      my $y2 = int($_[5]/$h*1024);
      return &{$self->{locate}}($who,$x1,$y1)
            .&{$self->{push}}($who, 1)
            .&{$self->{sync}}
            .&{$self->{end}};
    }
  },
  {
    down => sub {
      return '';
    },
    downup => sub {
      # my $self = $_[0];
      my $who = $_[1];
      my $cmd = ($_[2] == $_[4] and $_[3] == $_[5])
        ? "device.touch($_[2],$_[3],MonkeyDevice.DOWN_AND_UP)"
        : "device.drag(($_[4],$_[5]), ($_[2],$_[3]))";
          open MONKEY, ">$who.touch.monkey";
          print MONKEY <<END;
from com.android.monkeyrunner import MonkeyRunner, MonkeyDevice
device = MonkeyRunner.waitForConnection(10, '$who')
result = $cmd
END
          close MONKEY;
      return "monkeyrunner $who.touch.monkey";
    }
  },
);

  sub resp_touch {
      my $res = shift;
      my $cgi  = shift;   # CGI.pm object
      return if !ref $cgi;

      my $who = $cgi->param('device');
      my $swho = who_param_port($who);

      my $coords = $cgi->param('coords');
      my $up = $cgi->param('swipe');
      my $down = $cgi->param('down');
      my $rot = $cgi->param('rot');
      my $img = $cgi->param('img');

      $res->add_content($who);

      my $shell = "$swho shell ";

    warn "touch mode = " . $flags{$who}{inputMode};
      $flags{$who}{inputMode} ||= 0;
      $touch = $TOUCH[$flags{$who}{inputMode}];
      if ("$down$up$img" =~ /^\?(\d+),(\d+)\?(\d+),(\d+)$/) {
        my $cmd = $touch->{down}($touch, $who, $1, $2, $3, $4);
        $res->add_content(runAdb "$swho $shell \"$cmd\"") if $cmd;
        return;
      }
      if ("$down$up$img" =~ /^\?(\d+),(\d+)\?(\d+),(\d+)\?(\d+),(\d+)$/) {
        my $cmd = $touch->{downup}($touch, $who, $3, $4, $1, $2, $5, $6);
        if ($cmd) {
          if ($cmd !~ /monkeyrunner/) {
            $res->add_content(runAdb "$swho $shell \"$cmd\"");
          } else {
            $res->add_content(runCmd "$cmd");
          }
        }
        return;
      }
  }

  sub resp_settings {
      my $res = shift;
      my $cgi  = shift;   # CGI.pm object

      my $who = $cgi->param('device');
      my $swho = who_param_port($who);

      $res->content(
            $cgi->start_html("$who")
            ."Flags...<pre>"
            .::Ref($flags{$who}, "\n ", ". ")
            ."</pre>"
            ."getevent...<pre>"
            .::Ref($getevent{$who}, "\n ", ". ")
            ."</pre>");
  }

  sub resp_keyboard {
      my $res = shift;
      my $cgi  = shift;   # CGI.pm object

      my $who = $cgi->param('device');
      my $swho = who_param_port($who);

      my $key = $cgi->param('key');
      my $down = $cgi->param('down');

      $res->add_content(
            $cgi->start_html("$who")
      );

      if ($key) {
        my $shell = "$swho shell ";
        my $k = $getevent{$who}{$key};
        $res->add_content(runAdb "$swho $shell \"sendevent $$k{DEV} $$k{EVENT10} $$k{CODE10} $down; sendevent $$k{DEV} 0 0 0\"");
        return;
      }
      else {
        $res->add_content( <<END
<script type='text/javascript'>
  function key(b, k, d) {
    window.frames['stdout'].location='/keyboard?device=$who&key='+k+'&down='+d
    if (d==1) {
      b.style.backgroundColor='red';
      b.style.color='white';
    }
    else {
      b.style.backgroundColor='white';
      b.style.color='black';
    }
  }
  function powerUp() {
    key(document.getElementById('KEY_POWER'), 'KEY_POWER', 0);
  }
</script>
<iframe height=20 width='100%' id=stdout></iframe><br>
Slide off key to hold<br>
END
);
        for $k (sort { length $a <=> length $b || $a cmp $b } grep { /KEY_/ } keys %{$getevent{$who}}) {
          my $name = $k; $name =~ s/KEY_//;
          if ($k eq 'KEY_POWER') {
            # Prevent inadvertent power off! :D
            $res->add_content( "<input type='button' value='$name' id='$k' "
                  ."onmouseup=\"key(this, '$k', 1); setTimeout(powerUp, 100); \">");
          }
          else {
            $res->add_content( "<input type='button' value='$name' "
                  ."onmousedown=\"key(this, '$k', 1)\" "
                  ."onmouseup=\"key(this, '$k', 0)\">");
          }
        }
      }
  }

  sub resp_reboot {
      my $res = shift;
      my $cgi  = shift;   # CGI.pm object

      my $who = $cgi->param('device');
      my $swho = who_param_port($who);

      $res->add_content(
            $cgi->start_html("$who"));

      my $shell = "$swho";
      $res->add_content(runAdb "$swho $shell reboot");
  }

  sub resp_text {
      my $res = shift;
      my $cgi  = shift;   # CGI.pm object

      my $who = $cgi->param('device');
      my $swho = who_param_port($who);

      my $text = $cgi->param('text');
      my $key = $cgi->param('key');

      $res->add_content(
            $cgi->start_html("$who"));

      my $shell = "$swho shell ";

      if ($text eq ' ') {
        $text = undef; $key = 62;
      }
      if ($text) {
          $res->add_content(runAdb "$swho $shell input text $text");
          return;
      }
      if ($key) {
          $res->add_content(runAdb "$swho $shell input keyevent $key");
          return;
      }
  }

  sub resp_browsedir {
      my $res = shift;
      my $cgi  = shift;   # CGI.pm object

      my $who = $cgi->param('device');
      my $swho = who_param_port($who);
      my $path = $cgi->param('path') || "/";
      my $su = $cgi->param('su') ? "su -c " : "";

      my $cmd = "$::adb $swho shell $su ls -l -a $path";
      warn localtime().": $$: $cmd\n";
      my @listing = execute $cmd;
      my $listerr = $?;
      my $listing = "";
      for my $entry ( @listing ) {
        if ($entry =~ /^([ld].*?)(\S+)\s*$/ ) {
          my $details = $1;
          my $name = $2;
          my $link = $name;
          $link = "$path/$link" unless $link =~ /^\//;
          $listing .= "$details <a href='/browsedir?device=$who&path=$link&su=1'>".($su ? "" : "+su</a> <a href='/browsedir?device=$who&path=$link'>")."$name</a>\n";
        } elsif ($entry =~ /^(-.*?)(\S+)\s*$/ ) {
          my $details = $1;
          my $name = $2;
          my $link = $name;
          $link = "$path/$link" unless $link =~ /^\//;
          my $leaf = $name;
          $leaf =~ s{/(\S+/)*}{}g;
          $listing .= "$details <a href='/pullfile/$leaf?device=$who&path=$link&su=1'>".($su?"":"+su</a> <a href='/pullfile/$leaf?device=$who&path=$link'>")."$name</a>\n";
        } else {
          $listing .= "$entry";
        }
      }
      if ($listing =~ /opendir failed|Permission denied/i) {
        $listing .= "<a href='/browsedir?device=$who&path=$path&su=1'>Try with su?</a>";
      }
      if ($listerr != 0) {
        $listing .= errorRunning($cmd);
      }
      $res->add_content(
            $cgi->start_html("$who $path").
            "<h1>$su$who $path</h1>".
            "<pre>$listing</pre>".
            $cgi->end_html);
  }

  sub resp_pullfile {
      my $res = shift;
      my $cgi  = shift;   # CGI.pm object

      my $who = $cgi->param('device');
      my $swho = who_param_port($who);
      my $path = $cgi->param('path') || "/";

      my $cmd = "$::adb $swho shell ls -l -a $path";
      warn localtime().": $$: $cmd\n";
      my @out = execute $cmd;
      if ($? != 0) {
        $res->add_content(errorRunning($cmd). $out);
        return;
      }
      if ($#out != 0 || $out[0] !~ /^-/) {
        $res->add_content("$#out Not a file...<pre>".join("\n",@out)."</pre>");
        return;
      }
      my $pull = "/tmp/pull.$$";
      $cmd = $cgi->param('su')
             ? "$::adb $swho shell su -c cat $path > $pull"
             : "$::adb $swho pull $path $pull";
      unlink $path;
      warn localtime().": $$: $cmd\n";
      my $out = execute $cmd;
      if ($? != 0) {
        $res->add_content( errorRunning($cmd). $out);
        return;
      }
      my $ext = $path; $ext =~ s/.*\.([^\.]+)$/$1/;
      if (-T $pull) {
        if ($pull =~ /^<[!?]/) {
          $res->content_type('application/xml' )
        } else {
          $res->content_type('text/plain' )
        }
      }
      else {
        $res->content_type('image/$ext' )
      }
      $res->content(readFile($pull))
  }

  sub resp_screenshot {
      my $res = shift;
      my $cgi = shift;   # CGI.pm object

      my $who = $cgi->param('device');
      my $swho = who_param_port($who);
      my $screenflags = $cgi->param('screenflags');

      my $image;
      my $cmd;
      if ($screenflags =~ /,pull,/) {
          $image = execute($cmd = "adb $swho shell screencap /sdcard/$who.png") && 
                    execute("adb $swho pull /sdcard/$who.png /tmp/") && 
                    readFile("/tmp/$who.png");
      } else {
        my $cmd = $screenflags =~ /,piped,/
            ? "export LOCALE=C; export LC_ALL=C; echo screencap -p | $TIMELIMIT $::adb $swho  shell"
            : "$TIMELIMIT $::adb $swho shell screencap -p";
        warn localtime().": $$: $cmd\n";
        $image = execute $cmd;
        $image && $image =~ s/^\* daemon not running\. starting it now on port \d+ \*\s+\* daemon started successfully \*\s+//;
      }
      $first_err = $!;
      if ($? != 0 || $image =~ /^screencap: permission denied/) {
        if (1) {
          # Experimental... monkeyrunner as fallback.
          warn localtime().": $$: trying MONKEY $who\n";
          open MONKEY, ">$who.monkey";
          print MONKEY <<END;
from com.android.monkeyrunner import MonkeyRunner, MonkeyDevice
device = MonkeyRunner.waitForConnection(10, '$who')
result = device.takeSnapshot()
result.writeToFile('$who.png','png')
END
          close MONKEY;
          execute "monkeyrunner $who.monkey";
          $image = readFile("$who.png");
          $cmd .= " ... and monkeyrunner";
        }
      } 
      if ($? != 0) {
        $res->code(503);
        $res->content(errorRunning($cmd). $out);
        return;
      }
      $image =~ /^\211PNG\r\n\032\n/ || $image =~ s/\r\n/\n/g unless $screenflags =~ /,nomagic,/;
      $res->content_type('image/png');
      $res->content($image);
  }

  sub resp_quitThis {
    exit 0;
  }

  sub resp_killServer {
      my $res = shift;
      my $cgi  = shift;   # CGI.pm object

      $res->add_content(
            $cgi->start_html("$who"));
      my $socket = $cgi->param('ssocket');
      $res->add_content(runAdb "-L $socket kill-server");
  }

  sub decodeGetEvent {
    my @data = qx($_[0]);
    my $event = {};
    s/\015//g for @data;
    while ($_ = shift @data) {
      logg "decode $_";
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
        logg "decode $_";
        while (s/^\s+(\w+)\s+\((\w+)\)://) {
          my $id = $2;
          my @values = ();
          do {
            if (/(\w+)\s+:\s+(.*)/) {
              my $name = $1;
              my $pairs = $2;
              unshift @values, { NAME => $name, EVENT => $id, EVENT10 => hex($id), split(/,?\s+/, $pairs) };
            }
            else {
              unshift @values, map { { NAME => $_, EVENT => $id, EVENT10 => hex($id) } } split(" ", $_);
            }
            $_ = shift @data;
            logg "decode $_";
          } while (!/:\s*$/ && !/^\s+\w+\s+\(\w+\):/ && $_);
          $$event{"$device:$name"} = \@values;
        }
      }
    }
    return $event;
  }

  sub resp_setInputMode {
      my $res = shift;
      my $cgi  = shift;   # CGI.pm object
      return if !ref $cgi;

      my $who = $cgi->param('device');
      my $swho = who_param_port($who);
      my $mode = $cgi->param('mode');

      $res->add_content(
            $cgi->start_html("$who"));

      logg "mode=$mode";

      if ($mode) {
        my $cmdw = decodeGetEvent("$::adb $swho shell getevent -lp");
        my $cmdn = decodeGetEvent("$::adb $swho shell getevent -p");
        my %event;
        for my $k ( keys %$cmdw ) {
          my ( $dev, $desc ) = split(/:/, $k);
          my $w = $$cmdw{$k};
          my $n = $$cmdn{$k};
          for my $l (0..((scalar @$w)-1)) {
            my $name = $$w[$l]{NAME};
            my $h = $$w[$l];
            $$h{CODE} = $$n[$l]{NAME};
            $$h{CODE10} = hex($$n[$l]{NAME});
            $$h{DEV} = $dev;
            $$h{DESC} = $desc;
            $event{$name} = $h;
          }
        }
        saveRef(\%event, "getevent", $who);
        $getevent{$who} = \%event;
      }

    $flags{$who}{inputMode}=$mode;
    saveRef($flags{$who}, "flags", $who);
  }

  sub resp_adbCmd {
      my $res = shift;
      my $cgi  = shift;   # CGI.pm object

      my $who = $cgi->param('device');
      my $swho = who_param_port($who);
      my $cmd = $cgi->param('cmd');

      $res->add_content(
            $cgi->start_html("$who"));
      $res->add_content(runAdb "$swho shell $cmd") if $cmd !~ /^\s*$/;
  }
}

$MyWebServer::getevent{''}={};
$MyWebServer::flags{''}={};
$MyWebServer::product{''}={};
opendir DIR, "$0.devices";
for (readdir DIR) {
  my ( $who, $ext ) = split(/\./);
  if ( $ext eq 'getevent' ) {
    $MyWebServer::getevent{$who}=MyWebServer::loadRef($ext, $who);
  }
  elsif ( $ext eq 'flags' ) {
    $MyWebServer::flags{$who}=MyWebServer::loadRef($ext, $who);
  }
  elsif ( $ext eq 'product' ) {
    $MyWebServer::product{$who}=MyWebServer::loadRef($ext, $who);
  }
  else {
    warn "Unknown config file $_\n";
  }
}
closedir DH;

print ::Ref(\%MyWebServer::getevent, "\n ", ". "), "\n";
print ::Ref(\%MyWebServer::flags, "\n ", ". "), "\n";
print ::Ref(\%MyWebServer::product, "\n ", ". "), "\n";

MyWebServer::NEW_SERVER()

__END__

# start the server on $port
if ($foreground) {
  print "Ctrl-C to interrupt the server\n";
  MyWebServer->new($port)->run();
}
else {
  $pidFile = "$0.pid";
  if (-f $pidFile and open PID, $pidFile ) {
    $pid = <PID>;
    close PID;
    @proc = grep { /^\s*$pid\b/ } ( qx/ps ax/ );
    print "Found old $pid - ".join("\n", @proc)."\n";
    if ($proc[0] =~ /CgiAdbRemote/) {
      print "Looks like me. Attempting to kill old me... $proc\n";
      system "kill $pid";
      sleep 1;
    }
    else {
      print "Doesn't look like me. You kill it if you want.\n";
    }
  }
  unlink $pidFile;
  my $pid = MyWebServer->new($port)->background();
  print "Use 'kill $pid' to stop server running on port $port.\n";
  open PID, ">$pidFile";
  print PID $pid;
  close PID;
}

