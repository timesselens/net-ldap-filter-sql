use Test::More;
use Net::LDAP::Filter::SQL;
use Data::Dumper;

my $ldapfilter1 = new Net::LDAP::Filter('(&(name=Homer)(city=Springfield))');
my $ldapfilter2 = bless({ 'equalityMatch' => { 'assertionValue' => 'bar', 'attributeDesc' => 'foo' } }, 'Net::LDAP::Filter');

my $sqlfilter1 = bless($ldapfilter1,'Net::LDAP::Filter::SQL');
my $sqlfilter2 = new Net::LDAP::Filter::SQL('(&(name=Marge)(city=Springfield))');

diag(Dumper({ clause => $sqlfilter1->sql_clause, values => $sqlfilter1->sql_values }));
# $VAR1 = {
#           'clause' => '(name = ?) and (city = ?)',
#           'values' => [
#                         'Homer',
#                         'Springfield'
#                       ]
#         };

diag(Dumper({ clause => $sqlfilter2->sql_clause, values => $sqlfilter2->sql_values }));

# $VAR1 = {
#           'clause' => '(name = ?) and (city = ?)',
#           'values' => [
#                         'Marge',
#                         'Springfield'
#                       ]
#         };

ok(1, "example run");
done_testing();
