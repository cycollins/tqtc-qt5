#!/usr/bin/env python

import argparse
import os
import platform
import subprocess
import sys

# Prevent .pyc file generation
sys.dont_write_bytecode = True

# Must follow setting dont_write_bytecode to prevent .pyc file generation
import st_submodules_initialize

script_dir = os.path.dirname(os.path.abspath(__file__))
current_dir = os.getcwd()

windows = platform.system() == 'Windows'
linux = platform.system() == 'Linux'
osx = platform.system() == 'Darwin'

def parseArguments():
    parser = argparse.ArgumentParser()
    parser.add_argument('--mobile', default=None, help="Mobile platform; 'android' or 'ios'")
    parser.add_argument('--arch', dest='arch', action='store', help="The architecture; context depends on platform")
    parser.add_argument('--developer', action='store_true', help="Perform developer build")
    parser.add_argument('--clean', action='store_true', help="Clean the repository first")
    parser.add_argument('--initialize', action='store_true', help="Initialize the repository first")
    parser.add_argument('--openssl', default=None, help="If specified, the path to the local OpenSSL build to use (if applicable)")
    parser.add_argument('--user', default=None, help="The user name for the code review account (optional)")
    parser.add_argument('--no-make', action='store_true', help="Don't call make")
    parser.add_argument('--mirror', default="https://github.com/blue-ocean-robotics/tqtc-qt5", help="Remote URL for the our copy of the Qt sources")
    args = parser.parse_args()

    # If on TeamCity, override arguments accordingly
    tc_conf = os.environ.get('TEAMCITY_BUILDCONF_NAME', None)
    if tc_conf:
        print("Configuring for TeamCity...")
        args.clean = True
        args.initialize = True
        args.developer = False

        if (tc_conf.find('android') != -1):
            args.mobile = 'android'
            if (tc_conf.find('x86') != -1):
                args.arch = 'x86'
            elif (tc_conf.find('arm') != -1):
                args.arch = 'armeabi-v7a'
        elif (tc_conf.find('ios') != -1):
            args.mobile = 'ios'
    else:
        print("Not configuring for TeamCity.")

    return args

def clean():
    cmd = ["git", "clean", "-dfx", "--exclude=sw-dev"]
    if subprocess.call(cmd, cwd=script_dir) != 0:
        return False

    cmd = "git submodule foreach --recursive \"git clean -dfx\""
    if subprocess.call(cmd, cwd=script_dir, shell=True) != 0:
        return False

    return True

def initialize(user, mirror):
    options = st_submodules_initialize.parse_args([])
    options.user = user
    options.checkout = True
    options.mirror=mirror
    if st_submodules_initialize.run(options) != 0:
        return False

    return True

def buildAndroid(developer, arch, openssl):
    if developer:
        cmd = [os.path.join(script_dir, "st_developer_build_android.sh"), arch]
        if openssl is not None:
            cmd.append(openssl)
    else:
        if osx:
            plat = 'osx'
        elif linux:
            plat = 'linux'
        else:
            print("Only MacOS and Linux hosts are supported for Android builds", file=sys.stderr)
            return False

        cmd = [os.path.join(script_dir, "st_build_android.sh"), plat, arch]
    return (subprocess.call(cmd, cwd=current_dir) == 0)

def buildIOS(developer, no_make):
    if developer:
        cmd = [os.path.join(script_dir, "st_developer_build_ios.sh")]
    else:
        cmd = [os.path.join(script_dir, "st_build_ios.sh")]

    if no_make:
        cmd += "1"

    return (subprocess.call(cmd, cwd=current_dir) == 0)

def buildWindows(developer, openssl):
    if developer:
        cmd = [os.path.join(script_dir, "st_developer_build_win32.bat")]
        if openssl is not None:
            cmd.append(openssl)
    else:
        cmd = [os.path.join(script_dir, "st_build_win32.bat")]
    return (subprocess.call(cmd, cwd=current_dir) == 0)

def buildLinux(developer):
    if developer:
        cmd = [os.path.join(script_dir, "st_developer_build_linux.sh")]
    else:
        cmd = [os.path.join(script_dir, "st_build_linux.sh"), "64", "x64"]
    return (subprocess.call(cmd, cwd=current_dir) == 0)

def buildOSX(developer):
    if developer:
        cmd = [os.path.join(script_dir, "st_developer_build_osx.sh")]
    else:
        cmd = [os.path.join(script_dir, "st_build_osx.sh")]
    return (subprocess.call(cmd, cwd=current_dir) == 0)

def main():
    args = parseArguments()

    if args.clean:
        if not clean():
            print("Clean failed.", file=sys.stderr)
            exit(-1)

    if args.initialize:
        if not initialize(args.user, args.mirror):
            print("Initialization failed.", file=sys.stderr)
            exit(-1)

    if args.mobile == 'android':
        if not args.arch:
            print("Must specify arch when compiling for Android", file=sys.stderr)
            exit(-1)
        if not buildAndroid(args.developer, args.arch, args.openssl):
            print("Build failed.", file=sys.stderr)
            exit(-1)
    elif args.mobile == 'ios':
        if not buildIOS(args.developer, args.no_make):
            print("Build failed.", file=sys.stderr)
            exit(-1)
    elif args.mobile is not None:
        print("--mobile must be either 'ios' or 'android'.", file=sys.stderr)
        exit(-1)
    elif windows:
        if not buildWindows(args.developer, args.openssl):
            print("Build failed.", file=sys.stderr)
            exit(-1)
    elif linux:
        if not buildLinux(args.developer):
            print("Build failed.", file=sys.stderr)
            exit(-1)
    elif osx:
        if not buildOSX(args.developer):
            print("Build failed.", file=sys.stderr)
            exit(-1)
    else:
        print("Build not supported.", file=sys.stderr)
        exit(-1)

if __name__ == "__main__":
    main()
