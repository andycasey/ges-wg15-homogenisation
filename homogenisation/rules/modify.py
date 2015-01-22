# coding: utf-8

""" Modification rules for updating data from different Gaia-ESO WGs """

from __future__ import division, print_function

__author__ = "Andy Casey <arc@ast.cam.ac.uk>"
__all__ = ["DeleteRowsRule", "UpdateColumnsRule"]

# Standard library
import logging
import json
import yaml

# Module-specific
from .base import ModificationRule

# Create a logger.
logger = logging.getLogger(__name__)


class UpdateColumnsRule(ModificationRule):

    def __init__(self, apply_to, columns, filter_rows=None, apply_from=None,
        match_by=None):
        """
        Create a rule that acts on working group results and updates columns
        that match some filter, or match rows in an external filename or other
        working group results.

        :param apply_to:
            The description of the working group to apply this rule onto. This
            description can be any string (or list of strings), but if the
            value in `apply_to` does not match any working group in a given
            :class:`homogenisation.DataRelease` then it will raise an exception.

        :type apply_to:
            str or list of str
        """

        self.apply_to = self._parse_apply_to(apply_to)
        self.columns = columns
        self.filter_rows = filter_rows
        self.apply_from = apply_from
        self.match_by = match_by

        self._reproducible_repr_ = {
            "action": "update_columns",
            "apply_to": self.apply_to,
            "columns": columns
        }
        if apply_from is not None:
            self._reproducible_repr_["apply_from"] = apply_from
        if match_by is not None:
            self._reproducible_repr_["match_by"] = match_by
        if filter_rows is not None:
            self._reproducible_repr_["filter_rows"] = filter_rows


    def __str__(self):
        """ Human-readable description of this rule. """

        num_columns = len(self.columns)
        if num_columns == 1:
            column_str = "column {}".format(self.columns[0])
        elif num_columns == 2:
            column_str = "columns {0} and {1}".format(*self.columns)
        else:
            column_str = "{} columns".format(num_columns)

        match_str = ""
        if self._match_to_external_source:
            match_str = "from {0} (match by {1})".format(self.apply_from,
                ", ".join(self.match_by))

        filter_str = ""
        if self.filter_rows is not None:
            filter_str = "where '{0}'".format(self.filter_rows)

        _ = "<homogenisation.rule.UpdateColumns update {0} in {1} data {2} {3}"\
            .format(column_str, ", ".join(self.apply_to), match_str, filter_str)
        return "{}>".format(re.sub(" +", " ", _.strip()))

        
    def __repr__(self):
        return "<homogenisation.rule.UpdateColumnsRule at {}>"\
            .format(hex(id(self)))


    @property
    def _match_to_external_source(self):
        """ Do we need to match the rows to an external source? """
        return (self.apply_from is not None and self.match_by is not None)


    def apply(self, wg_results):
        """
        Apply this rule to the results table from a working group lead.

        :param wg_results:
            The working group results.

        :type wg_results:
            :class:`homogenisation.wg.WorkingGroupResults`
        """

        if wg_results.wg not in self.apply_to:
            raise ValueError("this rule applies to {0} and is not meant to "
                "apply to {1}".format(", ".join(self.apply_to), wg_results.wg))

        # If we don't have to match to an external source:
        # - Just need to update columns for rows that meet some filter.
        # - If no filter exists, then the rule is applied to all rows.

        # If we do need to match to an external source:
        # - If the external source is a WG file then we should have been passed
        #   it in the kwargs from :func:`homogenisation.DataRelease.apply_rule`
        # - If it's not a WG file then we should load it.
        # - Match the tables by the required columns
        # - Filter the rows from the matched table
        # - Update the columns in those rows accordingly

        # Do the columns exist?

        # 

        raise NotImplementedError





class DeleteRowsRule(ModificationRule):

    def __init__(self, apply_to, filter_rows):
        """
        Create a rule that acts on Working Group results and deletes rows that
        match the given filter.

        :param apply_to:
            The description of the working group to apply this rule onto. This
            description can be any string (or list of strings), but if the
            value in `apply_to` does not match any working group in a given
            :class:`homogenisation.DataRelease` then it will raise an exception.

        :type apply_to:
            str or list of str

        :param filter_rows:
            The filter to use on each row. If the filter evaluates to True, then
            the row in the set of results will be deleted.

        :type filter_rows:
            str or callable
        """

        self.apply_to = self._parse_apply_to(apply_to)
        if not hasattr(filter_rows, "__call__"):
            try:
                self.filter_rows = str(filter_rows)
            except (TypeError, ValueError):
                raise TypeError("filter_rows must be a callable or string")

        else:
            self.filter_rows = filter_rows

        self._reproducible_repr_ = {
            "action": "delete_rows",
            "apply_to": self.apply_to,
            "filter_rows": self.filter_rows
        }
        

    def __str__(self):
        return "<homogenisation.rule.DeleteRows from {0} data where '{1}'>"\
            .format(", ".join(self.apply_to), self.filter_rows)

    def __repr__(self):
        return "<homogenisation.rule.DeleteRowsRule at {}>".format(hex(id(self)))


    def apply(self, wg_results, **kwargs):
        """
        Apply this rule to the results table from a working group lead.

        :param wg_results:
            The working group results.

        :type wg_results:
            :class:`homogenisation.wg.WorkingGroupResults`
        """

        if wg_results.wg not in self.apply_to:
            raise ValueError("this rule applies to {0} and is not meant to "
                "apply to {1}".format(", ".join(self.apply_to), wg_results.wg))

        # Create a mask that follows the `filter_rows`
        if hasattr(self.filter_rows, "__call__"):
            func = self.filter_rows

        else:
            # I know. But this is for a whitelist of people running locally.
            env = {}.update(self._default_env)
            env.update(kwargs.pop("env", {}))
            func = lambda row: eval(self.filter_rows, env=env)

        mask = np.zeros(len(wg_results.data), dtype=bool)
        for i, row in enumerate(wg_results.data):
            try:
                mask[i] = func(row)
            except:
                logger.exception("Exception parsing filter function on row {0} "
                    "in working group wg_results {1}:".format(i, wg_results.wg))

        num = mask.sum()
        logger.info("{0} rows deleted in {1} results by rule {2}".format(num,
            wg_results.wg, self))

        # Delete the rows
        wg_results.data = wg_results.data[~mask]

        return wg_results


