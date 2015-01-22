# coding: utf-8

""" Base rule classes for updating/combining data from different Gaia-ESO WGs """

from __future__ import division, print_function

__author__ = "Andy Casey <arc@ast.cam.ac.uk>"

# Standard library
import logging
import json
import yaml

# Create a logger.
logger = logging.getLogger(__name__)


class Rule(object):
    """ A base class for a Rule to apply to a data release. """

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


class CombinationRule(Rule):
    """
    Inherits from :class:`Rule` just so we can distinguish when rules can be
    applied in practice.
    """
    pass

