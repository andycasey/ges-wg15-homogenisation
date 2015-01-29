# coding: utf-8

""" Base rule classes for updating/combining data from different Gaia-ESO WGs """

from __future__ import division, print_function

__author__ = "Andy Casey <arc@ast.cam.ac.uk>"
__all__ = ["Rule", "CombinationRule", "DuplicateStarRule", "ModificationRule"]

# Standard library
import logging
import json
import yaml

# Third-party.
import numpy as np

# Create a logger.
logger = logging.getLogger(__name__)

def parse(encoded_rule):
    """
    Create a rule object by parsing an encoded string.

    :param encoded_rule:
        The rule!

    :type encoded_rule:
        dict
    """

    # update_columns, delete_rows
    # 

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

    if not isinstance(encoded_rule, dict):
        raise TypeError("encoded rule is expected to be a dictionary")

    if "action" not in encoded_rule:
        raise ValueError("encoded rule does not contain an action command")

    possible_actions = ("delete_duplicate_rows", "delete_rows", "update_columns")
    action = encoded_rule.action.lower()
    if action not in possible_actions:
        raise ValueError("Action '{0}' is not recognised. Available actions are"
            " {1}".format(", ".join(possible_actions)))

    if "apply_to" not in encoded_rule:
        raise ValueError("encoded rule does not contain an apply_to command")

    # OK, now look for required parameters based on the actions
    if action == "delete_rows":
        # Here we just need a filter_rows, which is required.
        if "filter_rows" not in encoded_rule:
            raise ValueError("encoded rules to delete rows require information "
                "about the filter_rows")

    elif action == "update_columns":
        None

    raise NotImplementedError("soon.jpg")


class Rule(object):
    """ A base class for a Rule to apply to a data release. """

    _default_env = {
        #"locals": None,
        #"globals": None,
        #"__name__": None,
        #"__file__": None,
        #"__builtins__": None,
        # Some numpy functions
        "isfinite": np.isfinite,
        "np": np
    }

    @property
    def json(self):
        """ Return the rule in JSON format."""
        return json.dumps(self._reproducible_repr_, indent=2)
        
    @property
    def yaml(self):
        """ Return the rule in YAML format. """
        return yaml.dump(self._reproducible_repr_)

    def apply(self, data_delease, **kwargs):
        raise RuntimeError("the Rule.apply() function must be overloaded")

    def _parse_apply_to(self, apply_to):
        if isinstance(apply_to, (tuple, list)):
            return map(str.upper, apply_to)
        return [apply_to.upper()]
    
    def _affected_wgs(self, data_release):
        """
        Return a list of working groups in the data release that could be
        affected by this rule.
        """
        return set(data_release._wg_names).intersection(self.apply_to)

class DuplicateStarRule(Rule):
    """
    Inherits from :class:`Rule` just so we can distinguish when rules can be
    applied in practice.
    """

    pass

class ModificationRule(Rule):
    """
    Inherits from :class:`Rule` just so we can distinguish when rules can be
    applied in practice.
    """
    pass
    


class CombinationRule(Rule):
    """
    Inherits from :class:`Rule` just so we can distinguish when rules can be
    applied in practice.
    """
    pass