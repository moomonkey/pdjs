#!/bin/bash

PD_EXT=""
if [ "$OS" = "Windows_NT" ]; then
    export TRIPLET="x64-windows-static"
    PD_EXT=".com"
    pacman -q --needed --noconfirm -S diffutils > /dev/null 2>&1
elif [ "$OSTYPE" = "linux-gnu" ]; then
    if [ "$HOSTTYPE" = "x86_64" ]; then
        export TRIPLET="x64-linux"
    fi
fi

export PD="../pd/${TRIPLET}/bin/pd${PD_EXT}"

FAILED=0
RED='\033[0;31m'
GREEN='\033[0;32m'
NOCOLOR='\033[0m'

for TESTFILE in test-*/test-*.pd; do

    TEST=`basename $TESTFILE`
    TESTDIR=`dirname $TESTFILE`
    echo -n "$TEST: "

    pushd $TESTDIR > /dev/null

    . ../run.sh $TEST

    V8_VERSION=`find ../../vcpkg-export/ -type f -name v8_monolith.pc -exec egrep -o 'Version: [0-9.]+' {} \; | egrep -o '[0-9.]+' | head -n1`
    sed "s/pdjs version.*/pdjs version ${VERSION} (v8 version ${V8_VERSION})/" < ./result.txt > ./expected.txt

    EXCEPTION_REGEX="s/^.+\.js:[0-9]+:(.+)/\1/"
    sed -i -r "${EXCEPTION_REGEX}" ./expected.txt
    sed -r "${EXCEPTION_REGEX}" < ./result.${TRIPLET}.txt > ./actual.txt

    ERROR_REGEX="s/^(error: Error.*) '.*\.js':/\1/"
    sed -i -r "${ERROR_REGEX}" ./expected.txt
    sed -i -r "${ERROR_REGEX}" ./actual.txt

    JSOBJECT_REGEX="s/jsobject [0-9]+/jsobject/"
    sed -i -r "${JSOBJECT_REGEX}" ./expected.txt
    sed -i -r "${JSOBJECT_REGEX}" ./actual.txt

    diff --strip-trailing-cr actual.txt ./expected.txt

    TESTSUCCESS=$?

    if [ "$TESTSUCCESS" = 0 ]; then
        printf "${GREEN}success${NOCOLOR} ✔️\n"
    else
        printf "${RED}failed${NOCOLOR} ❌\n"
        FAILED=$((FAILED + 1))
    fi

    popd > /dev/null
done

if [ "$FAILED" = 0 ]; then
    echo "All tests completed successfully."
else
    echo "$FAILED tests failed."
fi

exit $FAILED
