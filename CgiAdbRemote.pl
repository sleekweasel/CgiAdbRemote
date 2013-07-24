#!/usr/bin/perl
{
  package MyWebServer;

  use HTTP::Server::Simple::CGI;
  use base qw( HTTP::Server::Simple::CGI );

  my %dispatch = (
      '/' => \&resp_root,
      '/screenshot' => \&resp_screenshot,
      '/console' => \&resp_console,
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
      print $cgi->end_html;
  }

  sub resp_console {
      my $cgi  = shift;   # CGI.pm object
      return if !ref $cgi;
      
      my $who = $cgi->param('device');

      print $cgi->header,
            $cgi->start_html("$who");
      print <<END;
<iframe height=50 width=500 name=stdout></iframe><br>
<table border=2><tr><td>
END
      print $cgi->a({href=>"/touch?device=$who&coords=",target=>"stdout"},
              $cgi->img({id=>"screen", src=>"/screenshot?device=$who", ismap=>undef}));
      print "</td></tr></table>";
      print $cgi->end_html;
  }

  sub resp_touch {
      my $cgi  = shift;   # CGI.pm object
      return if !ref $cgi;
      
      my $who = $cgi->param('device');
 
      my $coords = $cgi->param('coords');

      print $cgi->header,
            $cgi->start_html("$who");

# http://blog.softteco.com/2011/03/android-low-level-shell-click-on-screen.html
      if ($coords =~ /\?(\d+),(\d+)$/) {
          my $cmd = "adb -s $who shell input tap $1 $2";
          warn $cmd;
          print `$cmd`;
          print $cmd;
      }
  }

  sub resp_screenshot {
      my $cgi  = shift;   # CGI.pm object
      return if !ref $cgi;
      
      my $who = $cgi->param('device');

      my $cmd = "adb -s $who  shell screencap -p | sed 's/\\r\$//'";
      warn "RUNNING $cmd";

      print $cgi->header( -type => 'image/png' ), `$cmd`;
  }
}

# start the server on port 8080
#my $pid = MyWebServer->new(8080)->background();
my $pid = MyWebServer->new(8080)->run();
print "Use 'kill $pid' to stop server.\n";