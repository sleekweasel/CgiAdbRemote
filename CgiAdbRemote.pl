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
      '/setInputMode' => \&resp_setInputMode,
      '/adbCmd' => \&resp_adbCmd,
      #'/touch' => { status => "204 No content", response => \&resp_touch },
      # ...
  );

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
      print <<END;
<script type="text/javascript">
function url(rest) {
    here = window.location.href.split("/");
    here.pop();
    here.push(rest);
    return here.join("/");
}
function killServer() {
    if (!confirm("Are you really sure you want to kill ADB?")) {
      alert("User uncertain. Aborted.");
    }
    else {
      if (confirm("Are any tests running? (OK=YES)")) {
        alert("Tests were running, Aborted.");
      }
      else {
        window.frames["stdout"].location=url("killServer");
      }
    }
}
</script>
<input type='button' value="kill-server" onclick="killServer()">
<iframe height=50 width=500 id=stdout name=stdout></iframe><br>
<hr>
<a href='https://github.com/sleekweasel/CgiAdbRemote'>CgiAdbRemote</a> is on github.
END
      print " " . localtime();
      print $cgi->end_html;
  }

  sub logg {
    my $thing = shift;
    my $log = localtime() . ": $$: $thing\n";
    warn $log;
    print $log;
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
      print <<END;
<script type="text/javascript">
document.dragstart = function() { return false; }
function doTouch() {
    document.refreshScreenAfter = $::touchdelay;
    document.refreshNum = 20;
}
doTouch();
function url(rest) {
    here = window.location.href.split("/");
    here.pop();
    here.push(rest);
    return here.join("/");
}
function getScale() {
  return document.autoScale;
}
function mouseDown(i, e) {
    document.lastDown = e;

    xoff = i.x - window.pageXOffset;
    yoff = i.y - window.pageYOffset;

    s = getScale();
    x1 = Math.round((e.clientX-xoff)/s);
    y1 = Math.round((e.clientY-yoff)/s);

    touch = "touch?device=$who" +
          "&down=?" + x1 + "," + y1 +
          "&swipe=?" + x2 + "," + y2;
    window.frames["stdout"].location=url(touch);
    window.frames["stdout"].location=url(
        "touch?device=$who" +
        "&down=?" + x1 + "," + y1);
    doTouch();
    return true;
}
function mouseUp(i, e) {
    f=document.lastDown;

    xoff = i.x - window.pageXOffset;
    yoff = i.y - window.pageYOffset;

    s = getScale();
    x1 = Math.round((f.clientX-xoff)/s);
    y1 = Math.round((f.clientY-yoff)/s);

    x2 = Math.round((e.x-xoff)/s);
    y2 = Math.round((e.y-yoff)/s);

    touch = "touch?device=$who" +
          "&down=?" + x1 + "," + y1 +
          "&swipe=?" + x2 + "," + y2;
    window.frames["stdout"].location=url(touch);

    doTouch();
    return true;
}
function keyPress(i, e) {
// Try to handle keypress and keydown together: assume charCode=0 if press.
    if (e.keyCode == 8) {
      keyEvent(i, 67);
    }
    else if (e.charCode == 0) {
      return;
    }
    else if (e.charCode == 32) {
      keyEvent(i, 62);
    }
    else {
      window.frames["stdout"].location=url(
        "touch?device=$who&text="+String.fromCharCode(e.charCode));
    }
    doTouch();
    return true;
}
function setInputMode(mode) {
    window.frames["stdout"].location=url("setInputMode?device=$who&mode="+mode);
    doTouch();
    return true;
}
function keyEvent(i, e) {
    window.frames["stdout"].location=url("touch?device=$who&key="+e);
    doTouch();
    return true;
}
function onAdb() {
    cmd = document.getElementById("adbcmd").value;
    document.getElementById("adbcmd").value = '';
    window.frames["stdout"].location=url("adbCmd?device=$who&cmd="+cmd);
    return true;
}
function qParam(k, d) {
  qPairs = window.location.hash.split("#");
  while (qPairs.length) {
    pair = qPairs.shift();
    kv = pair.split("=");
    if (kv[0] == k) return kv[1];
  }
  return d;
}
function qHash() {
  qPairs = window.location.hash.split("#");
  hash = {};
  while (qPairs.length) {
    pair = qPairs.shift();
    kv = pair.split("=");
    hash[kv[0]] = kv[1];
  }
  return hash;
}
function updateHash(k, v) {
  hash = qHash();
  hash[k]=v;
  s = '';
  for (key in hash) {
    if (key!==undefined && key != 'undefined' && hash[key]!==undefined && hash[key] != 'undefined' ) {
      s += '#' + key + '=' + hash[key];
    }
  }
  window.location.hash = s;
}
function maybeRotate(image) {
    image = document.getElementById("screen");
    w = (image.width);
    h = (image.height);
    deg = qParam('deg', '0');
    autoScale = qParam("autoScale", "false");
    document.autoScale = 1;
    if (autoScale == "true") {
      hh = window.innerHeight;
      ww = window.innerWidth;
      switch (deg) {
        case '90': case '270':
          t = hh; hh = ww; ww = t;
      }
      document.autoScale = Math.min(ww/w, hh/h);
    }
    s = getScale();
    wmh = (w-h);
    hmw = (h-w);
    switch (deg) {
    case "0":
        transform =
            ''
            + 'scale(' + s + ') '
            + 'translate('+Math.round(w*.5/-s)+'px,'+Math.round(h*.5/-s)+'px) '
            + 'translate('+Math.round(w/2)+'px,'+Math.round(h/2)+'px) '
            ;
        break;
    case "90":
        transform =
            ''
            + 'rotate(90deg)'
            + 'scale(' + s + ') '
            + 'translate('+Math.round(-h*.5/s)+'px,'+Math.round(w*.5/s)+'px) '
            + 'translate('+Math.round(w/2)+'px,'+Math.round(-h/2)+'px) '
            ;
        break;
    case "180":
        transform =
            ''
            + 'scale(' + s + ') '
            + 'rotate(180deg)'
            + 'translate('+Math.round(w*.5/s)+'px,'+Math.round(h*.5/s)+'px) '
            + 'translate('+Math.round(-w/2)+'px,'+Math.round(-h/2)+'px) '
            ;
        break;
    case "270":
        transform =
            ''
            + 'scale(' + s + ') '
            + 'rotate(270deg) '
            + 'translate('+Math.round(h*.5/s)+'px,'+Math.round(-w*.5/s)+'px) '
            + 'translate('+Math.round(-w/2)+'px,'+Math.round(h/2)+'px) '
            ;
        break;
    }
    image.style.webkitTransform = transform;
    b = document.getElementById("d"+deg+'deg');
    if (b != null) {
        b.style.backgroundColor='red';
        b.style.color='white';
    }
}
function everyHalfSecond() {
  if (document.refreshNum != 0) {
    refresh = "Auto refresh in: " + (document.refreshScreenAfter/2) + "s"
    + " (" + document.refreshNum + " more)";
  }
  else {
    refresh = "Auto refresh: paused until user activity";
  }
  document.getElementById('refreshAfter').innerHTML= refresh + ", scale "+getScale();
  if (document.refreshScreenAfter > 0 && document.refreshNum != 0) {
    document.refreshScreenAfter = document.refreshScreenAfter - 1;
    if (document.refreshScreenAfter <= 0) {
      document.refreshNum = document.refreshNum - 1;
      screen = document.getElementById("screen");
      screen.src = screen.src.split("#")[0] + "#" + new Date();
    }
  }
}
function onLoadScreen(image) {
  maybeRotate(image);
  document.refreshScreenAfter = $::autodelay;
}
function logResponse(doc) {
    if (doc.logger != null) {
        logg = doc.logger.frameElement.contentDocument;
        logg.body.innerHTML = logg.body.innerHTML +
            "<pre>" +
            doc.stdout.frameElement.contentDocument.body.innerHTML +
            "</pre>";
        logg.body.scrollTop = logg.height;
    }
}

setInterval(everyHalfSecond, 500);
</script>
<a href='/'>Adb devices</a>
<h1 style="color: red">$::banner</h1>
<iframe height=20 width='100%' id=stdout name=stdout onload="logResponse(document)"></iframe><br>
<iframe height=100 width='100%' id=logger name=logger></iframe><br>

<table border=1>
  <td>
    <input type="button" value="home" onclick="keyEvent(this, 3)">
    <input type="button" value="menu" onclick="keyEvent(this, 82)">
    <input type="button" value="back" onclick="keyEvent(this, 4)">
    <input type="button" value="power" onclick="keyEvent(this, 26)">
    <input type="text" id="textEntry" value="Type here" onkeypress="keyPress(this, event)" onkeydown="keyPress(this, event)">
    Autoscale: <input type="checkbox" id="autoScale" value="autoScale" onclick="updateHash('autoScale', this.checked); maybeRotate(document.getElementById('screen'))">
  <td rowspan=2>
    <table border=1>
      <tr>
        <th colspan=2>
          <input type="button" value="refresh 0deg" id='d0deg' onclick="updateHash('deg',0); window.location.reload()">
        </th>
      </tr>
      <tr>
        <th>
          <input type="button" value="refresh 270deg" id='d270deg' onclick="updateHash('deg',270); window.location.reload()">
        </th>
        <th>
          <input type="button" value="refresh 90deg" id='d90deg' onclick="updateHash('deg',90); window.location.reload()">
        </th>
      </tr>
      <tr>
        <th colspan=2>
          <input type="button" value="refresh 180deg" id='d180deg' onclick="updateHash('deg',180); window.location.reload()">
        </th>
      </tr>
    </table>
  <td rowspan=2>
    <table border=1>
     <tr><td><input type="button" value="TapSwipe" onclick="setInputMode(0)">
     <tr><td>Experimental: <input type="button" value="Older sendevent" onclick="setInputMode(1)">
     <tr><td>Experimental: <input type="button" value="Newer sendevent" onclick="setInputMode(2)">
    </table>
  </tr>
  <tr>
    <td>
      <input type='button' value='adb shell' onclick="onAdb()">
      <input type="text" id="adbcmd">
      <br>
      <span id="refreshAfter"></span>
      <br>If the device's clock shows the wrong time and it's unresponsive, the
          screen is probably powered off.
    </td>
  </tr>
</table>
<br>
<img id="screen" style="border:5px dotted grey" draggable="false"
  onmousedown="mouseDown(this, event)"
  onmouseup="mouseUp(this,event)"
  onload="onLoadScreen(this)"
  src="/screenshot?device=$who">
<script type="text/javascript">
  document.getElementById("textEntry").focus();
  document.getElementById("autoScale").checked = (qParam("autoScale", "false") == 'true');
</script>
<hr>
<a href='https://github.com/sleekweasel/CgiAdbRemote'>CgiAdbRemote</a> is on github.
END
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
      my $text = $cgi->param('text');
      my $key = $cgi->param('key');

      print $cgi->header,
            $cgi->start_html("$who");

      my $shell = "-s $who shell ";

      if ($coords =~ /\?(\d+),(\d+)$/) {
          runAdb "$shell input tap $1 $2";
          return;
      }
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
      # http://blog.softteco.com/2011/03/android-low-level-shell-click-on-screen.html
      $touch = $TOUCH[$q{inputMode}];
      if ("$down$up" =~ /^\?(\d+),(\d+)$/) {
        my $cmd = $touch->{down}($touch, $1, $2);
        runAdb "$shell \"$cmd\"" if $cmd;
        return;
      }
      if ("$down$up" =~ /^\?(\d+),(\d+)\?(\d+),(\d+)$/) {
        my $cmd = $touch->{downup}($touch, $1, $2, $3, $4);
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
        : "input swipe $_[1] $_[2] $_[3] $_[4]";
      return $cmd;
    }
  },
  {
    locate => sub {
warn "$_[1], $_[2]";
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
    locate => sub {
warn "$_[1], $_[2]";
      return " sendevent /dev/input/event0 3 53 $_[1] ;".
             " sendevent /dev/input/event0 3 54 $_[2] ;";
    },
    push => sub {
      my $c = $_[0] ? 6 : 8;
      return " sendevent /dev/input/event0 3 58 59 ;".
             " sendevent /dev/input/event0 3 48 $c ;". # down=6 up=7 ... 8?
             " sendevent /dev/input/event0 3 57 0 ;".
             " sendevent /dev/input/event0 0 2 0 ;".
             " sendevent /dev/input/event0 0 0 0 ;";
    },
    down => sub {
      my $self = $_[0];
      return &{$self->{locate}}.&{$self->{push}}(1);
    },
    downup => sub {
      my $self = $_[0];
      return &{$self->{locate}}.&{$self->{push}}(0);
    }
  }
);

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

  sub resp_setInputMode {
      my $cgi  = shift;   # CGI.pm object
      return if !ref $cgi;
      
      my $who = $cgi->param('device');
      my $mode = $cgi->param('mode');

      my %q;
      if (-f "$0.devices/$who") {
        for (qx"cat $0.devices/$who") {
          chomp;
          @q = split(/:/,$_,2);
          $q{$q[0]}=$q[1] if $q[0];
        }
      }

      $q{inputMode}=$mode;

      print $cgi->header,
            $cgi->start_html("$who");
      logg "mode=$mode";

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
