#!/usr/bin/perl

use strict;
use File::Copy;
use File::Basename;
my $destination = "$ENV{TARGET_BUILD_DIR}/$ENV{PUBLIC_HEADERS_FOLDER_PATH}";

mkdir $destination unless -d $destination;
open Horos_h, ">", "$destination/Horos.h" or die $!;

print Horos_h "#ifndef __Horos_API\n#define __Horos_API\n\n";

my @fromdirs = ( "$ENV{PROJECT_DIR}/Nitrogen/Sources", "$ENV{PROJECT_DIR}/Nitrogen/Sources/JSON", "$ENV{PROJECT_DIR}/Horos/Sources" );
# TODO: "$ENV{PROJECT_DIR}/cocoahttpserver",

foreach my $root (@fromdirs) {
    opendir(DIR, $root);
    
    my @files = readdir(DIR);
    foreach (@files) {
        my $filename = $_;
        next unless -f "$root/$filename" && $filename =~ /\.h$/s;
        my @args = ( "cp", "-fp", "$root/$filename", "$destination/".(basename $filename) );
        system(@args) == 0 or die "Copy failed: $?";
        print Horos_h "#include <Horos/$filename>\n";
    }
    
    closedir(DIR);
}

print Horos_h "\n#endif\n";
close Horos_h;

chdir "$ENV{TARGET_BUILD_DIR}/$ENV{FULL_PRODUCT_NAME}";
symlink "Versions/Current/Headers", "Headers";

exit 0;
