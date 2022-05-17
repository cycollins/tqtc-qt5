#!/usr/bin/env python

"""Remove unused submodules."""

import argparse
import logging
import os
import sys

# Prevent .pyc file generation
sys.dont_write_bytecode = True

# Must follow setting dont_write_bytecode to prevent .pyc file generation
import st_submodules_remove

logger = logging.getLogger(__name__)
script_dir = os.path.dirname(os.path.abspath(__file__))

def parse_args(args):
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument("--log-level", type=str, default="INFO", choices=["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"], help="Desired console log level")

    args = parser.parse_args(args)
    return args

def run(args):
    logging.basicConfig(level=args.log_level, format='%(levelname)-8s %(message)s')

    # For each empty submodule directory, remove the submodule.
    submodule_prefix = "qt"
    submodule_prefix_length = len(submodule_prefix)
    for file_name in os.listdir(script_dir):
        submodule_dir = os.path.join(script_dir, file_name)
        if os.path.isdir(submodule_dir):
            if file_name[:submodule_prefix_length] == submodule_prefix:
                if len(os.listdir(submodule_dir)) == 0:
                    submodule = file_name

                    options = st_submodules_remove.parse_args([])
                    options.submodules = [submodule]
                    options.log_level = args.log_level
                    st_submodules_remove.run(options)
    return 0

if __name__ == '__main__':
    sys.exit(run(parse_args(sys.argv[1:])))
