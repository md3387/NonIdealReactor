function[] = MlappNonIdealReactor(Temperature,Pressure,GasSpec,filebase)
% "MlappNonIdealReactor" - Mitchell D. Hageman October 2024
% PURPOSE:
%   * Solve a constant volume, adiabatic, zero-D reactor at thermodynamic conditions for a combustion shock tube experiment.
%   * Includes a dropdown with most of the freely available chemical mechanisms. Those mechanisms included in the github repository with this code, in .yaml format.
% PREREQUISITES
%   *Must have Cantera installed and mapped correctly (Also requires Python)
%   *Start here: https://cantera.org/install/index.html
% INPUTS:
%   * Temperature = temperature in test section, typically either shock tube T2 or T5 [K]
%   * Pressure = in test section, typically either shock tube P2 or P5 [atm]
%   * Mechanism = name of chosen mechanism
%       *mechanism file must be in .yaml format
%       *mechanism file must be saved in present working directory
%       *e.g. 'mech.yaml'  NOTE THE SINGLE QUOTES
%   * GasSpec = string defining gases and their mole fractions in test gas mixture
%        *e.g.: 'Ar:0.99,O2:0.009,C3H8:0.001'  NOTE THE SINGLE QUOTES
%        *Check the "species" block of your mechanism file to ensure that the species are all listed. being listed in the "elements" block doesnt count. Species needs to be listed in species block, and have composition, thermo, and in some cases transport information listed further down
%        *Species names should not be case-sensitive. (i.e. Ar and AR should work)
%   * filebase = first part of file name, onto which we will append '_cantera.csv'
%        *e.g. if filebase= '20240104' the outputs will be written to 20240104_cantera.csv
%        *DOUBLE or SINGLE QUOTES work for file base ('20240104' or "20200104" will produce the same result)
% OUTPUTS: Mole Fractions are written to *filebase*_cantera.csv in the present working directory.
%   * x(n,:) = moleFraction(real_gas,{Fuel 'HE' 'Ar' 'N2' 'O2'...% Other Reactants
%        'CH2O' 'CH' 'CH*' 'CHV' 'SCH' 'CH-S' 'OH' 'OH*' 'OHV' 'SOH' 'OH-S' 'CH3' 'H'...%Ignition Markers
%        'H2O' 'CO' 'CO2' 'NO' 'NO2'....% Products
%        'C2H4' 'H2' 'CH4' 'C2H2' 'C3H6' 'C3H8' 'IC4H8' 'C4H8-1' 'C4H8-2' 'C6H6' 'C7H8'}); %Hychem Intermediates
%        'UserDefinedSpecies'}); %user-defined species. This is a good place to put your fuel and any additional intermediates you're interested in.
%  *The species selected for outputinclude:
%       -Fuel (User input)
%       -Other Reactants (O2 + Inerts)
%       -Intermediates commonly used to mark ignition,
%       -Standard combustion products, and
%       -HyChem Intermediates -see (https://web.stanford.edu/group/haiwanglab/HyChem/pages/approach.html)
%       -User Defined Species - additional intermediates of interest - must hard-code this yourself
%  *If the chosen mechanism doesn't contain one of the above species, the
%   associated column will be filled with zeroes.
%  % DEVELOPMENT HISTORY:
%   * reactor network based on NonIdealShockTube.py (https://cantera.org/examples/python/reactors/NonIdealShockTube.py.html)
%   * Transcribed into MATLAB code and adjusted to output species concentration histories by Mitch Hageman
% VERSION NUMBER:
%   * 1.0: October 2024 - initial release
tic
%% Get User Inputs.
%Create UI figure
fig = uifigure('Name', 'Mechanism Details', 'Position', [500, 300, 500, 300]);
% Labels and input fields
% Label and input for "Simulation Time"
uilabel(fig, 'Position', [20, 240, 150, 22], 'Text', 'Simulation Time [s]:');
simTimeInput = uieditfield(fig, 'numeric', 'Position', [200, 240, 150, 22], 'Value', 0.003);
% Label and input for "Time Step"
uilabel(fig, 'Position', [20, 200, 150, 22], 'Text', 'Time Step [s]:');
timeStepInput = uieditfield(fig, 'numeric', 'Position', [200, 200, 150, 22], 'Value', 0.0000015);
% Label and input for "Fuel"
uilabel(fig, 'Position', [20, 160, 150, 22], 'Text', 'Fuel (as defined in the Mechanism file)');
FuelInput = uieditfield(fig, 'text', 'Position', [200, 160, 150, 22], 'Value', '');
% Dropdown menu for Mechanism
dropdown = uidropdown(fig, ...
    'Position', [20, 120, 150, 22], ... % [x, y, width, height]
    'Items', {'gri30.yaml', 'gri30.yaml', 'gri30_ion.yaml', 'airNASA9.yaml','curranC8H18.yaml','nDodecane_Reitz.yaml',...
    'Decalin_mmc3mech.yaml','Decalin_mmc3mech_with_Chemi.yaml','Decalin-skeletal.yaml','Decalin-skeletal_with_Chemi_2.yaml',...
    'HyChem_A1highT.yaml','HyChem_A1NTC.yaml','HyChem_A1NTC.yaml','HyChem_A2highT.yaml','HyChem_A2NOx.yaml','HyChem_A2NOx_skeletal.yaml',...
    'HyChem_A2NTC.yaml','HyChem_A2NTC_skeletal.yaml','HyChem_A2NTCfast.yaml','HyChem_A2NTCfast_ske.yaml','HyChem_A2NTCslow.yaml','HyChem_A2skeletal.yaml'...
    'HyChem_A3highT.yaml','HyChem_A3NTC.yaml','HyChem_A3NTC.yaml','HyChem_A3skeletal.yaml','HyChem_C1A2highT.yaml','HyChem_C1A2NOx_skeletal.yaml','HyChem_C1A2skeletal.yaml'...
    'HyChem_C1highT.yaml','HyChem_C1NOx_skeletal.yaml','HyChem_C1skeletal.yaml','HyChem_C5highT.yaml','HyChem_C5skeletal.yaml','HyChem_JP10highT.yaml',...
    'HyChem_JP10skeletal.yaml','HyChem_R2highT.yaml','HyChem_R2NOx_skeletal.yaml','HyChem_R2skeletal.yaml','HyChem_ShellA_full.yaml','HyChem_ShellA_highTonly',...
    'HyChem_ShellA_skeletal.yaml','HyChem_ShellD_full.yaml','HyChem_ShellD_highTonly.yaml'}, ...
    'Value', 'gri30.yaml');% Default selected value
% Add a Submit button
submitButton = uibutton(fig, 'Position', [150, 80, 100, 30], 'Text', 'Submit', ...
    'ButtonPushedFcn', @(btn, event) uiresume(fig));
uiwait(fig);
% Retrieve the inputs
SimulationTime = simTimeInput.Value;
dt = timeStepInput.Value;
Fuel = FuelInput.Value;
Mechanism = dropdown.Value;
% Close the UI
close(fig);

%% Define the thermodynamic state based on available user inputs
reactorPressure = Pressure * 101325.0;  %[Pa] convert atm to Pascals
real_gas = Solution(Mechanism);
try  %If all required inputs are provided, and everything in GasSpec is listed in the chosen mechanism
    set(real_gas,'T',Temperature,'P',reactorPressure,'X',GasSpec)
catch %If part of GasSpec isn't recognized
    % (ex: 'C8H18','IXC8H18, IC8H18, 'iso-octane', and 'isooctane' are all possible entries for iso-octane in a mechanism.
    UserPrompt={'Cantera did not recognize one of your components. Check the "species" block of your mechanism file to make sure your names match, Then change the GasSpec string below. Note: being listed in the "elements" block doesnt count. Species needs to be listed in species block, and have composition, thermo, and in some cases transport information listed further down.'};
    Promptdefault = {GasSpec};
    GasSpec = inputdlg(UserPrompt,'Input',1,Promptdefault);
    set(real_gas,'T',Temperature,'P',reactorPressure,'X',GasSpec)
end

%% Create a reactor object
r = Reactor(real_gas); %for ideal gas try <r = IdealGasReactor(real_gas);>
reactorNetwork = ReactorNet({r});
%timeHistory_RG = SolutionArray(real_gas, 't'); %SolutionArray works in Python, but not Matlab. check against python solution.
%% Initialize loop variables
%dt=str2double(char(UserInput(2))); %dt = step(reactorNetwork); %Results in really tiny steps and takes forever. sure seems like python is faster. %dt = 0.0000015; %[s?] Results in way fewer steps, but it's arbitrary. check against python method.
t = 0;
nsteps=SimulationTime/dt; %[-] number of simulation steps
for n=1:nsteps
    t = t + dt;
    advance(reactorNetwork, t)
    tim(n) = time(reactorNetwork);
    temp(n) = temperature(r);
    x(n,:) = moleFraction(real_gas,{Fuel 'HE' 'AR' 'N2' 'O2'...%Reactants
        'CH2O' 'CH' 'CH*' 'CHV' 'SCH' 'CH-S' 'OH' 'OH*' 'OHV' 'SOH' 'OH-S' 'CH3' 'H'...%Ignition Markers
        'H2O' 'CO' 'CO2' 'NO' 'NO2'....%Products
        'C2H4' 'H2' 'CH4' 'C2H2' 'C3H6' 'C3H8' 'IC4H8' 'C4H8-1' 'C4H8-2' 'C6H6' 'C7H8'...%Hychem Intermediate
        'User_Defined_Species'}); %user-defined species. This is a good place to put your fuel and any additional intermediates you're interested in.
    %Don't forget to enter the 'UserDefinedSpecies in the 'titles' block too.
end

%%Write output file
filename = strcat(filebase,'_cantera.csv'); %This should write to PWD.
titles = {'time' ... %[s?]
    Fuel 'HE' 'AR' 'N2' 'O2' ...%Reactants
    'CH2O' 'CH' 'CH*-radical' 'CHV-radical' 'SCH-radical' 'CH-S-radical' 'OH' 'OH*-radical' 'OHV-radical' 'SOH-radical' 'OH-S-radical' 'CH3' 'H'...%Ignition Markers
    'H2O' 'CO' 'CO2' 'NO' 'NO2'...%Products
    'Ethylene C2H4' 'Hydrogen H2' 'Methane CH4' 'acetylene C2H2' 'Propene C3H6' 'Propane C3H8' 'iso-Butene IC4H8'...%HyChem Intermediates
    '1-butene C4H8-1' '2-Butene C4H8-2' 'Benzene C6H6' 'Toluene C7H8'...
    'User_Defined_Species'}; %user-defined species. This is a good place to put your fuel and any additional intermediates you're interested in.
data = [tim',x];
table=array2table(data,'VariableNames',titles);
writetable(table,filename);

toc
