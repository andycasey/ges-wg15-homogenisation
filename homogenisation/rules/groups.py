# coding: utf-8

""" Rules for updating groups of duplicate stars in Gaia-ESO WG data sets. """

from __future__ import division, print_function

__author__ = "Andy Casey <arc@ast.cam.ac.uk>"
__all__ = ["DeleteDuplicateRowsRule", "UpdateDuplicateRowsRule"]

# Standard library
import json
import logging
import re
import yaml
from itertools import izip

# Third-party
import numpy as np
from astropy import table
import pandas as pd

# Module-specific
from .base import DuplicateStarRule
from .modify import UpdateColumnsRule

# Create a logger.
logger = logging.getLogger(__name__)


class UpdateDuplicateRowsRule(DuplicateStarRule):

    def __init__(self, apply_to, columns, group_by=None, group_filter=None):
        """
        Find repeated measurements of the same star (groups) and update the
        columns in each group set.

        :param apply_to:
            The description of the working group to apply this rule onto. This
            description can be any string (or list of strings), but if the
            value in `apply_to` does not match any working group in a given
            :class:`homogenisation.DataRelease` then it will raise an exception.

        :type apply_to:
            str or list of str

        :param columns:
            The data columns to update in the affected WG results. This is
            expected to contain the names of the columns as keys, and an
            evaluable function (or string) as values.

        :type columns:
            dict

        :param group_by: [optional]
            The data column(s) to use to identify duplicate stars. If none is
            provided, then matches are performed by CNAME only.

        :type group_by:
            list

        :param group_filter: [optional]
            A filter to use on each group. If it is given, then the rule will
            only be applied to groups where the filter evaluates to True for at
            least one star in the group. The callable should take a single value
            which is the table containing all rows for a given group.

        :type group_filter:
            callable
        """

        self.apply_to = self._parse_apply_to(apply_to)
        self.columns = {}
        for column, evaluable in columns.iteritems():
            self.columns[column.upper()] = evaluable
        if not isinstance(self.columns, dict):
            raise TypeError("columns should be a dictionary where the column "
                "name is a key, and the values are expressions for the update")
        self.group_by = group_by if group_by is not None else ["CNAME"]
        if not isinstance(self.group_by, (tuple, list)):
            self.group_by = self.group_by

        self.group_filter = group_filter
        if self.group_filter is not None \
        and not hasattr(self.group_filter, "__call__"):
            raise TypeError("group filter must be a callable")

        prohibited_columns = ["CNAME"] + self.group_by
        for column in prohibited_columns:
            if column in map(str.upper, self.columns.keys()):
                raise ValueError("cannot update {} of rows because matches are "
                    "performed on {} values".format(column))

        self._reproducible_repr_ = {
            "action": "update_duplicates",
            "columns": self.columns,
            "apply_to": self.apply_to,
            "group_by": self.group_by,
            "group_filter": self.group_filter
        }

    def __str__(self):
        return "<homogenisation.rule to update columns in duplicates rows in "\
            "{0} data (group by {1})>".format(", ".join(self.apply_to),
                ", ".join(self.group_by))

    def __repr__(self):
        return "<homogenisation.rule.UpdateDuplicateRowsRule at {}>"\
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
        debug = kwargs.pop("debug", False)
        affected_wgs = self._affected_wgs(data_release)
        if len(affected_wgs) == 0:
            logger.warn("No working groups in data release {0} ({1}) that are "
                "affected by rule {1}".format(data_release,
                    ", ".join(data_release._wg_names), self))
            return (False, {}, {})

        # Create an environment for if the filter or update rule is a string.
        # I know. But this is for a whitelist of people running locally.
        env = {}
        env.update(self._default_env)
        env.update(kwargs.pop("env", {}))

        rows = dict(zip(affected_wgs, [0] * len(affected_wgs)))
        exceptions = dict(zip(affected_wgs, [0] * len(affected_wgs)))
        for wg in affected_wgs:

            update_rows = []
            wg_results = data_release._wg(wg).data

            # OK, find the duplicates.
            wg_results = wg_results.group_by(self.group_by)
            logger.debug("There are {0} groups by {1} in {2}".format(
                len(wg_results.groups), ", ".join(self.group_by), wg))

            # Here we need to do some work on each group.
            for key, group in izip(wg_results.groups.keys, wg_results.groups):
                if len(group) == 1: continue # Only apply to real groups, pls.

                logger.debug("Found group of size {0} with {1} = {2} in {3} of "
                    "{4}".format(len(group), self.group_by, list(key), wg,
                        data_release))

                # Check the filter: Should we be applying this rule to this
                # group?
                if self.group_filter is not None \
                and not self.group_filter(group):
                    continue

                # For each column, evaluate the rule.
                update_values = {}
                for column, evaluable in self.columns.iteritems():
                    # Evaluate the value.
                    try:
                        if hasattr(evaluable, "__call__"):
                            value = evaluable(rows)
                        else:
                            env["group"] = group
                            value = eval(str(evaluable), env)
                            del env["group"]
                    except:
                        # If we did except, we should check to see if this
                        # column data type is a string. If it's a string we
                        # should just set the value as is.
                        if wg_results[column].dtype.str[:2] == "|S":
                            value = evaluable

                        else:
                            logger.exception("Exception evaluating column value"
                                " for {0} from {1} in rule {2} with rows {3} in"
                                " {4} of {5}".format(column, evaluable, self,
                                    group, wg, data_release))
                            exceptions[wg] += 1
                            if debug:
                                raise

                            # Move onto the next column.
                            continue

                    # Update the column on all the rows in this group.
                    logger.debug("  Updating column {0} = {1} from {0} = {2}"\
                        .format(column, value,
                            list(map(str.strip, map(str, group[column])))))

                    # [TODO] This may be problematic if the string dtype needs
                    # updating.
                    update_values[column] = value
                    rows[wg] += len(group)

                # Actually make the updates.
                for column, value in update_values.items():
                    group[column] = value

        return (True, rows, exceptions)


