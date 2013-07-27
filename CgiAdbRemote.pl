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

  sub runCmd {
    my $cmd = shift;
    my $log = localtime() . ": $$: $cmd\n";
    warn $log;
    print $log;
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
function url(rest) {
    here = window.location.href.split("/");
    here.pop();
    here.push(rest);
    return here.join("/");
}
function mouseDown(i, e) {
    document.lastDown = e;

    xoff = i.x - window.pageXOffset;
    yoff = i.y - window.pageYOffset;

    x1 = (e.clientX-xoff);
    y1 = (e.clientY-yoff);

    window.frames["stdout"].location=url(
        "touch?device=$who" +
        "&down=?" + x1 + "," + y1);
    return true;
}
function mouseUp(i, e) {
    f=document.lastDown;

    xoff = i.x - window.pageXOffset;
    yoff = i.y - window.pageYOffset;

    x1 = (f.clientX-xoff);
    y1 = (f.clientY-yoff);

    x2 = (e.x-xoff);
    y2 = (e.y-yoff);

    window.frames["stdout"].location=url(
        "touch?device=$who" +
        "&down=?" + x1 + "," + y1 +
        "&swipe=?" + x2 + "," + y2);

    document.refreshScreenAfter = $::touchdelay;
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
    document.refreshScreenAfter = $::touchdelay;
    return true;
}
function keyEvent(i, e) {
    window.frames["stdout"].location=url("touch?device=$who&key="+e);
    document.refreshScreenAfter = $::touchdelay;
    return true;
}
function onAdb() {
    cmd = document.getElementById("adbcmd").value;
    document.getElementById("adbcmd").value = '';
    window.frames["stdout"].location=url("adbCmd?device=$who&cmd="+cmd);
    return true;
}
function maybeRotate(image) {
    image = document.getElementById("screen");
    w = (image.width/2) + 'px';
    h = (image.height/2) + 'px';
    w2 = (image.width) + 'px';
    h2 = (image.height) + 'px';
    switch (window.location.hash) {
    case "#90deg":
        image.style.webkitTransform='translate(-'+w+',-'+h+') ' +
                                'rotate(90deg) ' +
                                'translate('+w+',-'+h+')'; 
        break;
    case "#180deg":
        image.style.webkitTransform= 'rotate(180deg)'; 
        break;
    case "#270deg":
        image.style.webkitTransform='translate(-'+w+',-'+h+') ' +
                                'rotate(270deg) ' +
                                'translate(-'+w+','+h+')'; 
        break;
    }
}
function everyHalfSecond() {
  document.getElementById('refreshAfter').innerHTML="Auto refresh in: " + (document.refreshScreenAfter/2) + "s";
  if (document.refreshScreenAfter > 0) {
    document.refreshScreenAfter = document.refreshScreenAfter - 1;
    if (document.refreshScreenAfter <= 0) {
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
<h1 style="color: red">$::banner</h1>
<iframe height=20 width='100%' id=stdout name=stdout onload="logResponse(document)"></iframe><br>
<iframe height=100 width='100%' id=logger name=logger></iframe><br>
<table><td>
<input type="button" value="home" onclick="keyEvent(this, 3)">
<input type="button" value="menu" onclick="keyEvent(this, 82)">
<input type="button" value="back" onclick="keyEvent(this, 4)">
<input type="button" value="power" onclick="keyEvent(this, 26)">
<input type="text" id="textEntry" value="Type here" onkeypress="keyPress(this, event)" onkeydown="keyPress(this, event)">
<td rowspan=2>
<table><th colspan=2>
<input type="button" value="refresh 0deg" onclick="window.location='$myself#0deg'; window.location.reload()">
</th></tr><tr><th>
<input type="button" value="refresh 270deg" onclick="window.location='$myself#270deg'; window.location.reload()">
</th><th>
<input type="button" value="refresh 90deg" onclick="window.location='$myself#90deg'; window.location.reload()">
</th></tr><tr><th colspan=2>
</td>
<input type="button" value="refresh 180deg" onclick="window.location='$myself#180deg'; window.location.reload()">
</table>
</tr><td>
<input type='button' value='adb shell' onclick="onAdb()"><input type="text" id="adbcmd"><br>
<span id="refreshAfter"></span>
<br>
If the device's clock shows the wrong time and it's unresponsive, the screen is
probably powered off.
</table>

<br>
<img id="screen" style="border:5px dotted grey" draggable="false"
  onmousedown="mouseDown(this, event)"
  onmouseup="mouseUp(this,event)"
  onload="onLoadScreen(this)"
  src="/screenshot?device=$who">
<script type="text/javascript">
  document.getElementById("textEntry").focus();
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
 
      my $coords = $cgi->param('coords');
      my $up = $cgi->param('swipe');
      my $down = $cgi->param('down');
      my $text = $cgi->param('text');
      my $key = $cgi->param('key');

      print $cgi->header,
            $cgi->start_html("$who");

# http://blog.softteco.com/2011/03/android-low-level-shell-click-on-screen.html
      if ($coords =~ /\?(\d+),(\d+)$/) {
          runAdb "-s $who shell input tap $1 $2";
          return;
      }
      if ($text eq ' ') {
        $text = undef; $key = 62;
      }
      if ($text) {
          runAdb "-s $who shell input text $text";
          return;
      }
      if ($key) {
          runAdb "-s $who shell input keyevent $key";
          return;
      }
      if ("$down$up" =~ /\?(\d+),(\d+)\?(\d+),(\d+)$/) {
          my $cmd = ($1 == $3 and $2 == $4)
            ? "-s $who shell input tap $1 $2"
            : "-s $who shell input swipe $1 $2 $3 $4";
          runAdb $cmd;
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
        print $cgi->headers, errorRunning($cmd);
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
