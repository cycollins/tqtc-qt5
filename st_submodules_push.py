#!/usr/bin/env python

"""Push submodules and add upstream tracking reference."""

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

    submodule_prefix = "qt"
    submodule_prefix_length = len(submodule_prefix)
    for file_name in os.listdir(script_dir):
        submodule_dir = os.path.join(script_dir, file_name)
        if os.path.isdir(submodule_dir):
            if file_name[:submodule_prefix_length] == submodule_prefix:
                if len(os.listdir(submodule_dir)) == 0:
                    continue

                submodule = file_name
                submodule_branch = subprocess.check_output(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=submodule_dir).strip();
                if submodule_branch != branch:
                    logger.error("The submodule \"%s\" is checked out to branch \"%s\" instead of \"%s\". Did not push." % (submodule, submodule_branch, branch))

                if not call(["git", "push", "-u", "origin", branch], cwd=submodule_dir):
                    logger.error("Could not push the branch \"%s\" in submodule \"%s\" to origin." % (branch, submodule))
                    continue
                logger.info("Pushed branch \"%s\" in submodule \"%s\" to origin." % (branch, submodule))

    return 0

if __name__ == '__main__':
    sys.exit(run(parse_args(sys.argv[1:])))
