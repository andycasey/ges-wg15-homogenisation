# coding: utf-8

""" Modification rules for updating data from different Gaia-ESO WGs """

from __future__ import division, print_function

__author__ = "Andy Casey <arc@ast.cam.ac.uk>"
__all__ = ["DeleteRowsRule", "UpdateColumnsRule"]

# Standard library
import logging
import json
import yaml

# Third-party
import numpy as np

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

        :param columns:
            The data columns to update in the affected WG results. This is
            expected to contain the names of the columns as keys, and an
            evaluable function (or string) as values.

        :type columns:
            dict
        """

        self.apply_to = self._parse_apply_to(apply_to)
        if not isinstance(columns, dict):
            raise TypeError("columns must be a dictionary with column names as "
                "keys and evaluable strings (or functions) as values")
        if "CNAME" in map(str.upper, self.columns.keys()):
            raise ValueError("cannot update CNAME of rows because matches are "
                "performed on CNAMEs")

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
            filter_str = "where {0}".format(self.filter_rows)

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

        # Create an environment for if the filter is a string.
        # I know. But this is for a whitelist of people running locally.
        env = {}
        env.update(self._default_env)
        env.update(kwargs.pop("env", {}))

        rows = dict(zip(affected_wgs, [0] * len(affected_wgs)))
        exceptions = dict(zip(affected_wgs, [0] * len(affected_wgs)))
        for wg in affected_wgs:
            # If we don't have to match to an external source:
            # - Just need to update columns for rows that meet some filter.
            # - If no filter exists, then the rule is applied to all rows.
            if not self._match_to_external_source:
                # This is just an internal update to a WG results file.
                wg_results = data_release._wg(wg)
                for i, row in enumerate(wg_results.data):

                    # Do we have a filter?
                    if self.filter_rows is None:
                        update_this_row = True
                    else:
                        # Apply the filter
                        try:
                            if hasattr(self.filter_rows, "__call__"):
                                update_this_row = self.filter_rows(row)
                            else:
                                env["row"] = row
                                update_this_row = eval(self.filter_rows, env)
                                del env["row"]

                        except:
                            logger.exception("Exception parsing filter function"
                                " from rule {0} on row {1} in working group {2}"
                                " of {3}:".format(i, self, wg, data_release))
                            exceptions[wg] += 1
                            if debug:
                                raise

                            # Don't update this row.
                            continue
                            
                        # Force boolean.
                        update_this_row = bool(update_this_row)

                    # Does this rule apply to this row of this WG?
                    if update_this_row:

                        old_values = {}
                        new_values = {}
                        for column, evaluable in self.columns.iteritems():

                            # Evaluate the value
                            try:
                                if hasattr(evaluable, "__call__"):
                                    value = evaluable(row)
                                else:
                                    env["row"] = row
                                    value = eval(evaluable, env)
                                    del env["row"]
                            except:
                                logger.exception("Exception evaluating column "
                                    "value for {0} from {1} in rule {2} on row"
                                    "{3} (index {4}) in working group {5} of "
                                    "{6}:".format(
                                        column, evaluable, self, i + 1, i, wg,
                                        data_release))
                                exceptions[wg] += 1
                                if debug:
                                    raise

                            old_values[column] = wg_results.data[column][i]
                            new_values[column] = value
                            wg_results.data[column][i] = value

                        logger.debug("Rule {0} has updated row {1} (index {2}) "
                            "in working group {2} of {3}:".format(self, i + 1,
                                i, wg, data_release))

                        for k, old_value in old_values.iteritems():
                            logger.debug("\t{0} updated from {1} to {2}".format(
                                k, old_value, new_values[k]))

                        rows[wg] += 1

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
        return "<homogenisation.rule.DeleteRows from {0} data where {1}>"\
            .format(", ".join(self.apply_to), self.filter_rows)


    def __repr__(self):
        return "<homogenisation.rule.DeleteRowsRule at {}>"\
            .format(hex(id(self)))


    def apply(self, data_release, **kwargs):
        """
        Apply this rule to a data release.

        :param data_release:
            The working group results.

        :type data_release:
            :class:`homogenisation.release.DataRelease`
        """

        debug = kwargs.pop("debug", False)
        affected_wgs = self._affected_wgs(data_release)
        if len(affected_wgs) == 0:
            logger.warn("No working groups in data release {0} ({1}) that are "
                "affected by rule {1}".format(data_release,
                    ", ".join(data_release._wg_names), self))
            return (False, {}, {})

        # Create an environment for if the filter is a string.
        # I know. But this is for a whitelist of people running locally.
        env = {}
        env.update(self._default_env)
        env.update(kwargs.pop("env", {}))

        # Apply the rule to the results from each affected WG
        rows = dict(zip(affected_wgs, [0] * len(affected_wgs)))
        exceptions = dict(zip(affected_wgs, [0] * len(affected_wgs)))
        for wg in affected_wgs:

            wg_results = data_release._wg(wg)
            mask = np.zeros(len(wg_results.data), dtype=bool)
            for i, row in enumerate(wg_results.data):

                try:
                    if hasattr(self.filter_rows, "__call__"):
                        mask[i] = self.filter_rows(row)
                    else:
                        env["row"] = row
                        mask[i] = eval(self.filter_rows, env)

                except:
                    logger.exception("Exception parsing filter function from "
                        "rule {0} on row {1} in working group {2} of {3}:"\
                        .format(i, self, wg, data_release))
                    exceptions[wg] += 1
                    if debug:
                        raise

            # Delete the rows
            rows[wg] = mask.sum()
            index = data_release._wg_names.index(wg)
            logger.info("{0} rows deleted in {1} results by rule {2}".format(
                rows[wg], wg, self))
            if rows[wg] > 0:
                # Show some summary of those lines?
                for i in np.where(mask)[0]:
                    logger.debug("\tRow {0} (index {1}) of {2} data with CNAME "
                        "/ OBJECT / TARGET : {3} / {4} / {5} has been deleted"\
                        .format(i + 1, i, wg,
                            wg_results.data["CNAME"][i],
                            wg_results.data["OBJECT"][i],
                            wg_results.data["TARGET"][i]))

            # OK, now that we have logged this info, actually delete it.
            data_release._wg_results[index].data = wg_results.data[~mask]

        return (True, rows, exceptions)


