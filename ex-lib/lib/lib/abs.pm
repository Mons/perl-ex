# Copyright (c) 200[789] Mons Anderson <mons@cpan.org>. All rights reserved
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
package lib::abs;

=head1 NAME

lib::abs - The same as C<lib>, but makes relative path absolute.

=head1 DESCRIPTION

C<lib::abs> is just an alias for L<ex::lib>. See the docs there

=cut


$lib::abs::VERSION = $ex::lib::VERSION;

use strict;
use warnings;
use ex::lib ();
*import = \&ex::lib::import;
*unimport = \&ex::lib::unimport;

1;
__END__
=head1 COPYRIGHT & LICENSE

Copyright 2007-2009 Mons Anderson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Mons Anderson, <mons@cpan.org>

=cut
