#!/usr/bin/env python
"""
The author (msk) was too lazy to write what the program does.

Author: msk

"""

import argparse


def main(args=None):
    if args is None:
        parser = get_argparser()
        args = parser.parse_args()
    print(args)


def add_arguments(parser):
    parser.add_argument('-X', help='')


def get_argparser():
    """Return an argparse argument parser."""
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    add_arguments(parser)
    return parser


if __name__ == '__main__':
    main()
