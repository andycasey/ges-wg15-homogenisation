# coding: utf-8

""" Rules for updating groups of duplicate stars in Gaia-ESO WG data sets. """

from __future__ import division, print_function

__author__ = "Andy Casey <arc@ast.cam.ac.uk>"
__all__ = ["DeleteDuplicateRowsRule"]

# Standard library
import json
import logging
import re
import yaml

# Third-party
import numpy as np
from astropy import table
import pandas as pd

# Module-specific
from .base import DuplicateStarRule

# Create a logger.
logger = logging.getLogger(__name__)



class DeleteDuplicateRowsRule(DuplicateStarRule):

    def __init__(self, apply_to, sort_by=None, group_by=None, order="desc"):
        """
        Find repeated measurements of the same star and delete all but one from
        each group, following some heuristic.

        :param apply_to:
            The description of the working group to apply this rule onto. This
            description can be any string (or list of strings), but if the
            value in `apply_to` does not match any working group in a given
            :class:`homogenisation.DataRelease` then it will raise an exception.

        :type apply_to:
            str or list of str

        :param sort_by: [optional]
            Which column should be used to sort the data. All duplicates in the
            group get removed, so `sort_by` (and `order`) indicates which of the
            columns should be kept.

        :type sort_by:
            str

        :param group_by: [optional]
            The data column(s) to use to identify duplicate stars. If none is
            provided, then matches are performed by CNAME only.

        :type columns:
            list

        :param order: [optional]
            The order in which to sort the duplicates by (using `sort_by`). Only
            'asc' or 'desc' are available.

        :type order:
            str
        """

        self.apply_to = self._parse_apply_to(apply_to)
        if sort_by is not None:
            self.sort_by = [sort_by] if isinstance(sort_by, (str, unicode)) \
                else sort_by
        else:
            self.sort_by = None
        self.group_by = group_by if group_by is not None else ["CNAME"]
        if not isinstance(self.group_by, (tuple, list)):
            self.group_by = self.group_by

        self.order = order.lower()
        if self.order not in ("asc", "desc"):
            raise ValueError("order must be 'asc' or 'desc'")

        self._reproducible_repr_ = {
            "action": "delete_duplicates",
            "apply_to": self.apply_to,
            "sort_by": sort_by,
            "group_by": group_by,
            "order": order
        }

    def __str__(self):
        group_str = ", ".join(self.group_by)
        if self.sort_by is not None:
            _ = ", ".join(self.sort_by) \
                if isinstance(self.sort_by, (tuple, list)) else self.sort_by
            sort_str = ", sort by {0} {1}".format(_, self.order)
        else:
            sort_str = ""
        return "<homogenisation.rule to delete duplicates in {0} data (group b"\
                "y {1})>".format(", ".join(self.apply_to), group_str + sort_str)

    def __repr__(self):
        return "<homogenisation.rule.DeleteDuplicateRowsRule at {}>"\
            .format(hex(id(self)))

    def apply(self, data_release, **kwargs):
        """
        Apply this rule to a data release.

        :param data_release:
            The working group results.

        :type data_release:
            :class:`homogenisation.release.DataRelease`
        """

        # See if there are any WGs in this data release that are affected by
        # this rule.
        affected_wgs = self._affected_wgs(data_release)
        if len(affected_wgs) == 0:
            logger.warn("No working groups in data release {0} ({1}) that are "
                "affected by rule {1}".format(data_release,
                    ", ".join(data_release._wg_names), self))
            return (False, {}, {})

        rows = dict(zip(affected_wgs, [0] * len(affected_wgs)))
        exceptions = dict(zip(affected_wgs, [0] * len(affected_wgs)))
        for wg in affected_wgs:

            update_rows = []
            wg_results = data_release._wg(wg).data

            # Sort as necessary first.
            if self.sort_by is not None:
                logger.debug("Sorting {0} data by {1}".format(
                    wg, ", ".join(self.sort_by)))
                wg_results.sort(self.sort_by)

                if self.order == "desc":
                    logger.debug("Reversing sort in {} because order is 'desc'"\
                        .format(wg))
                    wg_results = wg_results[::-1]

            # OK, find the duplicates.
            num_rows_before = len(wg_results)
            wg_results = wg_results.group_by(self.group_by)

            logger.debug("There are {0} groups by {1} in {2}".format(
                len(wg_results.groups), ", ".join(self.group_by), wg))

            # Aggregate the unique rows.
            wg_results = wg_results[wg_results.groups.indices[:-1]]
            index = data_release._wg_names.index(wg)
            data_release._wg_results[index].data = wg_results

            num_rows_after = len(wg_results)
            logger.info("{0} duplicate rows removed in {1} by {2}".format(
                num_rows_before - num_rows_after, wg, self))
            rows[wg] = num_rows_before - num_rows_after
            # [TODO] hard to identify exceptions here...
        
        return (True, rows, exceptions)


