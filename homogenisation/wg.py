# coding: utf-8

""" Parsing and validating top-level Gaia-ESO Working Group output files. """

from __future__ import division, print_function

__author__ = "Andy Casey <arc@ast.cam.ac.uk>"

# Standard library
import logging
import os
import re

# Third-party
from astropy.io import fits

# Create a logger.
logger = logging.getLogger(__name__)

class WorkingGroupResults(object):
    """
    A class to represent results from a given Gaia-ESO Survey Working Group.
    It is expected that the results from many :class:`WorkingGroupResults`
    objects are combined together to form a :class:`homogenisation.DataRelease`.
    """

    def __init__(self, image, **kwargs):
        self.image = image
        self.wg = _assign_working_group(
            supplied=kwargs.pop("wg", None),
            filename=kwargs.pop("filename", None),
            header=image[0].header.get("NODE1", None))

    @classmethod
    def from_filename(cls, filename, **kwargs):
        """
        Load GES Working Group results from a filename.

        :param filename:
            The FITS filename containing the working group results.

        :type filename:
            str
        """

        wg = kwargs.pop("wg", None)
        image = fits.open(filename, **kwargs)
        return cls(image, filename=filename, wg=wg)


    @classmethod
    def open(cls, *args, **kwargs):
        return cls.from_filename(*args, **kwargs)


    def validate(self):
        raise NotImplementedError("no WG file validation rules implemented yet")

    def update(self, rule):
        raise NotImplementedError

    def update_repeated(self, rule):
        raise NotImplementedError



def _assign_working_group(supplied, filename, header):
    """
    Assign a working group from the given information supplied by the user, the
    filename, and the image header information.
    """

    if filename is not None:
        _ = re.findall("WG[0-9]{2}", os.path.basename(filename))
        filename = _[0] if len(_) > 0 else None

    upperise = lambda x: x if x is None else x.upper().strip()
    filename, header, supplied = map(upperise, (filename, header, supplied))

    if  filename is None and header is None \
    and supplied is None:
        raise ValueError("could not determine working group from filename ({}),"
            "image header (NODE1 on extension 0), and no keyword (wg) was given"
            .format(filename))

    # supplied takes priority, then header then filename
    if supplied is not None:
        wg_assigned = supplied

    else:
        if header is not None:
            wg_assigned = header
        else:
            wg_assigned = filename

    logger.debug("Assigning WG '{0}' for {1} (suppled: {2}, header: {3}, "
        "filename: {4}".format(wg_assigned, filename, supplied,
            header, filename))

    # Make some checks to warn the user.
    if filename is not None and header is not None \
    and filename != header:
        logger.warn("Working group parsed from filename for {0} is {1}, but"
            " NODE1 header on extension 0 is {2}. Assigned WG as {3}"
            .format(filename, filename, header, wg_assigned))

    return wg_assigned
