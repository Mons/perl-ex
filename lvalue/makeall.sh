#!/bin/bash

rm -rf MANIFEST.bak MANIFEST Makefile.old && \
pod2text lib/lvalue.pm > README && \
perl Makefile.PL && \
rm *.tar.gz && \
make manifest && \
perl -i -lne 'print unless /(?:\.tar\.gz$|^dist)/' MANIFEST && \
make clean && \
perl Makefile.PL && \
make && \
make test && \
make disttest && \
make dist && \
cp -f *.tar.gz dist/ && \
make clean && \
rm -rf MANIFEST.bak Makefile.old && \
echo "All is OK"
