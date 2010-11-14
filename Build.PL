#!/usr/bin/perl
use Module::Build;
my $build = Module::Build->new(
    module_name => 'Net::LDAP::Filter::SQL',
    license  => 'perl',
    dist_author => 'Tim Esselens <tim.esselens@gmail.com>',
    dist_abstract => 'LDAP filter to SQL clause transformer',
    requires => {
        'Net::LDAP'  => '0',
    },
);
$build->create_build_script;

