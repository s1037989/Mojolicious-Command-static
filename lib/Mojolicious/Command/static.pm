package Mojolicious::Command::static;
use Mojo::Base 'Mojolicious::Command';

# This command is a copy of Mojolicious::Command::daemon

use Getopt::Long qw(GetOptionsFromArray :config no_auto_abbrev no_ignore_case);
use Mojo::Server::Daemon;

has description => 'Quickly serve static files';
has usage => sub { shift->extract_usage };

use File::Basename;

sub run {
  my ($self, @args) = @_;

  my $daemon = Mojo::Server::Daemon->new(app => Mojolicious->new);
  GetOptionsFromArray \@args,
    'b|backlog=i'            => sub { $daemon->backlog($_[1]) },
    'c|clients=i'            => sub { $daemon->max_clients($_[1]) },
    'i|inactivity-timeout=i' => sub { $daemon->inactivity_timeout($_[1]) },
    'l|listen=s'   => \my @listen,
    'p|proxy'      => sub { $daemon->reverse_proxy(1) },
    'r|requests=i' => sub { $daemon->max_requests($_[1]) };

  push @{$daemon->app->renderer->classes}, __PACKAGE__;

  # Add all the paths and paths of filenames specified on the command line
  $daemon->app->static->paths([grep { -d $_ } map { -f $_ ? dirname $_ : $_ } @args, '.']);

  # Create numeric shortcuts for each filename specified on the command line
  my @files;
  foreach my $file ( grep { -f $_ } @args ) {
    push @files, basename $file;
    $daemon->app->routes->get('/'.($#files+1))->to(cb=>sub {
      my $c = shift;
      $c->res->headers->content_disposition(sprintf "attachment; filename=%s;", basename $file);
      $c->reply->asset(Mojo::Asset::File->new(path => $file));
    });
  }

  # Build an index of the available specified files
  $daemon->app->routes->get('/')->name('index')->to(files => \@files);

  $daemon->listen(\@listen) if @listen;
  $daemon->run;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::static - Quickly serve static files

=head1 SYNOPSIS

  Usage: APPLICATION static [OPTIONS] dir1 dir2 ... file1 file2 ...

    ./myapp.pl static

  Options:
    -h, --help          Show this summary of available options

=head1 DESCRIPTION

L<Mojolicious::Command::static> quickly serves static files

Serves files from the current directory as well as those specified on the
command line.  Numeric shortcuts (e.g. /1, /2, etc) are created for files
that are specified on the command line.

=head1 ATTRIBUTES

L<Mojolicious::Command::static> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 description

  my $description = $static->description;
  $static         = $static->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $static->usage;
  $routes   = $static->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::static> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $static->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut

__DATA__
@@ index.html.ep
% my $c = 0;
<p>List of static files available for download</p>
% foreach ( @$files ) {
  <a href="/<%= ++$c %>"><%= $_ %></a><br />
% }
