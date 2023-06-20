#!/usr/bin/env python
"""
The author (msk) was too lazy to write what the program does.

Author: msk

"""

import argparse

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('i_X', metavar='i:inputX', help='')
    parser.add_argument('o_Y', metavar='o:outputY', help='')

    args = parser.parse_args()
