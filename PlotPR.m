% Plot Precision-Recall curves
function [p_handle] = PlotPR( p_data, p_plotBaseline, p_plotIntPrecision, p_plotPRBEP )

    if (nargin < 2)
        p_plotBaseline = true;
    end;
    
    if (nargin < 3)
        p_plotIntPrecision = false;
    end;
    
    if (nargin < 4)
        p_plotPRBEP = false;
    end;    
    
    assert(isfield(p_data,'TPRs'),...
        'True Positive Rates (TPRs) are missing');

    assert(isfield(p_data,'PPVs'),...
        'Precision values (PPVs) are missing');    

    if p_plotIntPrecision
        assert(isfield(p_data,'IntPrecision'),...
            'Interpolated Precision Values are missing');
    end

    if p_plotPRBEP
        assert(isfield(p_data,'PRBEP'),...
            'Precision-Recall Breakeven Point is missing');
    end
    
    hold on;
    
    if (p_plotBaseline)
        plot([1 0], [0 1], 'Color', [0.8 0.8 0.8], 'Linewidth', 1);
    end;
    p_handle = plot( p_data.TPRs, p_data.PPVs, 'r', 'linewidth', 3);
    if p_plotIntPrecision
        plot( p_data.TPRs, p_data.IntPrecision, 'b', 'linewidth', 1);
    end        
    if p_plotPRBEP
        plot([0 1], [0 1], 'k:');
        hPRBEP = plot( p_data.PRBEP, p_data.PRBEP, 'ko', 'LineWidth', 3 );
    end
    axis([0 1 0 1]);
	xlabel('Recall (TPR)'); 
    ylabel('Precision (PPV)'); 
    if isfield(p_data,'AUCPR')
        title(['PR curve (AUC-PR: ' sprintf('%5.3f',p_data.AUCPR) ')']);
    else
        title(['PR curve']);
    end
    set(gca, 'box', 'on');
end