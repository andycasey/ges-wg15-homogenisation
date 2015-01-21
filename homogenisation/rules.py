# coding: utf-8

""" Rules for updating/combining data from different Gaia-ESO Working Groups """

from __future__ import division, print_function

__author__ = "Andy Casey <arc@ast.cam.ac.uk>"

# Standard library
import logging
import json
import yaml

# Create a logger.
logger = logging.getLogger(__name__)


#create,
#read,
#update
#delete


class Rule(object):

    _default_env = {
        "locals": None,
        "globals": None,
        "__name__": None,
        "__file__": None,
        "__builtins__": None
    }

    @property
    def json(self):
        """ Return the rule in JSON format."""
        return json.dumps(self._reproducible_repr_, indent=2)
        
    @property
    def yaml(self):
        """ Return the rule in YAML format. """
        return yaml.dump(self._reproducible_repr_)

    def apply(self, **kwargs):
        raise RuntimeError("the Rule.apply() function must be overloaded")


class ModificationRule(Rule):
    """
    Inherits from :class:`Rule` just so we can distinguish when rules can be
    applied in practice.
    """

    def _parse_apply_to(self, apply_to):
        if not isinstance(apply_to, (tuple, list)):
            return map(str.upper, apply_to)
        return apply_to.upper()


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
        

    def apply(self, wg_results, **kwargs):
        """
        Apply this rule to the results table from a working group lead.

        :param wg_results:
            The working group results.

        :type wg_results:
            :class:`homogenisation.wg.WorkingGroupResults`
        """

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



# possible actions:
# update_columns, delete_rows
    # update_columns can take columns as a list of dicts (e.g. internal update) or
    # a list of columns where a apply_from + match_by exists.
    # NOTE: A RULE SHOULD NEVER BE ALLOWED TO CHANGE THE CNAME

# requirement for delete_rows action:
# needs apply_to, filter_rows

# requirement for update_columns:
# columns, apply_to, (apply_from + match_by) OR (filter_rows)

# ALL so far need: action, apply_to.
