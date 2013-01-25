#!/usr/bin/python
# -*- coding: utf-8 -*-

# General Imports
import argparse
import subprocess
import sys

# Debugging Stuff
# import pprint
# dumper = pprint.PrettyPrinter(indent=4)

# TODO: adjust the documentation of the script
# Documentation
name        = "a 5 word description"
description = "your_script.py with a longer description, what the script does and for which purpose it is intended."
examples    = "Do some example stuff"
author      = "Written by Benedikt Koeppel (code@benediktkoeppel.ch)"

# Option Parsing
parser = argparse.ArgumentParser(
        add_help=False,
        description=description,
        epilog=author
)

# help Action
class HelpAction(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        # Print out description first, then remove description from the parser
        print parser.description + "\n"
        parser.description = ""

        # Then print out the usage, but remove all newlines, and remove all usage
        print parser.format_usage().replace("\n", "").replace("usage", "Usage")
        parser.usage = ""

        # Then print the rest (i.e. options), but remove usage completely and rename "optional arguments" to "Options"
        print parser.format_help().replace("usage:", "").replace("optional arguments", "Options")

        # Exit
        sys.exit(0)

# man Action
class ManAction(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        # Execute help2man and then display the output with man
        cmdline = "help2man \
                    --name='" + name + "'\
                    --no-info \
                    --no-discard-stderr " + \
                    sys.argv[0] + \
                    " | man -l -"
        subprocess.call(cmdline, shell=True)

        # Exit
        sys.exit(0)

# the built-in -h/--help does not play nice with help2man, so re-create -h/--help more or less
parser.add_argument('-h', '--help', action=HelpAction, nargs=0)

# -m/--man option prints manpage
parser.add_argument('--man', action=ManAction, nargs=0)

# Version
parser.add_argument('--version', action='version', version='%(prog)s 0.1')


# TODO: adjust your options below

# command line switch (True or False (action='store_true'))
parser.add_argument('-c', '--commandline',
        help="Description what the --commandline switch does.",
        action='store_true')

# a mandatory (required=True) string parameter
parser.add_argument('-o', '--optionstring',
        help="Description what the --optionstring parameter does, and what the user should provide for the argument.",
        required=True)

# an array (nargs='+') parser
parser.add_argument('-a', '--array',
        help="Description what the --array parameter does, and which values the user should provide for the argument.",
        nargs='+')


# main
def main():
    # parse arguments
    args = parser.parse_args()

    # TODO: the fun begins here (i.e. your code :-) )
    # args.commandline is now set to True if the -c or --commandline option was passed on the command line
    # args.optionstring now holds the argument that was passed after the -o or --optionstring parameter
    # args.array now holds an array with the values specified after -a or --array



# execute main if started directly
if __name__ == '__main__':
    main()
