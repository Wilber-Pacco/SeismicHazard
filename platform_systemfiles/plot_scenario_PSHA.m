function handles=plot_scenario_PSHA(handles)

MapOptions = handles.HazOptions;
ind        = handles.pop_scenario.Value;
shakefield = handles.shakefield(ind);
num        = str2double(handles.Znum.String);

delete(findall(handles.ax1,'tag','scenario'));
hyp = xyz2gps(shakefield.geom.hypm,handles.opt.ellipsoid);
gps = shakefield.gpsRA;
switch handles.show_RA.Value
    case 0, VIS='off';
    case 1, VIS='on';
end
patch('parent',handles.ax1,'vertices',gps(:,[2,1]),'faces',1:size(gps,1),'facecolor',[1 1 1]*0.7,'facealpha',0.5,'tag','scenario','visible',VIS);
plot(handles.ax1,hyp(2),hyp(1),'ks','markerfacecolor','r','tag','scenario','visible',VIS);
switch handles.po_sites.Value
    case 0, VIS1='off';
    case 1, VIS1='on';
end

switch handles.po_contours.Value
    case 0, VIS2='off';
    case 1, VIS2='on';
end

switch handles.po_sites.Value+handles.po_contours.Value
    case 0,    VIS3='off';
    otherwise, VIS3='on';
end

% create scenario
Nsites  = size(handles.h.p,1);
Nz      = size(shakefield.mulogIM,1);
val     = handles.pop_field.Value;
II      = (1:Nsites)+Nsites*(val-1);
mulogIM = shakefield.mulogIM(II,:);
L       = shakefield.L(II,:);
if isnan(num)
    Z       = normrnd(0,1,[Nz,1]);
else
    Z       = shakefield.Z(:,num);
end
Y         = exp(mulogIM+L*Z);
handles.Y = Y;

delete(findall(handles.FIGSeismicHazard,'Tag','Colorbar'));
pall={'parula','autumn','bone','colorcube','cool','copper','flag','gray','hot','hsv','jet','lines','pink','prism','spring','summer','white','winter'};
pallet = pall{MapOptions.param(9)};
set(handles.FIGSeismicHazard,'colormap',feval(pallet));

% This piece of code prevents the patches to be generated for paths elements
t      = handles.h.t;
ispath = regexp(t(:,1),'path');
for i=1:length(ispath)
    if isempty(ispath{i}),ispath{i}=0;end
end
ispath=cell2mat(ispath);
t(ispath==1,:)=[];

delete(findall(handles.ax1,'tag','siteplot'));
delete(findall(handles.ax1,'Tag','satext'));
XY      = cell2mat(handles.h.p(:,2:3));

if size(t,1)==0
    scatter(handles.ax1,XY(:,2),XY(:,1),[],Y,'filled','markeredgecolor','k','tag','siteplot','visible',VIS1,...
        'ButtonDownFcn',{@site_click_PSHA;handles;1});
    handles.colorbar=colorbar('peer',handles.ax1,'location','eastoutside','position',[0.94 0.16 0.02 0.65]);
    CYLIM=[0.9*min(Y),1.1*max(Y)];
    handles.colorbar.YLim = CYLIM;
    caxis(handles.ax1,CYLIM);
    handles.colorbar.Visible=VIS3;
    str = handles.pop_field.String{handles.pop_field.Value};
    set(get(handles.colorbar,'Title'),'String',str)
    return
else
    handles.po_contours.Enable='on';
end
% ------------------------------------------------------------------------

ch=findall(handles.ax1,'tag','gmap'); uistack(ch,'bottom');
nt = size(handles.h.t,1);
for i=1:nt
    ch = findall(handles.ax1,'tag',num2str(i));
    delete(ch);
end

ch=findall(handles.ax1,'Tag','satext');delete(ch);
umax  = -inf;
umin  = inf;
label = handles.h.p(:,1);
p     = cell2mat(handles.h.p(:,[3,2]));

if ~isempty(handles.h.shape)
    active = vertcat(handles.h.shape.active);
    active = find(active);
end
ii     = 1;
handles.SaText = text(NaN,NaN,'','parent',handles.ax1,'Tag','satext');
for i=1:size(t,1)
    vptr=regexp(label,t{i});
    for j=1:length(vptr)
        if isempty(vptr{j})
            vptr{j}=0;
        end
    end
    vptr = find(cell2mat(vptr));
    x    = p(vptr,1);
    y    = p(vptr,2);
    u    = Y(vptr);
    F    = scatteredInterpolant(x,y,u,'linear','none');
    handles.TriScatterd{i}=F;
    
    if regexp(t{i,1},'grid')
        conn = t{i,2};
        gps  = [x,y];
        in   = 1:size(gps,1);
    end
    
    if regexp(t{i,1},'shape')
        ind = active(ii);
        xl=handles.h.shape(ind).Lon';
        yl=handles.h.shape(ind).Lat';
        faces = handles.h.shape(ind).faces;
        pv =[xl,yl];
        gps  = zeros(0,2);
        conn = zeros(0,3);
        offset=0;
        for count=1:size(faces,1)
            indface = faces(count,:);
            indface(isnan(indface))=[];
            pvface = pv(indface,:);
            [gps_i,conn_i]=triangulate_maps(pvface,[x,y]);
            gps = [gps;gps_i]; %#ok<AGROW>
            conn = [conn;conn_i+offset]; %#ok<AGROW>
            offset=size(gps,1);
        end
        u = F(gps(:,1),gps(:,2));
        in = inpolygon(gps(:,1),gps(:,2),xl,yl);        
        ii=ii+1;
    end
    
    
    
    shad=patch(...
        'parent',handles.ax1,...
        'vertices',gps,...
        'faces',conn,...
        'facevertexcdata',u,...
        'facecol','interp',...
        'edgecol','none',...
        'linewidth',0.5,...
        'facealpha',0.7,...
        'Tag',num2str(i),...
        'ButtonDownFcn',{@site_click_PSHA,handles,2},...
        'visible',VIS2);
    uistack(shad,'bottom') % move map to bottom (so it doesn't hide previously drawn annotations)
    
    uin = u;
    uin = uin(in);
    umin = min(min(uin),umin);
    umax = max(max(uin),umax);
    
end

caxis([umin umax])
YLIM = [umin,umax];
switch handles.po_sites.Value
    case 0, VIS='off';
    case 1, VIS='on';
end
scatter(handles.ax1,XY(:,2),XY(:,1),[],Y,'filled','markeredgecolor','k','tag','siteplot','visible',VIS1,'ButtonDownFcn',{@site_click_PSHA;handles;1},'visible',VIS);
handles.colorbar=colorbar('peer',handles.ax1,'location','eastoutside','position',[0.94 0.16 0.02 0.65],'ylim',YLIM);
handles.colorbar.Visible=VIS3;
set(get(handles.colorbar,'Title'),'String','Sa(g)')
handles.ax1.ButtonDownFcn={@clear_satxt;handles};

% restores map
h = findall(handles.ax1,'tag','gmap');
if ~isempty(h)
    h.ButtonDownFcn={@clear_satxt;handles};
    uistack(h,'bottom') % move map to bottom (so it doesn't hide previously drawn annotations)
end

function clear_satxt(hObject,eventdata,handles) %#ok<*INUSL,*INUSD>
ch=findall(handles.ax1,'Tag','satext');delete(ch);

