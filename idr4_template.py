# coding: utf-8

""" Template script for the Gaia-ESO Survey WG15 iDR4 homogenisation. """

from __future__ import division, print_function

__author__ = "Andy Casey <arc@ast.cam.ac.uk>"

from glob import glob
import homogenisation

# Load the rules.
with open("iDR4_rules.yaml") as fp:
    rules = homogenisation.rules.parse_rules(fp)

# Create a data release instance.
iDR4 = homogenisation.DataRelease(version="iDR4")

# Load in the working group files, and perform validation checks.
path = "/Users/arc/research/ges/homogenisation/data/*_WG??_Recommended.fits"
wg_recommended_filenames = glob(path)
iDR4.ingest(wg_recommended_filenames, validate=True)


# Apply the easy rules.
for rule in rules:
    affected = iDR4.apply_rule(rule)

# There may be combination rules, which are more difficult to put into a single
# file:

# Delete stars (by CNAME) in WG10 that are in WG11
delete_from_wg10_if_in_wg11 = homogenisation.rules.DeleteRowsRule(
    apply_to="WG10", filter_rows="row['CNAME'] in WG11")
delete_from_wg10_if_in_wg11._default_env["WG11"] = iDR4.select("WG11")["CNAME"]

# Join all the rules together.
combination_rules = (delete_from_wg10_if_in_wg11, )

# Apply the combination rules.
for rule in combination_rules:
    affected = iDR4.apply_rule(rule)


raise a