# coding: utf-8

""" Class for a Gaia-ESO Survey Data Release object. """

from __future__ import division, print_function

__author__ = "Andy Casey <arc@ast.cam.ac.uk>"
__all__ = ["DataRelease"]

# Standard library
import logging

# Module-specific
from . import (rules, wg)

# Create a logger.
logger = logging.getLogger(__name__)


class DataRelease(object):

    def __init__(self, version):
        logger.debug("Created DataRelease object with version {}".format(version))
        self.version = version


    def ingest(self, filenames, validate=True):
        """
        Ingest recommended results files from the Working Group leads.

        :param filenames:
            A list of filenames containing results from the Working Group leads.

        :type filenames:
            list of str

        :param validate: [optional]
            Validate that the input files do not contain any unexpected data.

        :type validate:
            bool
        """

        if not isinstance(filenames, (tuple, list)):
            raise TypeError("expected list of filenames for DataRelease object")

        # Load the working group files into this DataRelease
        self._wg_results = \
            [wg.RecommendedResults.from_filename(filename, validate=validate) \
                for filename in filenames]

        # Keep an attribute for accessing which WG they are.
        self._wg_names = [_.wg.upper() for _ in self._wg_results]
        return True


    def _wg(self, wg):
        """
        A convenience function to access the results from a given working group.
        """
        return self._wg_results[self._wg_names.index(wg)]

    
    def combine(self, working_groups, where=None):
        # Return a table containing stars common to multiple working groups.
        raise NotImplementedError

    
