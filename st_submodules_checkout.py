#!/usr/bin/env python

"""Check out submodules to the same version as the root module."""

import argparse
import logging
import os
import subprocess
import sys

# Prevent .pyc file generation
sys.dont_write_bytecode = True

logger = logging.getLogger(__name__)
script_dir = os.path.dirname(os.path.abspath(__file__))

def split_and_log(string, log_level=logging.DEBUG):
    for line in iter(string.splitlines()):
        line = line.rstrip()
        if line:
            logger.log(log_level, line)

def call(args, **kwargs):
    try:
        p = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, **kwargs)
        stdout, _ = p.communicate()
        split_and_log(stdout)
        return (0 == p.returncode)
    except (OSError, subprocess.CalledProcessError) as exception:
        logger.error('Subprocess failed. Exception: ' + str(exception))
        return False
    except:
        logger.error('Subprocess failed. Unknown exception.')
        return False

def parse_args(args):
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument("-c", "--create", default=False, action="store_true", help="Create the branch from upstream if the forked submodule doesn't contain it.")
    parser.add_argument("--log-level", type=str, default="INFO", choices=["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"], help="Desired console log level")

    args = parser.parse_args(args)
    return args

def run(args):
    logging.basicConfig(level=args.log_level, format='%(levelname)-8s %(message)s')

    branch = subprocess.check_output(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=script_dir).strip();

    prefix = "st-"
    prefix_length = len(prefix)
    if branch[:prefix_length] != prefix:
        logger.error("Branch \"%s\" invalid; must start with \"%s\"." % (branch, prefix))
        return 1
    version = branch[prefix_length:]
    upstream_tag = "v%s" % version
    logger.info("Checking out each submodule to version %s..." % version)

    submodule_prefix = "qt"
    submodule_prefix_length = len(submodule_prefix)
    for file_name in os.listdir(script_dir):
        submodule_dir = os.path.join(script_dir, file_name)
        if os.path.isdir(submodule_dir):
            if file_name[:submodule_prefix_length] == submodule_prefix:
                if len(os.listdir(submodule_dir)) == 0:
                    continue

                submodule = file_name

                logger.info("Checking out submodule \"%s\" to branch \"%s\"..." % (submodule, branch))

                if call(["git", "checkout", "%s" % branch], cwd=submodule_dir):
                    logger.info("Checked out submodule \"%s\" to branch \"%s\"." % (submodule, branch))
                    continue

                if not args.create:
                    logger.error("Could not check out submodule \"%s\" to branch \"%s\"! If the branch doesn't exist, please create it. To do so automatically, call this script with the \"--create\" argument." % (submodule, branch))
                    continue

                logger.info("Attempting to create branch \"%s\" in submodule \"%s\" from upstream tag \"%s\"..." % (branch, submodule, upstream_tag))
                if not call(["git", "fetch", "--tags", "git://code.qt.io/qt/%s.git" % submodule], cwd=submodule_dir):
                    logger.error("Failed to fetch tags from git://code.qt.io/qt/%s.git" % submodule)
                    continue
                if not call(["git", "checkout", upstream_tag], cwd=submodule_dir):
                    logger.info("Attempting to create branch \"%s\" in submodule \"%s\" from current commit in \"upstream/master\"..." % (branch, submodule))
                    if not call(["git", "checkout", "upstream/master"], cwd=submodule_dir):
                        logger.error("No upstream branch \"upstream/master\" in submodule \"%s\"." % submodule)
                        continue
                    if not call(["git", "submodule", "update", "%s" % submodule], cwd=script_dir):
                        logger.error("Could not update submodule \"%s\"." % submodule)
                        continue
                if not call(["git", "checkout", "-b", branch], cwd=submodule_dir):
                    logger.error("Failed to create branch \"%s\" in submodule \"%s\"." % (branch, submodule))
                    continue
                logger.info("Created branch \"%s\" in submodule \"%s\". *IMPORTANT*: Ensure that all of our changes from the previous version, if any, are cherry-picked into this new branch!" % (branch, submodule))

    return 0

if __name__ == '__main__':
    sys.exit(run(parse_args(sys.argv[1:])))
