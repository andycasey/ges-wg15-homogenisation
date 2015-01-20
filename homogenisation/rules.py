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

    @property
    def json(self):
        """ Return the rule in JSON format."""
        return json.dumps(self._reproducible_repr_, indent=2)
        
    @property
    def yaml(self):
        """ Return the rule in YAML format. """
        return yaml.dump(self._reproducible_repr_)



class ModificationRule(Rule):
    """
    Inherits from :class:`Rule` just so we can distinguish when rules can be
    applied in practice.
    """
    pass



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

        self._reproducible_repr_ = {
            "action": "update_columns",
            "apply_to": apply_to,
            "columns": columns
        }
        if apply_from is not None:
            self._reproducible_repr_["apply_from"] = apply_from
        if match_by is not None:
            self._reproducible_repr_["match_by"] = match_by
        if filter_rows is not None:
            self._reproducible_repr_["filter_rows"] = filter_rows

        self.apply_to = apply_to
        self.columns = columns
        self.filter_rows = filter_rows
        self.apply_from = apply_from
        self.match_by = match_by


    @property
    def _match_to_external_source(self):
        """ Do we need to match the rows to an external source? """
        return (self.apply_from is not None and self.match_by is not None)




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

        if not isinstance(apply_to, (tuple, list)):
            apply_to = [apply_to]

        if not hasattr(filter_rows, "__call__"):
            try:
                filter_rows = str(filter_rows)
            except (TypeError, ValueError):
                raise TypeError("filter_rows must be a callable or string")

        self._reproducible_repr_ = {
            "action": "delete_rows",
            "apply_to": apply_to,
            "filter_rows": filter_rows
        }

        self.apply_to, self.filter_rows = apply_to, filter_rows
        



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