class DeleteDuplicateRowsRule(DuplicateStarRule):

    def __init__(self, apply_to, columns=None, group_by=None, group_filter=None,
        sort_by=None, order="desc"):
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

        :param columns: [optional]
            The data columns to update in the affected WG results. This is
            expected to contain the names of the columns as keys, and an
            evaluable function (or string) as values.

        :type columns:
            dict

        :param group_by: [optional]
            The data column(s) to use to identify duplicate stars. If none is
            provided, then matches are performed by CNAME only.

        :type group_by:
            list

        :param group_filter: [optional]
            A filter to use on each group. If it is given, then the rule will
            only be applied to groups where the filter evaluates to True for at
            least one star in the group. The callable should take a single value
            which is the table containing all rows for a given group.
            
        :type group_filter:
            callable

        :param sort_by: [optional]
            Which column should be used to sort the data. All duplicates in the
            group get removed, so `sort_by` (and `order`) indicates which of the
            columns should be kept.

        :type sort_by:
            str

        :param order: [optional]
            The order in which to sort the duplicates by (using `sort_by`). Only
            'asc' or 'desc' are available.

        :type order:
            str
        """

        self.apply_to = self._parse_apply_to(apply_to)

        self.columns = {}
        if columns is not None:
            for column, evaluable in columns.iteritems():
                self.columns[column.upper()] = evaluable

            if not isinstance(self.columns, dict):
                raise TypeError(
                    "columns should be a dictionary where the column name is a"\
                    " key, and the values are expressions for the update")

        if sort_by is not None:
            self.sort_by = [sort_by] if isinstance(sort_by, (str, unicode)) \
                else sort_by
        else:
            self.sort_by = None
        self.group_by = group_by if group_by is not None else ["CNAME"]
        if not isinstance(self.group_by, (tuple, list)):
            self.group_by = self.group_by

        self.group_filter = group_filter
        if self.group_filter is not None \
        and not hasattr(self.group_filter, "__call__"):
            raise TypeError(
                "group filter must be a callable that takes a single argument")

        self.order = order.lower()
        if self.order not in ("asc", "desc"):
            raise ValueError("order must be 'asc' or 'desc'")

        self._reproducible_repr_ = {
            "action": "delete_duplicates",
            "columns": self.columns,
            "apply_to": self.apply_to,
            "sort_by": sort_by,
            "group_by": group_by,
            "group_filter": group_filter,
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

        if self.group_filter is not None:
            sort_str = ", ".join([sort_str, "to groups matching {}".format(
                self.group_filter)])
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

            # If there is no filter to apply to the groups, then it is easy:
            # we just need to aggregate the unique rows.
            if self.group_filter is None:
                wg_results = wg_results[wg_results.groups.indices[:-1]]
                index = data_release._wg_names.index(wg)
                data_release._wg_results[index].data = wg_results

                if self.columns:
                    raise NotImplementedError

                num_rows_after = len(wg_results)
                logger.info("{0} duplicate rows removed in {1} by {2}".format(
                    num_rows_before - num_rows_after, wg, self))
                rows[wg] = num_rows_before - num_rows_after

            else:
                logger.debug("Applying filter to {0} identified groups (this "\
                    "will take some time)...".format(len(wg_results.groups)))

                N = len(wg_results.groups)
                mask = np.ones(len(wg_results), dtype=bool)
                affected_groups = 0
                for i, si in enumerate(wg_results.groups.indices[:-1]):
                    ei = wg_results.groups.indices[i + 1]
                    if ei - si == 1: continue # Only apply to real groups, pls.

                    group = wg_results[si:ei]
                    if not self.group_filter(group):
                        continue

                    affected_groups += 1
                    logger.debug("Applying rule to group #{0}/{1}".format(i, N))
                    logger.debug("Keeping the following row from group #{0} "\
                        "(CNAME / OJBECT / GES_FLD / GES_TYPE):".format(i))

                    keeping_row = wg_results[si]
                    logger.debug("    {0} / {1} / {2} / {3} / {4}".format(
                        keeping_row["CNAME"], keeping_row["OBJECT"],
                        keeping_row["GES_FLD"], keeping_row["GES_TYPE"],
                        keeping_row["SETUP"]))

                    if self.columns:
                        logger.debug("Updating columns for this row...")
                        data_release.apply_rule(UpdateColumnsRule(apply_to=[wg],
                            columns=self.columns,
                            filter_rows='row["FILENAME"] == "{}"'.format(
                                keeping_row["FILENAME"])), env={"group": group})

                    logger.debug("Removing CNAME / OBJECT / GES_FLD / GES_TYPE"\
                        "/ SETUP rows:")
                    for row in wg_results[si + 1:ei]:
                        logger.debug("    {0} / {1} / {2} / {3} / {4}".format(
                            row["CNAME"], row["OBJECT"], row["GES_FLD"],
                            row["GES_TYPE"], row["SETUP"]))

                    # OK, now we *will* be applying this rule to this group.
                    # So, we need to delete the duplicate rows.

                    # Since the table is ordered already, we can just exclude
                    # indices si + 1:ei
                    mask[si + 1:ei] = False

                logger.debug("There were {} affected groups by this rule."\
                    .format(affected_groups))

                rows[wg] = (~mask).sum()
                logger.info("{0} duplicate rows removed in {1} by {2}".format(
                    rows[wg], wg, self))

            # [TODO] hard to identify exceptions here...
        
        return (True, rows, exceptions)


