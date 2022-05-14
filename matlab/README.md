# MATLAB microrobot_library

This is a MATLAB library designed to aid in MEMS microrobot design and layout. Generally, this library can be used for any application requiring the generation of GDSII files directly from MATLAB.  

This repository is built upon (and requires) the `gdsii-toolbox` library, a Octave/MATLAB toolbox capable of generating GDSII files written by Ulf Griesmann. We took this basic library and built additional functions that range in complexity from generating a simple rectangle with MEMS etch holes to generating an entire electrostatic inchworm motor. 

Ulf`s work can be found on his github page here: https://github.com/ulfgri/gdsii-toolbox

Or downloaded directly here: https://sites.google.com/site/ulfgri/numerical/gdsii-toolbox

After installing Ulf`s `gdsii-toolbox`, clone this repository and run the `tutorial.m` script. Make sure both `gdsii-toolbox` and this repository are in your MATLAB path.   

The first version of this library was built by Joey Greenspun using Ulf`s `gdsii-toolbox` version 141. 

## More detailed installation instructions

The following are more detailed installation instructions for use on Windows and MATLAB (at least some of this library has also been known to work on Linux with Octave).

1. Install MATLAB with the curve fitting and symbolic toolboxes (Octave may need its splines, symbolic, control, and signal toolboxes).

2. Download the latest version of `gdsii-toolbox` (say, version 146) as a zipped folder, e.g., "https://github.com/ulfgri/gdsii-toolbox/archive/refs/tags/146.zip" (alternatively, from https://sites.google.com/site/ulfgri/numerical/gdsii-toolbox). Extract this to the folder to folder `gdsii-toolbox-146/` containing `gdsii-toolbox-146/makemex.m`, etc.

3. Open MATLAB and navigate inside the folder `gdsii-toolbox-146/`, then run `makemex` to compile several scripts as described in the `gdsii-toolbox` project README. 
  a. If this doesn't work, you made need to install a c compiler; MATLAB may suggest an option (e.g., MinGW). Make sure this step works before continuing (else hard-to-debug errors may appear later).

4. Once this is complete, move the folder to "C:\Program Files\MATLAB\R2021a\toolbox\local\gdsii-toolbox-146" and add "C:\Program Files\MATLAB\R2021a\toolbox\local\gdsii-toolbox-146" recursively (with all its subfolders) to the MATLAB path (click "Home->Environment->Set Path" in the GUI). It should now be possible to, e.g., run `gdsii_units` at the MATLAB command line without error.
  a. If you are getting an error with 'gdsii_units' double check that the path was added "with subfolders".
  
5. Next, download this library (e.g., run "git clone https://github.com/https://github.com/PisterLab/microrobot_library" to get the latest version). Add the `microrobot_library/matlab` folder to the MATLAB path recursively (with all subdirectories) as with `gdsii-toolbox`. It should now be possible to autocomplete and run `tutorial` at the MATLAB command line without error, which will create the file `Tutorial.gds` file in the current MATLAB directory. This file contains a number of generated test structures, and can be opened and edited further with a GDSII editor like [KLayout](https://klayout.de/).
