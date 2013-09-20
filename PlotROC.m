% Plot ROC curves
function [p_handle] = PlotROC( p_data, p_plotBaseline )

    assert(isfield(p_data,'TPRs'),...
        'True Positive Rates (TPRs) are missing');

    assert(isfield(p_data,'FPRs'),...
        'False Positive Rates (FPRs) are missing');    
    
    if (nargin < 2)
        p_plotBaseline = true;        
    end;    
    
    hold on;
    p_handle = plot( p_data.FPRs(p_data.ndxUnique), p_data.TPRs(p_data.ndxUnique), 'r', 'linewidth', 3);
    if (p_plotBaseline) 
        plot([0 1], [0 1], 'Color', [0.8 0.8 0.8], 'Linewidth', 1); 
    end;
    axis([0 1 0 1]);
	xlabel('False Positive Rate'); 
    ylabel('True Positive Rate'); 
    if isfield(p_data,'AUCROC')
        title(['ROC curve (AUC: ' sprintf('%5.3f',p_data.AUCROC) ')']);
    else
        title(['ROC curve']);
    end
    set(gca, 'box', 'on');
end