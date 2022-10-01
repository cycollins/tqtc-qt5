#!/usr/bin/env python

"""Update fork from upstream.

This will clone the repository from our github account into the current directory,
update the branch from upstream, push it back to our github account, and delete
the clone directory.

This is useful for nested submodules like qtdeclarative-testsuites,
qtxmlpatterns-testsuites, and qtlocation-mapboxgl that are forked into our account
and may need to be updated when we update our Qt version.
"""

import argparse
import os
import subprocess
import sys
from distutils.dir_util import remove_tree

# Prevent .pyc file generation
sys.dont_write_bytecode = True

script_dir = os.path.dirname(os.path.abspath(__file__))
current_dir = os.getcwd()

def parse_args(args):
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument("--repository", type=str, default="", help="The name of the github.com/suitabletech repository")

    args = parser.parse_args(args)
    return args

def run(args):
    repository = args.repository
    if not repository:
        print >> sys.stderr, "The --repository argument is required and must specify a valid repository"
        return -1
    
    result = subprocess.call(['git', 'clone', 'https://github.com/suitabletech/%s.git' % repository], cwd=current_dir)
    if (result != 0):
        print >> sys.stderr, "Error cloning https://github.com/suitabletech/%s.git" % repository
        return result

    repository_dir = os.path.join(current_dir, repository)

    result = subprocess.call(['git', 'remote', 'add', 'upstream', 'https://github.com/qt/%s.git' % repository], cwd=repository_dir)
    if (result != 0):
        print >> sys.stderr, "Error adding upstream remote https://github.com/qt/%s.git" % repository
        return result

    result = subprocess.call(['git', 'fetch', 'upstream'], cwd=repository_dir)
    if (result != 0):
        print >> sys.stderr, "Error fetching from upstream"
        return result

    branch = subprocess.check_output(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=repository_dir).strip();
    result = subprocess.call(['git', 'merge', 'upstream/%s' % branch], cwd=repository_dir)
    if (result != 0):
        print >> sys.stderr, "Error merging branch upstream/%s" % branch
        return result

    result = subprocess.call(['git', 'push'], cwd=repository_dir)
    if (result != 0):
        print >> sys.stderr, "Error pushing changes"
        return result

    remove_tree(repository_dir)
    return 0

if __name__ == '__main__':
    sys.exit(run(parse_args(sys.argv[1:])))
