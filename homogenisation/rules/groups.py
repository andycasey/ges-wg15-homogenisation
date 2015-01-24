# coding: utf-8

""" Rules for updating groups of duplicate stars in Gaia-ESO WG data sets. """

from __future__ import division, print_function

__author__ = "Andy Casey <arc@ast.cam.ac.uk>"

# Standard library
import json
import logging
import re
import yaml

# Third-party
import numpy as np
from astropy import table

# Module-specific
from .base import RepeatedStarRule

# Create a logger.
logger = logging.getLogger(__name__)

