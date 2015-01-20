# coding: utf-8

""" Class for a Gaia-ESO Survey Data Release object. """

from __future__ import division, print_function

__author__ = "Andy Casey <arc@ast.cam.ac.uk>"

# Standard library
import logging

# Create a logger.
logger = logging.getLogger(__name__)


class DataRelease(object):

    def __init__(self, version=None):

        self.version = version



    def ingest(self, filenames, validate=True):

        # Load the working group files into this DataRelease

        raise NotImplementedError



    def update_results(self, rule):
        raise NotImplementedError


    def update_repeated_results(self, rule):
        raise NotImplementedError


    def combine(self, rules):

        raise NotImplementedError

