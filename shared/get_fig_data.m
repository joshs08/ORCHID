%takes a path to a figure and extracts the xdata and ydata from it (assumes
%one trace)

function  [xdata, ydata] = get_fig_data (path)

fig = openfig (path);

% h = findobj(gca,'Type','line');
% xdata=get(h,'Xdata') ;
% ydata=get(h,'Ydata') ;
% xdata = cell2mat(xdata (3, :));
% ydata = cell2mat(ydata (3, :));

% axObjs = fig.Children;
% dataObjs = axObjs.Children;
% xdata = dataObjs(1).XData;
% ydata = dataObjs(1).YData;
% 
dataObjs = findobj(fig,'-property','YData');
ydata = dataObjs(1).YData;

dataObjs = findobj(fig,'-property','XData');
xdata = dataObjs(1).XData;

close (fig);