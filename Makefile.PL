# Copyright (C) 2011 Wes Hardaker
# License: GNU GPLv2.  See the COPYING file for details.
#!/usr/bin/perl

use ExtUtils::MakeMaker;

%opts = (
         'NAME'         => 'TaskMastery',
#         'PREREQ_PM'    => { XML::Simple => 0,
#                           },
         'EXE_FILES' => [qw(taskmastery)],
#         'PMLIBDIRS'    => [qw(GeoDB)],
         
        );

WriteMakefile(%opts);
