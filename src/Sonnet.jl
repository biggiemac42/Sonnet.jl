# 2016 Andrew J. Keller
module Sonnet

using MATLAB
using PyCall
@pyimport numpy
@pyimport gdspy

export gdspath
export gds2son
export padgeom
export sonnetopen
export sonnetdir
export sonnetsave
export sonnetsaveas

# Get the user's home directory. This will be MATLAB's working path.
@windows_only const WORKING_PATH = ENV["USERPROFILE"]
@unix_only const WORKING_PATH = ENV["HOME"]

# Get the MATLAB engine's path to be somewhere we have write access.
# We choose the home directory.
# Otherwise, SonnetPath() will fail, at least on Windows.
@matlab cd(WORKING_PATH)

# Set up the MATLAB path to include SonnetLab
pathstr = joinpath(WORKING_PATH, "Documents", "MATLAB", "v8.0", "Scripts")
pathstr = normpath(pathstr)
mat"path(path, $pathstr)"

"""
Inspects a given cell in a GDS-II file to see what layer and datatype
combinations are in it.

Returns an iterator over tuples; each tuple is like (layer, datatype)."
"""
function layerinfo(filename, cellname)
    gds = gdspy.GdsImport(filename)
    keys(gds)
    celldict = gds[:cell_dict]
    polydict = celldict[cellname][:get_polygons](by_spec=true)
    keys(polydict)
end

function sonnetlayerfile()

"Path of Sonnet directory."
sonnetdir() = begin
    @matlab (a,b,c) = SonnetPath();
    @mget b
    normpath(strip(b[1],'\"'))
end

"Path to gds executable responsible for geometry conversion."
gdspath() = normpath(joinpath(sonnetdir(), "bin", "gds"))

"""
Given a GDS-II file at `gds_str`, and an output file location `out_str`,
this function will create a Sonnet project with the geometry contained within.

Optional keywords:

- `cell`: specify the cell name you want to extract.
- `subsize`: pass symbols `:min`, `:max`, or `:normal`; or pass a tuple
 specifying the x and y box size. Defaults to `:min`.
"""
function gds2son(gds_str, out_str; cell="", subsize=:min, )
    gds = gdspath()
    cell == "" ? pflag = "" : pflag = "-p$cell"
    oflag = "-o$out_str"

    if isa(subsize, Symbol)
        sflag = "-s$subsize"
    else
        coords = string(subsize[1])*","*string(subsize[2])
        sflag = "-s$coords"
    end

    run(`$gds $pflag $sflag $oflag $gds_str`)
end

"Open the Sonnet project at `filename`. This project is persistent in the
MATLAB engine (no values are returned)."
function sonnetopen(filename)
    normed = normpath(filename)
    mat"proj = SonnetProject($normed)"
    nothing
end

"""
Increases the box size by `xpad` and `ypad`, centering all polygons
with respect to the added padding.

Note however that the metallization is not necessarily centered after this
function is called unless it was centered to begin with.
"""
function padgeom(xpad, ypad)
    xbox, ybox = (mat"proj.xBoxSize()", mat"proj.yBoxSize()")
    xbox += xpad
    ybox += ypad
    mat"""
        proj.changeBoxSize($xbox,$ybox);
        proj.GeometryBlock.LocalOrigin.X=0;
        proj.GeometryBlock.LocalOrigin.Y=$(ybox);
        [ids,polys]=proj.getAllPolygonIds();
        for i = ids
            proj.movePolygonRelativeUsingId(i,$(xpad/2),$(ypad/2));
        end
    """
end

"Equivalent to File → Save"
sonnetsave() = mat"proj.save();"

"Equivalent to File → Save as..."
sonnetsaveas(x) = begin
    y = normpath(x)
    mat"proj.saveAs($y);"
end

end

# module GDS
# using PyCall
# @pyimport numpy
# @pyimport gdspy
#
#
# end
