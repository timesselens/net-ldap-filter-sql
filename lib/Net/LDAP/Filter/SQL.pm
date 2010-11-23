#!/usr/bin/perl
use strict;
use warnings;
package Net::LDAP::Filter::SQL;
use parent qw/Net::LDAP::Filter/;
use Carp;

our $VERSION = '0.01';

sub _filter_parse {
    my $self = shift;
    my $hash = shift || $self;
    my $args = shift;

    $self->{sql_values} ||= [];
    $self->{sql_ops} ||= { reverse qw/&   and
                                      |   or
                                      !   not
                                      =   equalityMatch
                                      ~   approxMatch
                                      >=  greaterOrEqual
                                      <=  lessOrEqual
                                      / };

    foreach (keys %$hash) {
        /^and/ and return '('. join(') and (', map { $self->_filter_parse($_) } @{$hash->{$_}}) .')';
        /^or/  and return '('. join(') or (', map { $self->_filter_parse($_) } @{$hash->{$_}}) .')';
        /^not/ and return 'not (' . $self->_filter_parse($hash->{$_}) . ')';
        /^present/ and return $hash->{$_}.' is not null';
        /^(equalityMatch|greaterOrEqual|lessOrEqual|approxMatch)/ and do {
                push @{$self->{sql_values}}, $hash->{$_}->{assertionValue};
                return $self->_escape_identifier($hash->{$_}->{attributeDesc}) . " ". $self->{sql_ops}->{$1} . " ?";
        };
        /^substrings/ and do {
            my $str = join("%", "", map { values %$_ } @{$hash->{$_}->{substrings}});
            $str =~ s/^.// if exists $hash->{$_}->{substrings}[0]{initial};
            $str .= '%' unless exists $hash->{$_}->{substrings}[-1]{final};

            push @{$self->{sql_values}}, $str;
            return '(' . $self->_escape_identifier($hash->{$_}->{type}) .' like ?) ';
        };
        /^extensibleMatch/ and do {
            push @{$self->{sql_values}}, $hash->{$_}->{matchValue};
            return $self->_escape_identifier($hash->{$_}->{matchingRule}) . '(' . $self->_escape_identifier($hash->{$_}->{type}) . ') = ?';
        };
    }
    
}

sub _escape_identifier {
    my ($self,$ident) = @_;
    $ident =~ s/\W//g and warn "identifier '$ident' contains non word characters";
    return $ident;
}

sub sql_clause {
    my $self = shift;
    $self->{sql_clause} ||= $self->_filter_parse();
    return $self->{sql_clause};
}

sub sql_values {
    my $self = shift;
    $self->_filter_parse() unless $self->{sql_values};
    return $self->{sql_values};
}

sub as_string {
    my $self = shift;
    return Net::LDAP::Filter::_string(map { $_ => $self->{$_} } grep {! /^sql_/} keys %$self);
}

sub new_from_data {
    my $self = shift;
    my $dataref = shift;
    croak "expecting a HASH" unless ref $dataref eq 'HASH'; 

    my %data = %$dataref;
    return bless(\%data, 'Net::LDAP::Filter::SQL');
}

42;

__END__

=head1 NAME

Net::LDAP::Filter::SQL - LDAP filter to SQL clause transformer

=head1 SYNOPSIS

    my $ldapfilter = new Net::LDAP::Filter('(&(name=Homer)(city=Springfield))');

    my $sqlfilter  = new Net::LDAP::Filter::SQL('(&(name=Marge)(city=Springfield))');
    my $sqlfilter2 = Net::LDAP::Filter::SQL->new_from_data({ 'equalityMatch' => { 'assertionValue' => 'bar', 'attributeDesc' => 'foo' } });
    my $sqlfilter3 = bless($ldapfilter,'Net::LDAP::Filter::SQL');

    print Data::Dumper({ clause => $sqlfilter->sql_clause, values => $sqlfilter->sql_values });

    # ... $dbh->selectall_arrayref('select * from sometable where '.$sqlfilter->sql_clause, undef, $sqlfilter->sql_values)

=head1 DESCRIPTION

This module allows you to transform a Net::LDAP::Filter object into an SQL
clause string containing '?' placeholders.  The corresponding values can be
accessed as a list, and thus can be used inside a dbh prepare or select call.

=head1 METHODS

=head2 new( I<ldapfilter> )

Create a new LDAP Filter

=head2 new_from_data( I<$hashref> )

Creates a new LDAP Filter from an existing data set. i.e. a Net::LDAP::Filter structure

=head2 sql_clause(I<>)

returns an sql where clause in string format with '?' placeholders

=head2 sql_values(I<>)

returns a list of values associated with the filter

=head1 EXAMPLE

    my $filter = new Net::LDAP::Filter::SQL('(&(name=Marge)(city=Springfield))');
    
    print Dumper({ clause => $filter->sql_clause, values => $filter->sql_values });
    
    # $VAR1 = {
    #           'clause' => '(name = ?) and (city = ?)',
    #           'values' => [
    #                         'Marge',
    #                         'Springfield'
    #                       ]
    #         };

=head1 AUTHOR

Tim Esselens C<< <tim.esselens@gmail.com> >>

=head1 BUGS

probably lots, please send patches

=head1 TODO

=over

figure out what approxMatch should do. e.g. soundex? 

=back

=head1 SUPPORT

send me an e-mail

=head1 SEE ALSO

L<Net::LDAP::Filter>
L<Net::LDAP::Server>

=head1 ACKNOWLEDGEMENTS

My mother, for raising me and my brother the way she did. Thanks mom!

=head1 COPYRIGHT & LICENSE

Copyright 2010 datif - Tim Esselens

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
