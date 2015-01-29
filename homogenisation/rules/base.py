# coding: utf-8

""" Base rule classes for updating/combining data from different Gaia-ESO WGs """

from __future__ import division, print_function

__author__ = "Andy Casey <arc@ast.cam.ac.uk>"
__all__ = ["parse_rule", "parse_rules", "Rule", "CombinationRule",
    "DuplicateStarRule", "ModificationRule"]

# Standard library
import logging
import yaml
from json import dumps

# Third-party.
import numpy as np

# Create a logger.
logger = logging.getLogger(__name__)

def parse_rule(encoded_rule):
    """
    Create a rule object by parsing an encoded string.

    :param encoded_rule:
        The rule!

    :type encoded_rule:
        dict
    """

    if not isinstance(encoded_rule, dict):
        raise TypeError("encoded rule is expected to be a dictionary")
    if "action" not in encoded_rule:
        raise ValueError("encoded rule does not contain an action command")
    if "apply_to" not in encoded_rule:
        raise ValueError("encoded rule does not contain an apply_to command")

    encoded_rule = encoded_rule.copy()
    action = encoded_rule["action"].lower()
    del encoded_rule["action"]

    # OK, now look for required parameters based on the actions
    from modify import DeleteRowsRule, UpdateColumnsRule
    from groups import DeleteDuplicateRowsRule, UpdateDuplicateRowsRule
    classes = {
        "delete_rows": DeleteRowsRule,
        "update_columns": UpdateColumnsRule,
        "delete_duplicate_rows": DeleteDuplicateRowsRule,
        "update_duplicate_rows": UpdateDuplicateRowsRule
    }
    if action not in classes.keys():
        raise ValueError("Action '{0}' is not recognised. Available actions are"
            " {1}".format(", ".join(classes.keys())))
    _class = classes[action]   
    return _class(**encoded_rule)


def parse_rules(fp, n=36):
    """
    Create a list of rules from file contents.

    :param fp:
        A file pointer.
    """

    indent = n * " "
    rules = []
    contents = yaml.load(fp)
    if isinstance(contents, dict):
        logger.warn("File contents returned a dictionary: rules may not be "
            "applied in the order you expect!")
        for rule_name, encoded_rule in contents.items():
            rule = parse_rule(encoded_rule)
            rules.append(rule)
            logger.debug("Created rule {0} ({1}) from contents:\n{2}\n".format(
                rule_name, rule, 
                indent + dumps(encoded_rule, indent=2).replace("\n", "\n" + indent)))
    else:
        for each in contents:
            rule_name = each.keys()[0]
            encoded_rule = each[rule_name]
            
            rule = parse_rule(encoded_rule)
            rules.append(rule)
            logger.debug("Created rule {0} ({1}) from contents:\n{2}\n".format(
                rule_name, rule, 
                indent + dumps(encoded_rule, indent=2).replace("\n", "\n" + indent)))
    return rules


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
        return dumps(self._reproducible_repr_, indent=2)
        
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