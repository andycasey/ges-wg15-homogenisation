# coding: utf-8

""" Tests for the homogenisation.release classes and functions. """

from __future__ import division, print_function

__author__ = "Andy Casey <arc@ast.cam.ac.uk>"

# Standard library
import os
import unittest

# Third-party
from astropy.table import Table

# Module-specific
from homogenisation import release


class CreateDataRelease(unittest.TestCase):

    def test_init(self):
        _ = release.DataRelease("iDRX")
        self.assertEqual(_.version, "iDRX")

    def test_no_version_supplied_to_data_release(self):
        self.assertRaises(TypeError, release.DataRelease)

    def test_list_supplied_as_version_to_data_release(self):
        self.assertRaises(TypeError, release.DataRelease, [])

    def test_tuple_supplied_as_version_to_data_release(self):
        self.assertRaises(TypeError, release.DataRelease, ())

    def test_bool_supplied_as_version_to_data_release(self):
        self.assertRaises(TypeError, release.DataRelease, False)
        self.assertRaises(TypeError, release.DataRelease, True)


class BadIngestToDataRelease(unittest.TestCase):

    def test_single_filename_given(self):
        _ = release.DataRelease("iDRX")
        self.assertRaises(TypeError, _.ingest, "filename.fits")

    def test_missing_filenames_given(self):
        _ = release.DataRelease("iDRX")
        self.assertRaises(IOError, _.ingest, ("missing_1.fits", "missing_2.fits"))


class GoodIngestToDataRelease(unittest.TestCase):

    def setUp(self):
        self.filenames = ("temp_WG10.fits", "temp_WG11.fits")
        [os.remove(__) for __ in self.filenames if os.path.exists(__)]

        a = [1, 4, 5]
        b = [2.0, 5.0, 8.2]
        c = ['x', 'y', 'z']
        self.t1 = Table([a, b, c], names=("CNAME", "OBJECT", "SOMETHING"))
        self.t1.write(self.filenames[0])

        a = [2, 10, 5]
        b = [2.0, 5.0, 8.2]
        c = ['x', 'y', 'z']
        self.t2 = Table([a, b, c], names=("CNAME", "OBJECT", "SOMETHING"))
        self.t2.write(self.filenames[1])

    def test_full_ingest(self):
        _ = release.DataRelease("iDRX")
        _.ingest(self.filenames)
        self.assertEqual(_._wg_results[0].data["CNAME"][0], self.t1["CNAME"][0])
        self.assertEqual(_._wg_results[1].data["CNAME"][0], self.t2["CNAME"][0])

    def test_wg_naming(self):
        _ = release.DataRelease("iDRX")
        _.ingest(self.filenames)
        self.assertEqual(_._wg_names, ["WG10", "WG11"])

    def test__wg_access(self):
        _ = release.DataRelease("iDRX")
        _.ingest(self.filenames)
        self.assertEqual(_._wg("WG10").data["CNAME"][0], self.t1["CNAME"][0])
        self.assertEqual(_._wg("WG11").data["CNAME"][0], self.t2["CNAME"][0])

    def tearDown(self):
        [os.remove(__) for __ in self.filenames]
