# coding: utf-8

""" Template script for the Gaia-ESO Survey iDR4 homogenisation. """

from __future__ import division, print_function

__author__ = "Andy Casey <arc@ast.cam.ac.uk>"

import homogenisation


# Create a data release instance.
iDR4 = homogenisation.DataRelease(version="iDR4")

# Load in the working group files, and perform validation checks.
iDR4.ingest(wg_recommended_filenames, validate=True)

# Create some human-readable rules to deal with (1) stars that match some filter,
# and (2) multiple measurements for a given star.




# Update the WG results based on some rules.
iDR4.update_wg_results(Rules)

# Combine the updated WG results based on some rules.
iDR4.combine_wg_results(Rules)



