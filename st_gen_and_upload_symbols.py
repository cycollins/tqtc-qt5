#!/usr/bin/env python

import argparse
import logging
import os
import os.path
import sys
import platform
import subprocess
import shutil

# Prevent .pyc file generation
sys.dont_write_bytecode = True

# This script assumes that you have a 'sw-dev' checkout at the same level as this script (unless you pass --swdev)
# or have set the env variable QT_BUILD_SWDEV (useful if you're trying to run st_build locally and have sw-dev checked
# out elsewhere)
# and that the working directory is the qt5 build directory (which is the qt5 repo directory by default)
if __name__ == '__main__':
    swdev_default = os.environ.get('QT_BUILD_SWDEV', 'sw-dev')
    parser = argparse.ArgumentParser()
    parser.add_argument('--swdev', dest='swdev', action='store', default=swdev_default, type=str)
    parser.add_argument('--os', dest='os', action='store', default=None, type=str,
                        choices=['win32', 'win64', 'macosx', 'linux', 'android', 'ios'], required=True)
    args = parser.parse_args()

    if (args.os == 'win64'):
        logging.warning("Symbol upload for x64 not yet supported. See http://code.google.com/p/google-breakpad/issues/detail?id=427")
        sys.exit(0)
    if not os.path.isdir(args.swdev):
        logging.error("sw-dev folder does not exist.")
        sys.exit(1)

    def swdevpath(path):
        return os.path.join(args.swdev, path)

    win_dump_syms = swdevpath('stacks/texas_videoconf/third_party/third_party/breakpad/tools/windows/binaries/dump_syms.exe')
    linux_dump_syms = swdevpath('stacks/texas_videoconf/third_party/third_party/breakpad/tools/linux/dump_syms/dump_syms')
    mac_dump_syms = swdevpath('stacks/texas_videoconf/third_party/third_party/breakpad/tools/mac/dump_syms/build/Release/dump_syms')
    dump_syms = {
            'win64': win_dump_syms,
            'win32': win_dump_syms,
            'linux': linux_dump_syms,
            'android': linux_dump_syms,
            'macosx': mac_dump_syms,
            'ios': mac_dump_syms,
            }

    linux_build_dump_syms = swdevpath('build_scripts/build_dump_syms_linux.sh')
    mac_build_dump_syms = swdevpath('build_scripts/build_dump_syms_osx.sh')
    build_dump_syms = {
            'win32': None,
            'win64': None,
            'linux': linux_build_dump_syms,
            'android': linux_build_dump_syms,
            'macosx': mac_build_dump_syms,
            'ios': mac_build_dump_syms,
            }

    shutil.rmtree('symbols', True)

    symbolstore = swdevpath('stacks/texas_videoconf/third_party/third_party/breakpad/tools/symbolstore.py')
    symbolupload = swdevpath('stacks/texas_videoconf/scripts/upload_symbols.py')

    build = build_dump_syms[args.os]
    if (build):
        subprocess.check_call([build])

    cmd = ['python', symbolstore, dump_syms[args.os], 'symbols', '.']
    subprocess.check_call(cmd)

    cmd = ['python', symbolupload, 'symbols', '-o', args.os, '-c', 'Final', '--software-channel', 'qt-symbols', '--software-version', '1']
    subprocess.check_call(cmd)
