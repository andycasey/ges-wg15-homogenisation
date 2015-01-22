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

    
    def modify_results(self, rule):
        """
        Apply a modification rule (e.g., update columns or delete rows) to some
        or all of the working group results.

        :param rule:
            The rule to apply to the working group results associated with this
            data release.

        :type rule:
            :class:`homogenisation.rule.ModificationRule`
        """

        if not isinstance(rule, rules.ModificationRule):
            raise TypeError("results can only be modified with well specified "
                "constraints, which must be in the form of a homogenisation.rul"
                "es.ModificationRule object")

        logger.debug("Modifying results in {0} with rule {1}".format(self, rule))

        # See which working groups we need to work on.
        applies_to_wg_names = set(self._wg_names).intersection(rule.apply_to)
        logger.debug("Intersection of WG names ({0}) and rule scope ({1}) is: "
            "{2}".format(self._wg_names, rule.apply_to, 
                ", ".join(applies_to_wg_names)))

        if len(applies_to) == 0:
            raise ValueError("found no working group results in ({0}) matching "
                "the requested scope of the rule ({1})".format(self._wg_names,
                    rule.apply_to))

        for wg_name in applies_to_wg_names:

            # Apply this rule to the relevant data table.
            # TODO
            self._wg_results[self._wg_names.index(wg_name)] = rule.apply(self._wg(wg_name))

        # Return the number of rows affected for each WG?
        assert False



    def update_repeated_results(self, rule):
        raise NotImplementedError


    def combine(self, rules):

        raise NotImplementedError

