# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
use ExtUtils::MakeMaker;

WriteMakefile(
							'NAME' => 'DBIx::HTMLView',
							'DISTNAME' => 'DBIx-HTMLView',
							'VERSION_FROM' => 'HTMLView.pm',
							'dist'   => {COMPRESS=>'gzip', SUFFIX=>'gz'},
);
