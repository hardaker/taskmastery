# Copyright (C) 2007-2009 Wes Hardaker
# License: GNU GPLv2.  See the COPYING file for details.
#!/usr/bin/perl

use ExtUtils::MakeMaker;

%opts = (
         'NAME'         => 'SyncManager',
#         'PREREQ_PM'    => { XML::Simple => 0,
#                           },
         'EXE_FILES' => [qw(syncmanager)],
#         'PMLIBDIRS'    => [qw(GeoDB)],
         
        );

WriteMakefile(%opts);
