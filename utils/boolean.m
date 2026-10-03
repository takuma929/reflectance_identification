function b = boolean(x)
% BOOLEAN  Compatibility shim for legacy code.
%   Older MATLAB code in this project used boolean() as an alias for
%   logical(). MATLAB has no built-in boolean(), so this restores it.
b = logical(x);
end
