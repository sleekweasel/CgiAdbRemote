#!/usr/bin/perl -s
#
#  Options:
die "Use -port=01, not -port 1\n" if $port eq '1';
die "Use -banner=Something, not -banner Something\n" if $banner eq '1';

$port ||= 8080;
$foreground ||= 0;
$banner ||= "WARNING: TESTS MAY BE RUNNING";
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
      #'/touch' => { status => "204 No content", response => \&resp_touch },
      # ...
  );

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

  sub resp_root {
      my $cgi  = shift;   # CGI.pm object
      return if !ref $cgi;
      
      my $who = $cgi->param('name');
      $cmd="adb devices";
      @devices = `$cmd`;
      
      print $cgi->header,
            $cgi->start_html("Devices");
      my $myself = $cgi->self_url;
      print $cgi->h1($cmd . localtime());
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
END
      print $cgi->end_html;
  }

  sub runCmd {
    my $cmd = shift;
    my $log = localtime() . ": $cmd\n";
    warn $log;
    print $log;
    print `$cmd`;
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

    document.refreshScreenAfter = 3;
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
    document.refreshScreenAfter = 3;
    return true;
}
function keyEvent(i, e) {
    window.frames["stdout"].location=url("touch?device=$who&key="+e);
    document.refreshScreenAfter = 3;
    return true;
}
function rotate(i) {
    i = document.getElementById("screen");
    w = (i.width/2) + 'px';
    h = (i.height/2) + 'px';
    i.style.webkitTransform='translate(-'+w+',-'+h+') ' +
                            'rotate(90deg) ' +
                            'translate('+w+',-'+h+')'; 
}
function everyHalfSecond() {
  document.getElementById('refreshAfter').innerHTML="Auto refresh in: " + (document.refreshScreenAfter/2) + "s";
  if (document.refreshScreenAfter > 0) {
    document.refreshScreenAfter = document.refreshScreenAfter - 1;
    if (document.refreshScreenAfter == 0) {
      screen = document.getElementById("screen");
      screen.src = screen.src.split("#")[0] + "#" + new Date();
    }
  }
}
function onLoadScreen(image) {
  maybeRotate(image);
  document.refreshScreenAfter = 14;
}

function maybeRotate(image) {
  if (window.location.hash == "#90deg") {
    rotate(image);   
  }
}
setInterval(everyHalfSecond, 500);
</script>
<h1 style="color: red">$::banner</h1>
<iframe height=100 width=500 id=stdout name=stdout></iframe><br>
<input type="button" value="home" onclick="keyEvent(this, 3)">
<input type="button" value="menu" onclick="keyEvent(this, 82)">
<input type="button" value="back" onclick="keyEvent(this, 4)">
<input type="button" value="power" onclick="keyEvent(this, 26)">
<input type="text" id="textEntry" value="Type here" onkeypress="keyPress(this, event)" onkeydown="keyPress(this, event)">
<input type="button" value="refresh 0deg" onclick="window.location='$myself#0deg'; window.location.reload()">
<input type="button" value="refresh 90deg" onclick="window.location='$myself#90deg'; window.location.reload()">
<span id="refreshAfter"></span>
<br>
<img id="screen" style="border:5px dotted grey" draggable="false"
  onmousedown="mouseDown(this, event)"
  onmouseup="mouseUp(this,event)"
  onload="onLoadScreen(this)"
  src="/screenshot?device=$who">
<script type="text/javascript">
  document.getElementById("textEntry").focus();
</script>
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
          runCmd "adb -s $who shell input tap $1 $2";
          return;
      }
      if ($text eq ' ') {
        $text = undef; $key = 62;
      }
      if ($text) {
          runCmd "adb -s $who shell input text $text";
          return;
      }
      if ($key) {
          runCmd "adb -s $who shell input keyevent $key";
          return;
      }
      if ("$down$up" =~ /\?(\d+),(\d+)\?(\d+),(\d+)$/) {
          my $cmd = ($1 == $3 and $2 == $4)
            ? "adb -s $who shell input tap $1 $2"
            : "adb -s $who shell input swipe $1 $2 $3 $4";
          runCmd $cmd;
          return;
      }
  }

  sub resp_screenshot {
      my $cgi  = shift;   # CGI.pm object
      return if !ref $cgi;
      
      my $who = $cgi->param('device');

      my $cmd = "adb -s $who  shell screencap -p";
      warn localtime().": $cmd\n";
      my $image = `$cmd`;
      $image =~ s/\r\n/\n/g;
      $image =~ s/^\* daemon not running\. starting it now on port \d+ \*\s+\* daemon started successfully \*\s+//;
      print $cgi->header( -type => 'image/png' ), $image;
  }

  sub resp_killServer {
      my $cgi  = shift;   # CGI.pm object
      return if !ref $cgi;
      
      print $cgi->header,
            $cgi->start_html("$who");
      runCmd "adb kill-server";
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
