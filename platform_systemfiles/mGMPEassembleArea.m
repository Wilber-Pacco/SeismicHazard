function [param,rate]=mGMPEassembleArea(r0,source,Rmetric,ellipsoid,varargin)

geom = source.geom;
mscl = source.mscl;
gmpe = source.gmpe;
rupt = source.rupt;

M       = mscl.M;
nM      = size(M,1);
rf      = geom.hypm;
nR      = size(rf,1);
if nargin==4
    [iR,iM] = meshgrid(1:nR,1:nM);
else
    iR = 1:nR;
    iM = 1:nM;
end
M       = M(iM(:));
rf      = rf(iR(:),:);

%% EVALUATES RUPTURE AREA AND SOURCE NORMAL VECTOR
if geom.Area>0
    rupArea   = rupRelation(M,0,geom.Area,rupt.RA{1},rupt.RA{2});
    n         = geom.normal(iR(:),:);
    rateM     = mscl.dPm(iM(:));
    rateR     = geom.aream(iR(:))/geom.Area;
    rate      = rateM.*rateR/(rateM'*rateR);
else
    rupArea   = zeros(size(M));
    n         = [];
    rate      = mscl.dPm(iM(:));
end

% this is required if you use NGAWest2 models on non-rectangular sources
rrup  = dist_rrup(r0,rf,rupArea,n);
if Rmetric(2),  rhyp  = dist_rhyp(r0,rf); end
if Rmetric(3),  rjb   = rrup; end
if Rmetric(4),  repi  = rrup; end
if Rmetric(5),  rseis = rrup;end
if Rmetric(6),  rx    = rrup;end
if Rmetric(7),  ry0   = rrup;end
if Rmetric(8),  zhyp  = dist_zhyp(r0,rf,ellipsoid); end
if Rmetric(9),  ztor  = dist_zhyp(r0,rf,ellipsoid); end
if Rmetric(10), zbor  = dist_zhyp(r0,rf,ellipsoid); end
if Rmetric(11), zbot  = dist_zhyp(r0,rf,ellipsoid); end


%% GMM Parameters
usp      = source.gmpe.usp;
Ndepend  = 1;
isfrn    = false;
switch source.gmpe.type
    case 'regular', str_test = func2str(gmpe.handle);
    case 'cond',    str_test = func2str(gmpe.cond.conditioning);
    case 'udm' ,    str_test = 'udm';
    case 'pce' ,    str_test = func2str(gmpe.handle);
    case 'frn'
        Ndepend  = gmpe.usp.Ndepend;
        isfrn    = true;
        funcs    = cell(1,Ndepend);
        IMlist   = cell(1,Ndepend);
        PARAM    = cell(1,Ndepend);
end

for jj=1:Ndepend
    if isfrn
        GMMjj     = sprintf('GMM%i',jj);
        switch source.gmpe.usp.(GMMjj).type
            case 'regular', str_test = func2str(gmpe.usp.(GMMjj).handle);
            case 'cond',    str_test = func2str(gmpe.usp.(GMMjj).cond.conditioning);
            case 'udm',     str_test = func2str(gmpe.usp.(GMMjj).handle);
            case 'pce',     str_test = func2str(gmpe.usp.(GMMjj).handle);
        end
        usp      = gmpe.usp.(GMMjj).usp;
    end
    
    switch str_test
        case 'Arteta2018'
            param   = {M,rhyp,usp.media,usp.region};
        case 'Youngs1997'
            param   = {M,rrup,zhyp,usp.mechanism,usp.media};
        case 'AtkinsonBoore2003'
            param   = {M,rrup,zhyp,usp.mechanism,usp.media,usp.region};
        case 'Zhao2006'
            param   = {M,rrup,zhyp,usp.mechanism,usp.Vs30};
        case 'Mcverry2006'
            param   = {M,rrup,zhyp,usp.mechanism,usp.media,usp.rvol};
        case 'BCHydro2012'
            switch usp.mechanism
                case 'interface'
                    param     = {M,rrup,zhyp,usp.mechanism,usp.region,usp.DeltaC1,usp.Vs30};
                case 'intraslab'
                    param     = {M,rhyp,zhyp,usp.mechanism,usp.region,usp.DeltaC1,usp.Vs30};
            end
        case 'MontalvaBastias2017'
            switch usp.mechanism
                case 'interface'
                    param   = {M,rrup,zhyp,usp.mechanism,usp.region,usp.Vs30};
                case 'intraslab'
                    param   = {M,rhyp,zhyp,usp.mechanism,usp.region,usp.Vs30};
            end
        case 'SiberRisk2019'
            switch usp.mechanism
                case 'interface'
                    param   = {M,rrup,zhyp,usp.mechanism,usp.Vs30};
                case 'intraslab'
                    param   = {M,rhyp,zhyp,usp.mechanism,usp.Vs30};
            end
        case 'Idini2016'
            switch usp.mechanism
                case 'interface'
                    R=rrup; R(M<7.7)=rhyp(M<7.7);
                    param   = {M,R,zhyp,usp.mechanism,usp.spectrum,usp.Vs30};
                case 'intraslab'
                    param   = {M,rhyp,zhyp,usp.mechanism,usp.spectrum,usp.Vs30};
            end
        case 'ContrerasBoroschek2012'
            param     = {M,rrup,zhyp,usp.media};
        case 'Garcia2005'
            param   = {M,rrup,rhyp,zhyp,usp.direction};
        case 'Jaimes2006'
            param   = {M,rrup};
        case 'Jaimes2015'
            param   = {M,rrup,usp.station};
        case 'Jaimes2016'
            param   = {M,rrup};
        case 'GarciaJaimes2017'
            param   = {M,rrup,usp.component};
        case 'Bernal2014'
            param   = {M,rrup,zhyp,usp.mechanism};
        case 'Sadigh1997'
            param   = {M,rrup,usp.mechanism,usp.media};
        case 'AS1997h'
            usp.location = 'footwall';
            param   = {M,rrup,usp.media,usp.mechanism,usp.location,usp.sig};
        case 'Idriss2008_nga'
            param     = {M,rrup,usp.mechanism,usp.Vs30};
        case 'ChiouYoungs2008_nga'
            dip     = geom.dip;
            z1      = exp(28.5-3.82/8*log(usp.Vs30^8+378.8^8));
            param   = {M, rrup, rjb, rx, ztor, dip, z1, usp.mechanism, usp.event, usp.Vs30, usp.Vs30type};
        case 'BooreAtkinson_2008_nga'
            param   = {M,rjb,usp.mechanism,usp.Vs30};
        case 'CampbellBozorgnia_2008_nga'
            dip     = geom.dip;
            param   = {M,rrup, rjb, ztor, dip, usp.mechanism, usp.Vs30, usp.Z25, usp.sigmatype};
        case 'AbrahamsonSilva2008_nga'
            dip     = geom.dip;
            dipvec  = [1 -1]*gps2xyz(source.vertices(1:2,:),ellipsoid);
            W       = norm(dipvec);
            Z10     = Z10_default_AS08_NGA(usp.Vs30);
            param   = {M, rrup, rjb, rx, ztor, dip,W, Z10, usp.Vs30,usp.mechanism,usp.event,usp.Vs30type};
        case 'I_2014_nga'
            param     = {M,rrup,usp.mechanism,usp.Vs30};
        case 'CY_2014_nga'
            dip     = geom.dip;
            param   = {M, rrup, rjb, rx, ztor, dip, usp.mechanism, usp.Z10, usp.Vs30, usp.Vs30type, usp.region};
        case 'BSSA_2014_nga'
            param   = {M, rjb, usp.mechanism, usp.region, usp.BasinDepth, usp.Vs30};
        case 'CB_2014_nga'
            dip     = geom.dip;
            dipvec  = [1 -1]*gps2xyz(source.vertices(1:2,:),ellipsoid);
            W       = norm(dipvec);
            param   = {M, rrup, rjb, rx, W, ztor, zbot, dip, usp.mechanism, usp.HW, usp.Vs30, usp.Z25, zhyp, usp.region};
        case 'ASK_2014_nga'
            dip     = geom.dip;
            dipvec  = [1 -1]*gps2xyz(source.vertices(1:2,:),ellipsoid);
            W       = norm(dipvec);
            param={M, rrup, rjb, rx, ry0, ztor, dip, W, usp.mechanism, usp.event, usp.Z10, usp.Vs30, usp.Vs30type, usp.region};
            
        case 'DW12'
            param = {M,rrup,ups.mechanism,usp.media};
            
        case 'udm'
            var  = gmpe.var;
            txt  = regexp(var.syntax,'\(','split');
            args = regexp(txt{2}(1:end-1),'\,','split');
            args = strtrim(args);
            args(1)  = [];
            param    = cell(1,4+length(args));
            param{1} = str2func(strtrim(txt{1}));
            param{2} = var.vector;
            param{3} = var.residuals;
            for cont=1:length(args)
                f = var.(args{cont});
                if strcmpi(f.tag,'magnitude')
                    param{4+cont}=M;
                end
                
                if strcmpi(f.tag,'distance')
                    fval = find(f.value);
                    switch fval
                        case 1 , param{4+cont}=rrup;
                        case 2 , param{4+cont}=rhyp;
                        case 3 , param{4+cont}=rjb;
                        case 4 , param{4+cont}=repi;
                        case 5 , param{4+cont}=rseis;
                        case 6 , param{4+cont}=rx;
                        case 7 , param{4+cont}=ry0;
                        case 8 , param{4+cont}=zhyp;
                        case 9 , param{4+cont}=rztor;
                        case 10, param{4+cont}=rzbor;
                        case 11, param{4+cont}=rzbot;
                    end
                end
                
                if strcmpi(f.tag,'param')
                    switch f.type
                        case 'string'
                            param{4+cont}=gmpe.usp.(args{cont});
                        case 'double'
                            if isnumeric(gmpe.usp.(args{cont}))
                                param{4+cont}=gmpe.usp.(args{cont});
                            else
                                param{4+cont}=str2double(gmpe.usp.(args{cont}));
                            end
                    end
                end
            end
        case 'PCE_nga'
            dip     = geom.dip;
            W       = source.geom.W;
            param={M, rrup, rjb, rx, ry0, ztor, dip, W, usp.mechanism, usp.event, usp.Z10, usp.Vs30, usp.Vs30type, usp.region};
        case 'PCE_bchydro'
            param     = {M,rrup,usp.Vs30};
    end
    
    if strcmpi(gmpe.type,'cond')
        func    = gmpe.cond.conditioning;
        param   = [{M,rrup,func,usp.mechanism,source.Vs30},param]; %#ok<AGROW>
    end
    
    if isfrn
        funcs {jj}=gmpe.usp.(GMMjj).handle;
        IMlist{jj}=gmpe.usp.(GMMjj).T;
        switch gmpe.usp.(GMMjj).type
            case 'regular'
                PARAM {jj}=param;
            case 'cond'
                PARAM {jj}= [{M,rrup,gmpe.usp.(GMMjj).cond.conditioning,usp.mechanism,source.Vs30},param]; %#ok<AGROW>
            case 'udm'
                PARAM {jj}=param;
            case 'pce'
                PARAM {jj}=param;
        end
        
    end
    
end

if isfrn
    param=[funcs,IMlist,PARAM];
end





