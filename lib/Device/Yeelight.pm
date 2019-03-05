package Device::Yeelight;

use 5.006;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use IO::Select;
use IO::Socket::Multicast;

=head1 NAME

Device::Yeelight - The great new Device::Yeelight!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module provide base class for detecting Yeelight devices.

    use Device::Yeelight;

    my $yeelight = Device::Yeelight->new();
    my @devices = $yeelight->search();
    ...

=head1 SUBROUTINES/METHODS

=head2 new

Creates new Yeelight controller.

=cut

sub new {
    my $class = shift;
    my $data  = {
        address => '239.255.255.250',
        port    => 1982,
        devices => [],
    };
    return bless( $data, $class );
}

=head2 search

Sends search request message and waits for devices response.

=cut

sub search {
    my $self = shift;

    my $socket = IO::Socket::Multicast->new(
        PeerAddr  => $self->{address},
        PeerPort  => $self->{port},
        Proto     => "udp",
        ReuseAddr => 1,
    ) or croak;
    $socket->mcast_loopback(0);

    my $listen = IO::Socket::INET->new(
        LocalPort => $socket->sockport,
        Proto     => 'udp',
        ReuseAddr => 1,
    ) or croak;
    my $sel = IO::Select->new($listen);

    my $query = <<EOQ;
M-SEARCH * HTTP/1.1\r
HOST: $self->{address}:$self->{port}\r
MAN: "ssdp:discover"\r
ST: wifi_bulb\r
EOQ
    $socket->mcast_send( $query, "$self->{address}:$self->{port}" ) or croak;

    my @ready;
    while ( @ready = $sel->can_read ) {
        foreach my $fh (@ready) {
            my $data;
            $fh->recv( $data, 4096 ) or croak;
            $self->parse_response($data) if $data =~ m#^HTTP/1\.1 200 OK\r\n#;
            $sel->remove($fh);
            $fh->close;
        }
    }
    return $self->{devices};
}

=head2 parse_response

Parse response message from Yeelight device.

=cut

sub parse_response {
    my $self = shift;
    my ($data) = @_;

    my $device;
    ( $device->{$_} ) = ( $data =~ /$_: (.*)\r\n/i )
      foreach (
        qw/location id model fw_ver support power bright color_mode ct rgb hue sat name/
      );
    $device->{support} = [ split( ' ', $device->{support} ) ]
      if defined $device->{support};
    push @{ $self->{devices} }, $device;
}

=head1 AUTHOR

Jan Baier, C<< <jan.baier at amagical.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-device-yeelight at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Device-Yeelight>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::Yeelight


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Device-Yeelight>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Device-Yeelight>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Device-Yeelight>

=item * Search CPAN

L<http://search.cpan.org/dist/Device-Yeelight/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2019 Jan Baier.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1;    # End of Device::Yeelight
