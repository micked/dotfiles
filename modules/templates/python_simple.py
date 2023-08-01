#!/usr/bin/env python
#! /usr/bin/env nix-shell
#! nix-shell -i python -p "python311.withPackages(ps: with ps; [])"
#! nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixos-23.05.tar.gz
"""
The author (msk) was too lazy to write what the program does.

Author: msk

"""

import argparse


def main(args):
    pass


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("i_X", metavar="i:inputX", help="")
    parser.add_argument("o_Y", metavar="o:outputY", help="")
    main(parser.parse_args())
