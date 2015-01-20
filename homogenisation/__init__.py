# coding: utf-8

""" Top-level homogenisation of Gaia-ESO working group results. """

from __future__ import division, print_function

__author__ = "Andy Casey <arc@ast.cam.ac.uk>"

# Standard library
import logging

# Module-specific
from .release import DataRelease

# Create a logger.
logging.basicConfig(level=logging.DEBUG,
    format="%(asctime)s %(name)-12s %(levelname)-8s %(message)s",
    datefmt="%m-%d %H:%M", filename="GES-WG15-homogenisation.log", filemode="a")

console = logging.StreamHandler()
console.setLevel(logging.INFO)

formatter = logging.Formatter("%(name)-12s: %(levelname)-8s %(message)s")
console.setFormatter(formatter)
logging.getLogger("").addHandler(console)