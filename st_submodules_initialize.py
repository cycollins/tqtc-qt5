#!/usr/bin/env python

"""Initialize submodules."""

import argparse
import os
import subprocess
import sys

# Prevent .pyc file generation
sys.dont_write_bytecode = True

# Must follow setting dont_write_bytecode to prevent .pyc file generation
import st_submodules_fetch
import st_submodules_checkout
import st_submodules_clean

script_dir = os.path.dirname(os.path.abspath(__file__))

def parse_args(args):
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument("--user", type=str, default="", help="Code review user name")
    parser.add_argument('--mirror', type=str, default="https://github.com/blue-ocean-robotics/tqtc-qt5", help="Remote URL for the our copy of the Qt sources")

    parser.add_argument("--checkout", action='store_true', help="Check out the submodules to the root repository branch")

    args = parser.parse_args(args)
    return args

def init(args):
    user_arg = (" --codereview-username %s" % args.user) if args.user else ""
    no_checkout_arg = "" if args.checkout else " --no-checkout"
    cmd = "perl init-repository%s --branch --module-subset \"essential,qtandroidextras,qtgraphicaleffects,qtimageformats,qtlocation,qtmacextras,qtquickcontrols,qtquickcontrols2,qtsensors,qtsvg,qtvirtualkeyboard,qtwebview,qtwebengine,qtwebchannel,qtwinextras,qtxmlpatterns,qtserialport,qtwebsockets,qtactiveqt\" -f%s --mirror=%s" % (no_checkout_arg, user_arg, args.mirror)
    result = subprocess.call(cmd, cwd=script_dir, shell=True)
    if result:
        return result

def run(args):
    result = init(args)
    if result:
        return result

    # result = st_submodules_fetch.run(st_submodules_fetch.parse_args([]))
    # if result:
    #     return result

    # result = init(args, True)
    # if result:
    #     return result

    # if (args.checkout):
    #     result = st_submodules_checkout.run(st_submodules_checkout.parse_args([]))
    #     if result:
    #         return result

    result = st_submodules_clean.run(st_submodules_clean.parse_args([]))
    if result:
        return result

    return 0

if __name__ == '__main__':
    sys.exit(run(parse_args(sys.argv[1:])))
