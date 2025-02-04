function [rho] = JB_spatial_2009(T, h, param)

% Jayaram N. and Baker J.W. (2009). "Correlation model for spatially-
% distributed ground-motion intensities," Earthquake Engineering and 
% Structural Dynamics, 38(15), 1687-1708.
%
% Created by Christophe Loth and Jack Baker, 10/18/2013
%
% Compute the spatial correlation of epsilons for the NGA ground motion 
% models. The function is strictly empirical, fitted over the range the 
% period range 0.01s <= T <= 10s
%
%
% INPUT
%
%   T               = The period of interest. 
%
%   h               = The separation distance between two sites (units of km)
%
%   isVs30clustered = flag for to indicate that Vs30 values are clustered
%                     at the sites of interest (due, e.g., to similar geologic conditions).
%                     Discussion is on page 1700 of the above-cited reference
%
% OUTPUT
%
%   rho             = The predicted correlation coefficient

isVs30clustered = param.isVs30clustered;

% compute range
if T<1
    % If unspecified, assume unclustered Vs30s
    if nargin < 3
        isVs30clustered = 0;
    end
    
    if isVs30clustered==0       % case 1 (equation 17)
        b = 8.5+17.2*T;   
    elseif isVs30clustered==1   % case 2 (equation 18)
        b = 40.7-15.0*T;
    end
elseif T>=1                     % long periods (equation 19)
    b = 22.0+3.7*T;
end

% evaluate exponential function with specified range (equation 20)
rho = exp(-3.*h./b);

end