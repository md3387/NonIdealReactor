# NonIdealReactor
Reactor network based on NonIdealShockTube.py from Cantera, including several popular kinetic mechanisms in .yaml format
 "MlappNonIdealReactor" - Mitchell D. Hageman October 2024
 PURPOSE:
   * Solve a constant volume, adiabatic, zero-D reactor at thermodynamic conditions for a combustion shock tube experiment.
   * Includes a dropdown with most of the freely available chemical mechanisms. Those mechanisms included in the github repository with this code, in .yaml format.
 PREREQUISITES
   *Must have Cantera installed and mapped correctly (Also requires Python)
   *Start here: https://cantera.org/install/index.html
 INPUTS:
   * Temperature = temperature in test section, typically either shock tube T2 or T5 [K]
   * Pressure = in test section, typically either shock tube P2 or P5 [atm]
   * Mechanism = name of chosen mechanism
       *mechanism file must be in .yaml format
       *mechanism file must be saved in present working directory
       *e.g. 'mech.yaml'  NOTE THE SINGLE QUOTES
   * GasSpec = string defining gases and their mole fractions in test gas mixture
        *e.g.: 'Ar:0.99,O2:0.009,C3H8:0.001'  NOTE THE SINGLE QUOTES
        *Check the "species" block of your mechanism file to ensure that the species are all listed. being listed in the "elements" block doesnt count. Species needs to be listed in species block, and have composition, thermo, and in some cases transport information listed further down
        *Species names should not be case-sensitive. (i.e. Ar and AR should work)
   * filebase = first part of file name, onto which we will append '_cantera.csv'
        *e.g. if filebase= '20240104' the outputs will be written to 20240104_cantera.csv
        *DOUBLE or SINGLE QUOTES work for file base ('20240104' or "20200104" will produce the same result)
 OUTPUTS: Mole Fractions are written to *filebase*_cantera.csv in the present working directory.
   * x(n,:) = moleFraction(real_gas,{Fuel 'HE' 'Ar' 'N2' 'O2'...% Other Reactants
        'CH2O' 'CH' 'CH*' 'CHV' 'SCH' 'CH-S' 'OH' 'OH*' 'OHV' 'SOH' 'OH-S' 'CH3' 'H'...%Ignition Markers
        'H2O' 'CO' 'CO2' 'NO' 'NO2'....% Products
        'C2H4' 'H2' 'CH4' 'C2H2' 'C3H6' 'C3H8' 'IC4H8' 'C4H8-1' 'C4H8-2' 'C6H6' 'C7H8'}); %Hychem Intermediates
        'UserDefinedSpecies'}); %user-defined species. This is a good place to put your fuel and any additional intermediates you're interested in.
  *The species selected for outputinclude:
       -Fuel (User input)
       -Other Reactants (O2 + Inerts)
       -Intermediates commonly used to mark ignition,
       -Standard combustion products, and
       -HyChem Intermediates -see (https://web.stanford.edu/group/haiwanglab/HyChem/pages/approach.html)
       -User Defined Species - additional intermediates of interest - must hard-code this yourself
  *If the chosen mechanism doesn't contain one of the above species, the
   associated column will be filled with zeroes.
  % DEVELOPMENT HISTORY:
   * reactor network based on NonIdealShockTube.py (https://cantera.org/examples/python/reactors/NonIdealShockTube.py.html)
   * Transcribed into MATLAB code and adjusted to output species concentration histories by Mitch Hageman
 VERSION NUMBER:
   * 1.0: October 2024 - initial release
