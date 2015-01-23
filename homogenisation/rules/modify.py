# coding: utf-8

""" Modification rules for updating data from different Gaia-ESO WGs """

from __future__ import division, print_function

__author__ = "Andy Casey <arc@ast.cam.ac.uk>"
__all__ = ["DeleteRowsRule", "UpdateColumnsRule"]

# Standard library
import json
import logging
import re
import yaml
from collections import Counter

# Third-party
import numpy as np
from astropy import table

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

        :param filter_rows: [optional]
            A filter to use on each row. If the filter evaluates to True, then
            the row in the set of results will be deleted.

        :type filter_rows:
            str or callable

        :param apply_from: [optional]
            If `apply_from` is not supplied, then the rule is expecting to 
            update affected working group results. However, if `apply_from` is
            given (which can be a working group reference or an external file)
            then the affected working group results will be matched against the
            data in `apply_from`, and values from the matched row are available
            in the `row` as, for example, `FROM_TEFF` (opposed to `TO_TEFF`).

        :type apply_from:
            str, referencing a filename or a working group (e.g., WG14)

        :param match_by: [optional]
            When `apply_from` is used to match data to another table, the 
            `match_by` parameter specifies the column(s) to use to match
            identical rows. If `apply_from` is provided and `match_by` is not
            specified, this will default to matching by CNAME. However, the
            `match_by` term can be used to match tables by multiple columns.
            An example might be `('CNAME', 'SETUP')` to match rows from an
            existing file by CNAME and SETUP.

        :type match_by:
            str, or a list of str
        """

        self.apply_to = self._parse_apply_to(apply_to)
        if not isinstance(columns, dict):
            raise TypeError("columns must be a dictionary with column names as "
                "keys and evaluable strings (or functions) as values")
        if "CNAME" in map(str.upper, columns.keys()):
            raise ValueError("cannot update CNAME of rows because matches are "
                "performed on CNAMEs")

        self.columns = columns
        self.filter_rows = filter_rows
        if self.filter_rows is not None:
            if not hasattr(self.filter_rows, "__call__"):
                try:
                    self.filter_rows = str(self.filter_rows)
                except (TypeError, ValueError):
                    raise TypeError("filter_rows must be a callable or string")

        self.apply_from = apply_from
        self.match_by = [match_by] if match_by is not None \
            and isinstance(match_by, (str, unicode)) else match_by

        self._reproducible_repr_ = {
            "action": "update_columns",
            "apply_to": self.apply_to,
            "columns": columns
        }
        if self.apply_from is not None:
            self._reproducible_repr_["apply_from"] = self.apply_from
        if self.match_by is not None:
            self._reproducible_repr_["match_by"] = self.match_by
        if self.filter_rows is not None:
            self._reproducible_repr_["filter_rows"] = self.filter_rows


    def __str__(self):
        """ Human-readable description of this rule. """

        num_columns = len(self.columns)
        if num_columns == 1:
            column_str = "column {}".format(self.columns.keys()[0])
        elif num_columns == 2:
            column_str = "columns {0} and {1}".format(*self.columns.keys())
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


    def _update_data_types(self, data_table, update_rows):
        """ Update data table types if necessary. """
        
        if len(update_rows) == 0:
            return data_table

        columns = update_rows[0][1]

        # Let's just check for column names with string data types, as we may 
        # need to lengthen them.
        str_columns = [c for c in columns if data_table.dtype[c].kind == "S"]

        # Check the values in the update_rows variable
        str_lengths = [int(data_table.dtype[c].str[2:]) for c in str_columns]

        update_length = {}
        for i, row in update_rows:
            for column, length in zip(str_columns, str_lengths):
                if len(row[column]) > length:
                    update_length.setdefault(column, 0)
                    update_length[column] = \
                        max([update_length[column], len(row[column])])

        # Any updates?
        if len(update_length) == 0:
            logger.debug("No data types need updating.")
            return data_table

        else:
            logger.debug("Updating table dtypes: {0}".format(update_length))

            # Update data types
            old_dtypes = data_table.dtype.descr
            new_dtypes = []
            for column, old_dtype in old_dtypes:
                if column in update_length:
                    new_dtypes.append(
                        (column, '|S{}'.format(update_length[column]))
                    )
                else:
                    new_dtypes.append((column, old_dtype))

            return table.Table(data_table._data.astype(new_dtypes))


    @property
    def _match_to_external_source(self):
        """ Do we need to match the rows to an external source? """
        return (self.apply_from is not None and self.match_by is not None)


    def apply(self, data_release, debug=False, **kwargs):
        """
        Apply this rule to a data release.

        :param data_release:
            The working group results.

        :type data_release:
            :class:`homogenisation.release.DataRelease`

        :param debug: [optional]
            Re-raise any exception that occurs while parsing the rule filter.

        :type debug:
            bool
        """

        # See if there are any WGs in this data release that are affected by
        # this rule.
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

        # Just so we don't have to do this within the loop..
        if self._match_to_external_source:
            # Is the match to and external source?
            if self.apply_from not in data_release._wg_names:
                image = fits.open(self.apply_from)
                apply_from_extension = kwargs.pop("apply_from_extension", 0)
                apply_from_data = image[apply_from_extension].data

            else:
                apply_from_data = data_release._wg(self.apply_from).data

            # Check for uniqueness?
            match_by = self.match_by if self.match_by is not None else ["CNAME"]
            unique_entries = unique_table(apply_from_data, keys=match_by)
            if len(apply_from_data) > len(unique_entries):
                logger.warn("Matching data from {0} but those data have "
                    "multiple rows for combinations of {1}".format(
                        self.apply_from, ", ".join(match_by)))

            logger.debug("Applying from data with {0} rows".format(
                len(apply_from_data)))

        rows = dict(zip(affected_wgs, [0] * len(affected_wgs)))
        exceptions = dict(zip(affected_wgs, [0] * len(affected_wgs)))
        for wg in affected_wgs:

            update_rows = []
            wg_results = data_release._wg(wg)

            # Do all the columns exist in this WG?
            for column in self.columns.keys():
                if column not in wg_results.data.dtype.names:
                    raise ValueError("column name {0} does not exist in the {1}"
                        " table, so rule {2} cannot be applied".format(column,
                            wg, self))
            logger.debug("All columns for rule {0} appear in WG {1}".format(
                self, wg))

            # If we don't have to match to an external source:
            # - Just need to update columns for rows that meet some filter.
            # - If no filter exists, then the rule is applied to all rows.
            if not self._match_to_external_source:
                # This is just an internal update to a WG results file.
                for i, row in enumerate(wg_results.data):

                    # Do we have a filter?
                    if self.filter_rows is None:
                        # Then we assume this applies to all rows.
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
                                    value = eval(str(evaluable), env)
                                    del env["row"]
                            except:
                                logger.exception("Exception evaluating column "
                                    "value for {0} from {1} in rule {2} on row "
                                    "{3} (index {4}) in working group {5} of "
                                    "{6}:".format(
                                        column, evaluable, self, i + 1, i, wg,
                                        data_release))
                                exceptions[wg] += 1
                                if debug:
                                    raise

                                # Move onto the next column.
                                continue

                            old_values[column] = row["TO_{}".format(column)]
                            new_values[column] = value
                            #wg_results.data[column][i] = value

                        # Mark this row to be updated
                        update_rows.append((i, new_values))
                        logger.debug("Rule {0} has updated row {1} (index {2}) "
                            "in working group {3} of {4}:".format(self, i + 1,
                                i, wg, data_release))

                        for k, old_value in old_values.iteritems():
                            logger.debug("\t{0} updated from {1} to {2}".format(
                                k, str(old_value).strip(), new_values[k]))

                        rows[wg] += 1

                logger.info("{0} rows updated in {1} results by rule {2}"\
                    .format(rows[wg], wg, self))

            else:
                # If we do need to match to an external source:
                # - If the external source is a filename then we should load it
                # - If the external source is not a filename, then we assume it
                #   is a WG and we should reference that table
                # - We should join the tables by the required columns
                # - Filter the rows from the matched table
                # - Update the columns in those rows accordingly.

                # Join the table by the columns
                if self.match_by is None:
                    logger.debug("No columns specified for rule {0} to match "
                        "{1}, so defaulting to CNAME".format(
                            self, self.apply_from))

                match_by = self.match_by if self.match_by is not None \
                    else ["CNAME"]

                # Check for uniqueness?
                unique_entries = unique_table(wg_results.data, keys=match_by)
                if len(wg_results.data) > len(unique_entries):
                    # Raise an exception?
                    logger.warn("Joining {0} data with data from {1} but the "
                        "{0} data has multiple rows for combinations of {2}"\
                        .format(wg, self.apply_from, ", ".join(match_by)))

                logger.debug("Joining {0} data with {1}".format(wg,
                    self.apply_from))

                if "__TO_INDEX" in wg_results.data.dtype.names:
                    raise RuntimeError("{0} results file cannot contain column "
                        "name '__TO_INDEX' - sorry!".format(wg))

                # Append an index column for the wg_results data
                to_table = wg_results.data.copy()
                to_table.add_column(table.Column(
                    data=np.arange(len(wg_results.data)), name="__TO_INDEX"))

                joined_table = table.join(to_table, apply_from_data,
                    keys=match_by, table_names=["TO", "FROM"],
                    uniq_col_name="{table_name}_{col_name}")

                logger.debug("Joined table of {0} and {1} has {2} rows".format(
                    wg, self.apply_from, len(joined_table)))

                if len(joined_table) == 0:
                    logger.warn("No rows in joined table of {0} and {1}".format(
                        wg, self.apply_from))
                    if debug:
                        raise ValueError("no rows in joined table of {0} and "
                            "{1}".format(wg, self.apply_from))

                # Work on each row in the joined table
                for row in joined_table:

                    index = row["__TO_INDEX"]
                    
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

                    if update_this_row:
                        # If the row passes the filter, then we should update 
                        # the corresponding row in the wg_results table
                        old_values = {}
                        new_values = {}
                        for column, evaluable in self.columns.iteritems():

                            # Evaluate the value
                            try:
                                if hasattr(evaluable, "__call__"):
                                    value = evaluable(row)
                                else:
                                    env["row"] = row
                                    value = eval(str(evaluable), env)
                                    del env["row"]
                            except:
                                logger.exception("Exception evaluating column "
                                    "value for {0} from {1} in rule {2} on row "
                                    "{3} (index {4}) in working group {5} of "
                                    "{6}:".format(
                                        column, evaluable, self, index + 1,
                                        index, wg, data_release))
                                exceptions[wg] += 1
                                if debug:
                                    raise

                                # Move onto the next column.
                                continue

                            old_values[column] = wg_results.data[column][index]
                            new_values[column] = value
                            #wg_results.data[column][index] = value

                        # Mark this row to be updated
                        update_rows.append((index, new_values))
                        logger.debug("Rule {0} has updated row {1} (index {2}) "
                            "in working group {3} of {4}:".format(self,
                                index + 1, index, wg, data_release))

                        for k, old_value in old_values.iteritems():
                            logger.debug("\t{0} updated from {1} to {2}".format(
                                k, str(old_value).strip(), new_values[k]))

                        rows[wg] += 1

                logger.info("{0} rows updated in {1} results by rule {2}"\
                    .format(rows[wg], wg, self))

            # Check if we need to update any data types.
            wg_results.data = self._update_data_types(
                wg_results.data, update_rows)

            # Check for rows being updated multiple times.
            update_rows_count = Counter([_[0] for _ in update_rows])
            if np.any(np.array(update_rows_count.values()) > 1):
                logger.debug("Some rows in {0} are being updated multiple times"
                    " presumably due to multiple cross-matches with {1}:"\
                    .format(wg, self.apply_from))

                for i, count in update_rows_count.items():
                    if 1 >= count: continue
                    logger.debug("\tRow {0} (index {1}) updated {2} times"\
                        .format(i + 1, i, count)) 

            # Apply the updates.
            for index, updates in update_rows:
                for column, value in updates.items():
                    wg_results.data[column][index] = value

            logger.debug("Updates applied to {}".format(wg))

        return (True, rows, exceptions)


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


    def apply(self, data_release, debug=False, **kwargs):
        """
        Apply this rule to a data release.

        :param data_release:
            The working group results.

        :type data_release:
            :class:`homogenisation.release.DataRelease`

        :param debug: [optional]
            Re-raise any exception that occurs while parsing the rule filter.

        :type debug:
            bool
        """

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




def unique_table(input_table, keys=None, silent=False):
    """
    Returns the unique rows of a table.
    Parameters
    ----------
    input_table : `~astropy.table.Table` object or a value that
    will initialize a `~astropy.table.Table` object
        Input table.
    keys : str or list of str
        Name(s) of column(s) used to unique rows.
        Default is to use all columns.
    silent : boolean
        If `True` masked value column(s) are silently removed from
        ``keys``. If `False` an exception is raised when ``keys`` contains
        masked value column(s).
        Default is `False`.
    Returns
    -------
    unique_table : `~astropy.table.Table` object
        Table containing only the unique rays of ``input_table``.
    """

    if keys is None:
        keys = input_table.colnames

    if input_table.masked:
        if isinstance(keys, six.string_types):
            keys = [keys, ]
        for i, key in enumerate(keys):
            if np.any(input_table[key].mask):
                if not silent:
                    raise ValueError("Cannot unique masked value key columns, "
                                     "remove column '{0}' from keys and rerun "
                                     "unique.".format(key))
                del keys[i]
        if len(keys) == 0:
            raise ValueError("No column remained in ``keys``, unique cannot "
                             "work with masked value key columns.")

    grouped_table = input_table.group_by(keys)
    unique_table = grouped_table[grouped_table.groups.indices[:-1]]

    return unique_table
