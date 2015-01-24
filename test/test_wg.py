# coding: utf-8

""" Tests for the homogenisation.wg classes and functions. """

from __future__ import division, print_function

__author__ = "Andy Casey <arc@ast.cam.ac.uk>"

# Standard library
import os
import unittest

# Third-party
from astropy.table import Table

# Module-specific
from homogenisation import wg

class LoadRecommendedResults(unittest.TestCase):

    def test_from_table_no_cname(self):
        a = [1, 4, 5]
        b = [2.0, 5.0, 8.2]
        c = ['x', 'y', 'z']
        t = Table([a, b, c], names=('a', 'b', 'c'))
        # This should load, but log an error.
        wg.RecommendedResults(t, meta={"NODE1": "WG10"})

    def test_from_table_with__to_index(self):
        a = [1, 4, 5]
        b = [2.0, 5.0, 8.2]
        c = ['x', 'y', 'z']
        t = Table([a, b, c], names=('__TO_INDEX', 'b', 'c'))
        self.assertRaises(ValueError, wg.RecommendedResults, t, {"NODE1": "WG10"})

    def test_from_filename(self):
        a = [1, 4, 5]
        b = [2.0, 5.0, 8.2]
        c = ['x', 'y', 'z']
        t = Table([a, b, c], names=('a', 'b', 'c'))

        i, temp_filename = 0, "temp_WG10_{0}.fits"
        while os.path.exists(temp_filename.format(i)):
            i += 1
        t.write(temp_filename)

        wg_results = wg.RecommendedResults.from_filename(temp_filename)
        self.assertEqual(wg_results.wg, "WG10")
        os.remove(temp_filename)

    def test_open(self):
        a = [1, 4, 5]
        b = [2.0, 5.0, 8.2]
        c = ['x', 'y', 'z']
        t = Table([a, b, c], names=('a', 'b', 'c'))

        i, temp_filename = 0, "temp_WG10_{0}.fits"
        while os.path.exists(temp_filename.format(i)):
            i += 1
        t.write(temp_filename)

        wg_results = wg.RecommendedResults.open(temp_filename)
        self.assertEqual(wg_results.wg, "WG10")
        os.remove(temp_filename)


class AssignWG(unittest.TestCase):

    def test_nones(self):
        self.assertRaises(ValueError, wg._assign_working_group, None, None, None)

    def test_no_filename_lower(self):
        self.assertEqual(wg._assign_working_group("wg10", None, "wg11"), "WG10")

    def test_no_filename_upper(self):
        self.assertEqual(wg._assign_working_group("WG11", None, "WG10"), "WG11")

    def test_no_supplied1(self):
        self.assertEqual(wg._assign_working_group(None, "wg1", "wg2"), "WG1")

    def test_no_supplied2(self):
        self.assertEqual(wg._assign_working_group(None, "wg2", "wg2"), "WG2")

    def test_only_filename_wg_too_low(self):
        # Working group name in filename must be >= WG10 (e.g., can't be 'WG9')
        self.assertRaises(ValueError, wg._assign_working_group, None, None, "wg2")

    def test_only_filename_but_no_wg_present(self):
        self.assertRaises(ValueError, wg._assign_working_group, None, None, "sup")

    def test_only_filename_but_wg_is_not_upper(self):
        # And since getting it from the filename is a little dangerous, we only
        # allow uppercase descriptions of the 'WG'.
        self.assertRaises(ValueError, wg._assign_working_group, None, None, "wg12")

    def test_only_filename_but_is_ok(self):
        self.assertEqual(wg._assign_working_group(None, None, "WG10"), "WG10")
        self.assertEqual(wg._assign_working_group(None, None, "WG11"), "WG11")
        self.assertEqual(wg._assign_working_group(None, None, "WG12"), "WG12")
        self.assertEqual(wg._assign_working_group(None, None, "WG13"), "WG13")
        self.assertEqual(wg._assign_working_group(None, None, "WG14"), "WG14")
        self.assertEqual(wg._assign_working_group(None, None, "WG15"), "WG15")

    def test_all_given(self):
        self.assertEqual(wg._assign_working_group("wg1", "wg1", "wg1"), "WG1")

    def test_filename_and_header_disagree(self):
        self.assertEqual(wg._assign_working_group(None, "WG10", "WG11"), "WG10")

