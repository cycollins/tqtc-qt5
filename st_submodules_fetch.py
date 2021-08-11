#!/usr/bin/env python

"""Set up upstream remote in each submodule and fetch."""

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

    submodule_prefix = "qt"
    submodule_prefix_length = len(submodule_prefix)
    for file_name in os.listdir(script_dir):
        submodule_dir = os.path.join(script_dir, file_name)
        if os.path.isdir(submodule_dir):
            if file_name[:submodule_prefix_length] == submodule_prefix:
                if len(os.listdir(submodule_dir)) == 0:
                    continue

                submodule = file_name

                # Ignore failure here if the upstream remote was already set
                call(["git", "remote", "add", "upstream", "https://code.qt.io/qt/%s.git" % submodule], cwd=submodule_dir)

                if not call(["git", "fetch", "upstream"], cwd=submodule_dir):
                    logger.error("Could not fetch \"upstream\" for submodule \"%s\"." % submodule)
                    continue

                logger.info("Fetched upstream for submodule \"%s\"." % submodule)

    return 0

if __name__ == '__main__':
    sys.exit(run(parse_args(sys.argv[1:])))
