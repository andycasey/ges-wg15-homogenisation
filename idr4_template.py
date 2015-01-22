# coding: utf-8

""" Template script for the Gaia-ESO Survey iDR4 homogenisation. """

from __future__ import division, print_function

__author__ = "Andy Casey <arc@ast.cam.ac.uk>"

# Standard library.
from glob import glob

import homogenisation


# Create a data release instance.
iDR4 = homogenisation.DataRelease(version="iDR4")

# Load in the working group files, and perform validation checks.
path = "/Users/arc/research/ges/homogenisation/data/*_WG??_Recommended.fits"
wg_recommended_filenames = glob(path)
iDR4.ingest(wg_recommended_filenames, validate=True)

# Create some human-readable rules to deal with (1) stars that match some filter,
# and (2) multiple measurements for a given star.


"""
remove_skymapper_stars:
    action: delete_rows
    apply_to:
        - wg10
        - wg12
        - wg13
        - wg14
    filter_rows:
        - row["OBJECT"].startswith("U_skm_")
"""
delete_skymapper_stars = homogenisation.rules.DeleteRowsRule(
    apply_to=("wg10", "wg11", "wg12", "wg13", "wg14"),
    filter_rows="row['OBJECT'].startswith('U_skm_')")

"""
update_velocity_offset1:
    action: update_columns
    columns:
        - VRAD: row.vrad + 0.33
        - VRAD_OFFSET: 0.33
        - VRAD_OFFSETSOURCE: SOMEWHERE
    filter_rows:
        - some_filter
    apply_to: wg10
"""
update_velocity_offset = homogenisation.rules.UpdateColumnsRule(
    apply_to="WG10", columns={
        "VRAD": "row['VEL'] + 0.33",
        "E_VRAD": 1
    },
    filter_rows="isfinite(row['VEL'])")

raise a


# Update the WG results based on some rules.
iDR4.update_wg_results(Rules)

# Combine the updated WG results based on some rules.
iDR4.combine_wg_results(Rules)



