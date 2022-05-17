#!/usr/bin/env python

"""Remove specified submodule(s)."""

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

    parser.add_argument("-s", "--submodule", dest='submodules', default=[], action="append", help="Submodules to remove (use multiple --submodule args)")
    parser.add_argument("--log-level", type=str, default="INFO", choices=["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"], help="Desired console log level")

    args = parser.parse_args(args)
    return args

def run(args):
    logging.basicConfig(level=args.log_level, format='%(levelname)-8s %(message)s')

    submodules = args.submodules
    for submodule in submodules:
      if not call(["git", "rm", "--cached", "%s" % submodule], cwd=script_dir):
          logger.info("Could not remove submodule \"%s\"; may already be removed." % submodule)
      os.rmdir(os.path.join(script_dir, submodule))
    return 0

if __name__ == '__main__':
    sys.exit(run(parse_args(sys.argv[1:])))
