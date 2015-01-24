
# Rules that we need to implement:
# Add RA, DEC, VEL from some outside file for the WG10 HR15N setup

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

"""
update_wg10_hr15_velocities:
# This rule assumes that the apply_from filename has the data in extension 0 and
# has the required columns in `COLUMNS` and `MATCH_BY`
    action: update_columns
    columns:
        - VRAD
        - VRAD_OFFSET
        - VRAD_OFFSETSOURCE
    match_by:                   # default
        - CNAME                 # default
        - SETUP
    apply_from: filename.fits  # zeroth extension assumed
    apply_to: wg10

# Steps:
# 1) load all from filename
# 2) for each row in apply_to, find corresponding match by cname + setup in filename
# 3) update the `columns` for those matches (if no matches, just warn)
"""

# Remove benchmark stars from sample
"""
remove_benchmarks:
    action: delete_rows
    apply_to:
        - wg10
        - wg12
        - wg13
        - wg14
    filter_rows:
        - row.cname in benchmarks
"""

# Propagate all WG14 flags to the other WG files. Join w/ existing flags?
"""
update_flags_from_wg14:
    action: update_columns
    columns:
        - FLAGS: row_from.flags + '|' + row_to.flags
    match_by:
        - CNAME
        - SETUP
    apply_from: wg14
    apply_to:
        - wg10
        - wg11
        - wg12
        - wg13
        - wg14 
"""

# Move REMARK 1015B and 1015C flags to PECULI column in WG14
"""
update_remarks_to_flags:
    action: update_columns
    columns:
        - peculi: 1015B
        - remark: 
    filter_rows:
        - "1015B" in row.remark
    apply_to: wg14
"""
"""
update_remarks_to_flags2:
    action: update_columns
    columns:
        - peculi: 1015C
        - remark: 
    filter_rows:
        - "1015C" in row.remark
    apply_to: wg14
"""


# Remove abundances for benchmark stars .... in WG11?
"""
remove_benchmark_abundances:
    action: update_columns
    columns:
        - ABUND_1: 
        ...
    filter_rows:
        - row.cname in benchmarks
    apply_to: wg11
"""

# Update VRAD, VRAD_OFFSET, VRAD_OFFSETSOURCE for some filteredrows in a WG file
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

# Update target names like 'Br81/XXX' to be 'Br81'
"""
rename_target_br81:
    action: update_columns
    columns:
        - TARGET: Br81
    filter_rows:
        - row.target.startswith("Br/")
    apply_to:
        - wg10
        - wg11
        - wg12
        - wg13
        - wg14
"""

# Remove MH values from some WGs by row
# --> easy

# Remove SkyMapper stars
"""
remove_skymapper_stars:
    action: delete_rows
    apply_to:
        - wg10
        - wg12
        - wg13
        - wg14
    filter_rows:
<<<<<<< HEAD
        - row["OBJECT"].startswith("U_skm_")
=======
        - row.target.startswith("SkM")
>>>>>>> 81549769b8af501b512126bbd2303d8ad33c53eb
"""

# Update stars in a table that are also in other tables?
# Apply WG10/WG11 correction for stars that are not in other WG tables
"""
apply_feh_correction_wg10_setup:
    action: update_columns
    columns:
        - mh: row.mh + 0.10
    apply_to: wg10
    filter_by:
        - row.cname not in CNAMES_BY_OTHER_WGS
"""



# OTHER:
# Create a table containing benchmark stars from all WGs
# Create a table containing skymapper stars
# Create tables containing stars common to multiple WGs
# Calculate offsets between VRADs
# Output some statistics: number of UVES/GIRAFFE spectra. Number of UVES/GIRAFFE
#   with good measurements, stars in common between WGs

<<<<<<< HEAD
# CONSOLIDATED OTHER:
# Create tables containing stars common to multiple WGs, allowing some filter.

=======
>>>>>>> 81549769b8af501b512126bbd2303d8ad33c53eb


class Rule(object):
    pass




# Let's just build a class rule to update FLAG data from one WG to another
class UpdateFlagRule(Rule):

    def __init__(self):
        pass


    def update_row(self, row):
        # This should return updated data for the row.

    def filter(self, row):



# In human speak:

# update / append / add / subtract / 
"""
update_tech_flags:
    - action: append_column
    - columns: flag
    - from_wg: WG14
    - to_wg: WG10, WG11, WG12, WG13
    - extra_info:
        - delimiter: |
"""

"""
apply_HR10_velocity_offset:
    - action: add
    - columns: V_RAD
    - wg: wg10
    - filter_rows:
        - row.setup == HR15
    - value: +0.33
"""

"""
apply_HR15_velocity_offset:
    - action: add
    - columns: V_RAD
    - wg: wg10
    - filter:
        - row.setup == HR15
    - value: +0.33
"""

"""
remove_benchmarks:
    - action: delete_row
    - to_wg: WG10, WG12, WG13, WG14
    - filter:
        - row.cname in benchmarks
"""

"""
DuplicateMeasurement_Rules:
    # All of these rules will be applied to the groups of duplicate measurements
    # in each relevant working group
    remove_all_but_highest_snr:
        wgs: WG10, WG11, WG12, WG13, WG14
        sort: SNR
        actions:
            - keep_first
            - remove_rest
"""

"""
CombinationRule
a combinationRule will get results for a single star from all WGs

"""

class CombinationRule(Rule):

    def __call__(self, wg_results):
        # wg_results is a dictionary containing the results from all the 
        # working groups (keys), and their relevant result(s) for a given cname

        # If there are no results from multiple nodes, then there's no problem.
        if len(wg_results) == 1:
            return wg_results.values()[0]

        # is it a calibrator? --> WG11
        # is it a young OC cluster --> WG12. UVES > GIRAFFE
        # is it a field or old OC star? --> WG11
        #  is it a hot OC star? --> WG13
        # Is it in NGC 6705? --> WG10 HR10+21 







#    - apply_to_row: all?
