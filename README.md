# merge-squashfs

Merge a directory into a squashfs archive. Why? Currently `mksquashfs` only supports
appending to archives. This allows for the addition of files, but not the replacement
of files already in the archive. You may ask why you can't just `unsquashfs` the
archive, replace the files and `mksquashfs`. Well, you can, but if you're running
on a platform that lacks `fakeroot` and `fakechroot`, maintaining permissions, ownership,
and special files requires more work. This script does the more work.

## Usage

    merge-squashfs <input squashfs> <output squashfs> <overlay directory>

## Testing

Run `./run_tests.sh` to run through a set of unit tests to make sure that `merge-squashfs`
works on your platform.
