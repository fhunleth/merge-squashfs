#!/bin/bash

export LC_ALL=C

TESTS_DIR=$(dirname $(readlink -f $0))

WORK=$TESTS_DIR/work

INPUT_SQUASHFS=$WORK/input.squashfs

INPUT_SQUASHFS_PSEUDOFILE=$WORK/input.squashfs.pseudo
INPUT_SQUASHFS_ROOT=$WORK/input.squashfs.root

OVERLAY_DIR=$WORK/overlay
OUTPUT_SQUASHFS=$WORK/output.squashfs

MERGE_SQUASHFS=$TESTS_DIR/../merge-squashfs

LOCAL_USER=$(id -un)
LOCAL_GROUP=$(id -gn)

[[ -e $MERGE_SQUASHFS ]] || ( echo "Build $MERGE_SQUASHFS first"; exit 1 )

run() {
    TEST=$1
    EXPECTED=$WORK/$TEST.expected
    ACTUAL=$WORK/$TEST.actual

    echo "Running $TEST..."

    rm -fr $WORK
    # Create some common directories so that scripts don't need to
    mkdir -p $OVERLAY_DIR
    mkdir -p $INPUT_SQUASHFS_ROOT

    # Run the test script to setup files for the test
    source $TESTS_DIR/$TEST

    # If the test creates a pseudofile, then use it to create the
    # input.
    if [[ -e $INPUT_SQUASHFS_PSEUDOFILE ]]; then
        pushd $INPUT_SQUASHFS_ROOT >/dev/null
        mksquashfs . $INPUT_SQUASHFS -pf $INPUT_SQUASHFS_PSEUDOFILE -no-progress >/dev/null
        popd >/dev/null
    fi

    # Run
    $MERGE_SQUASHFS $INPUT_SQUASHFS $OUTPUT_SQUASHFS $OVERLAY_DIR

    # See what the resulting squashfs looks like
    unsquashfs -p 1 -no-progress -ll $OUTPUT_SQUASHFS > $ACTUAL.raw

    # Clean up the results
    #
    # 1. Remove unsquashfs info messages
    # 2. Remove blank lines
    # 3. Remove the root file system line since merge-squashfs doesn't work with it
    # 4. Normalize uid/gid of the local user
    # 5. Remove timestamps
    # 6. Normalize whitespace
    cat $ACTUAL.raw \
        | grep -v 'Parallel unsquashfs: Using' \
        | grep -v 'inodes.*blocks.*to write' \
        | grep -v '^$' \
        | grep -v 'squashfs-root$' \
        | sed "s^$LOCAL_USER/$LOCAL_GROUP^luser/lgroup^" \
        | sed 's/201[0-9]-[01][0-9]-[0-3][0-9] [0-1][0-9]:[0-5][0-9]//' \
        | sed 's/[[:space:]]\+/ /g' \
        > $ACTUAL

    # Check results
    diff -w $EXPECTED $ACTUAL
    if [[ $? != 0 ]]; then
        echo "Test $TEST failed!"
        exit 1
    fi
}

# Test command line arguments
TESTS=$(ls $TESTS_DIR/[0-9][0-9][0-9]_* | sort)
for TEST_CONFIG in $TESTS; do
    TEST=$(basename $TEST_CONFIG)
    run $TEST
done

rm -fr $WORK
echo "Pass!"
exit 0
