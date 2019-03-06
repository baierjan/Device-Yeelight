package Device::Yeelight::Light;

use 5.006;
use utf8;
use strict;
use warnings;

use Carp;
use JSON;
use Data::Dumper;
use IO::Socket;

=encoding utf8
=head1 NAME

Device::Yeelight::Light - WiFi Smart LED Light

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module provide base class for Yeelight smart device

=head1 SUBROUTINES/METHODS

=head2 new

Creates new Yeelight controller.

=cut

sub new {
    my $class = shift;
    my $data  = {
        id => undef,
        location => 'yeelight://',
        support => [],
        @_,
        _socket => undef,
        _next_command_id => 1,
    };
    return bless( $data, $class );
}

=head2 get_prop

This method is used to retrieve current property of smart LED.

=cut

sub get_prop {
    my $self = shift;
    my (@properties) = @_;
    return unless $self->is_supported((caller(0))[3]);
    my @res = $self->call('get_prop', \@properties);
    my $props;
    for my $i (0..$#properties) {
        $props->{$properties[$i]} = $res[$i];
    }
    return $props;
}

=head2 is_supported

Checks if method is supported by the device.

=cut

sub is_supported {
    my $self = shift;
    my ($method) = @_;

    unless (grep { $method =~ m/::$_$/ } @{$self->{support}}) {
        croak "$method is not supported by this device";
        return undef;
    }

    return 1;
}

sub command_id {
    my $self = shift;
    $self->{_next_command_id}++;
}

=head2 connection

Create and return socket connected to the device.

=cut

sub connection {
    my $self = shift;
    return $self->{_socket} if defined $self->{_socket} and $self->{_socket}->connected;
    my ($addr, $port) = $self->{location} =~ m#yeelight://([^:]*):(\d*)#;
    $self->{_socket} = IO::Socket::INET->new(
        PeerAddr  => $addr,
        PeerPort  => $port,
        ReuseAddr => 1,
        Proto     => 'tcp',
    ) or croak $!;
    return $self->{_socket};
}


=head2 call

Sends command to device.

=cut

sub call {
    my $self = shift;
    my ($cmd, $params) = @_;
    my $id = $self->command_id;

    my $json = encode_json({
            id => $id,
            method => $cmd,
            params => $params,
        });
    $self->connection->send("$json\r\n") or croak $!;

    my $buffer;
    $self->connection->recv($buffer, 4096);

    my $response = decode_json($buffer);
    croak "Received response to unkown command $response->{id}" if $response->{id} != $id;
    if (defined $response->{error}) {
        croak "$response->{error}->{message} ($response->{error}->{code})";
        return undef;
    }
    return @{$response->{result}};
}

=head1 AUTHOR

Jan Baier, C<< <jan.baier at amagical.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Jan Baier.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;    # End of Device::Yeelight
