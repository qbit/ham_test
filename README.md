ham_test
========

Makefile infrastructure for building HamShield stuff on OpenBSD

## Usage

1. Clone the
[HamShield](https://github.com/EnhancedRadioDevices/HamShield) library
into a directory of your choosing. It's best to not use a directory
that includes other files, as they will be pulled into the
arduino-support directory.
2. Add the `alibs.mk` file to the aforementioned directory.
3. Modify the `Makefile` entry for USER_LIBRARIES to point to the
directory from step #1.

Now you should be able to `make` your HamShield project!
