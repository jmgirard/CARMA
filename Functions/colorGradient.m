function [im]=colorGradient(c1,c2,height,width)
%COLORGRADIENT Create custom color gradient image
% Modified from code by Jose Maria Garcia-Valdecasas Bernal
% http://www.mathworks.com/matlabcentral/fileexchange/31524

%determine increment step for each color channel.
dr=(c2(1)-c1(1))/(height);
dg=(c2(2)-c1(2))/(height);
db=(c2(3)-c1(3))/(height);

%initialize gradient matrix.
r=[]; g=[]; b=[];

%for each color step, increase/reduce the value of Intensity data.
for j=1:height
    r=[r;repmat(c1(1)+dr*(j-1),1,width)];
    g=[g;repmat(c1(2)+dg*(j-1),1,width)];
    b=[b;repmat(c1(3)+db*(j-1),1,width)];
end

%merge R G B matrix and obtain our image.
im=cat(3,r,g,b);