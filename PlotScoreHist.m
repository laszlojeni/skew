% Plot Score Histrograms
function [p_handle] = PlotScoreHist( p_labels, p_scores, p_posClass )

    [posN,posX]=hist(p_scores(p_labels == p_posClass),100);
    [negN,negX]=hist(p_scores(p_labels ~= p_posClass),100);

    hist(p_scores(p_labels == p_posClass),50);
    h = findobj(gca,'Type','patch');
    set(h,'facealpha',0.5);
    set(h,'facecolor','r');

    hold on;
    hist(p_scores(p_labels ~= p_posClass),50);
    h = findobj(gca,'Type','patch');
    set(h,'edgecolor','none');
    set(h,'facealpha',0.5);
    
	xlabel('Score'); 
    ylabel('Frequency');
    title('Score Histrograms');
end