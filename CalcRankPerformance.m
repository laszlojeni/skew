function [ ps ] = CalcRankPerformance( p_labels, p_scores, p_posClass, varargin )
%--------------------------------------------------------------------------
%CalcRankPerformance Compute Rank-based Performance Scores
%    
%   [ps] = CalcRankPerformance( p_labels, p_scores, p_posClass, ... ) 
%   computes rank-metrics-based performance scores(Area Under ROC Curve,
%   Area Under Precision-Recall Curve, Precision-Recall Breakeven Point)
%   and performance curves (ROC Curve, Precision-Recall Curve, Interpolated
%   Precision).
%   
%   Vector p_scores is a numeric vector of decision scores returned by a 
%   classifier. Vector p_labels contains the ground truth class labels and 
%   p_posClass indicates the positive class label. The returned struct (ps) 
%   contains the True Positive Rates (or Recall, ps.TPRs), False Positive 
%   Rates (ps.FPRs), Positive Predictive Value (or Precision, ps.PPVs), 
%   Interpolated precision (ps.IntPrecision), Area Under ROC Curve value 
%   (ps.AUCROC), Area Under Precision-Recall Curve value (ps.AUCPR) and the
%   Precision-Recall Breakeven Point (ps.PRBEP).
%
%   With exception of area under the ROC curve, performance scores are 
%   attenuated by skewed distributions. 
%
%                    # of negative instances
%   Def.:   skew =  -------------------------
%                    # of positive instances
%
%   Skew is a critical factor in evaluating performance metrics. To avoid 
%   or minimize skew-biased estimates of performance, is it possible to
%   normalize the performance scores to a given degree of skew by the
%   'SetSkew', skewValue parameter name/value pair:
%
%   [ps] = CalcRankPerformance( p_labels, p_scores, p_posClass, ...
%           'SetSkew', 1 );
%
%   For more details on the effect of skew, see
%      L. A. Jeni, J. F. Cohn and F. De la Torre. 2013. Facing imbalanced 
%      data - recommendations for the use of performance metrics.
%      Affective Computing and Intelligent Interaction (ACII 2013)
%      http://www.pitt.edu/~jeffcohn/skew/PID2829477.pdf
%
%   Possible parameters:
%
%      'SetSkew' - Specifies the target degree of skew. The value must be 
%                  greater than 0. Skew == 1 represents a fully balanced
%                  dataset.
%
%      'All' - Calculates all the performance curves and scores (default). 
%              To speed up calculations is it possible to define only a
%              subset of the performance metrics (see below).
%
%      'TPRs' - True Positive Rates (or Recall).
%
%      'FPRs' - False Positive Rates.
%
%      'PPVs' - Positive Predictive Value (or Precision)
%
%      'IntPrecision' - Interpolated Precision. 
%
%      'AUCROC' - Area Under ROC Curve.
%
%      'AUCPR' - Area Under Precision-Recall Curve.
%
%      'PRBEP' - Precision-Recall Breakeven Point.debris

%
%   The ROC implementation is a vectorized version of Fawcett's algorithm
%   described in:
%      Tom Fawcett. 2006. An introduction to ROC analysis. Pattern Recogn. 
%      Lett. 27, 8 (June 2006), 861-874. DOI=10.1016/j.patrec.2005.10.010 
%      http://dx.doi.org/10.1016/j.patrec.2005.10.010%   
%
%   Author: Laszlo A. Jeni (laszlo.jeni@ieee.org), 2013
%--------------------------------------------------------------------------

    % check if the parameters are in a correct format
    if size(p_labels,2) ~= 1
        p_labels = p_labels';
    end
    assert(size(p_labels,2)==1,...
        'Array of labels must be a vector');

    % check if the parameters are in a correct format
    if size(p_scores,2) ~= 1
        p_scores = p_scores';
    end
    assert(size(p_scores,2)==1,...
        'Array of scores must be a vector');    
    
    % processing parameters
	req.TPRs = false;
    req.FPRs = false;   
    req.AUCROC = false;
    req.AUCPR = false;
    req.PRBEP = false;    
    req.PPVs = false;
    req.IntPrecision = false;    
    req.SetSkew = false;    
    
    if (length(varargin) == 0)
        varargin = [varargin 'All'];
    end
    
	i = 0;
    while i < length(varargin)
        i = i + 1;
        switch upper(varargin{i})
            case 'ALL'
                varargin = [varargin 'AUCPR' 'AUCROC' 'INTPRECISION' 'PRBEP'];
            case 'AUCPR'
                req.AUCPR = true;
                varargin = [varargin 'TPRs' 'PPVs'];
            case 'AUCROC'
                req.AUCROC = true;
                varargin = [varargin 'TPRs' 'FPRs'];
            case 'FPRS'
                req.FPRs = true;
            case 'INTPRECISION'
                req.IntPrecision = true;
                varargin = [varargin 'PPVs'];
            case 'PRBEP'
                req.PRBEP = true;
                varargin = [varargin 'TPRs' 'PPVs'];
            case 'PPVS'
                req.PPVs = true;
            case 'SETSKEW'
                assert(i < length(varargin),...
                    'Error in SetSkew argument (target skew value missing)');
                assert(isnumeric(varargin{i+1}),...
                    'Error in SetSkew argument (target skew must be a numeric value)');
                assert((varargin{i+1} > 0),...
                    'Error in SetSkew argument (target skew must be greater than 0)');
                req.SetSkew = true;
                i = i + 1;
                ps.TargetSkew = varargin{i};
            case 'TPRS'
                req.TPRs = true;
            otherwise
                error(['unknown parameter: ' varargin{i}]);
        end     
        if (req.SetSkew)&&(i==length(varargin))&&(length(varargin)<=2)
            varargin = [varargin 'All'];
        end
    end

    % number of instances in p_labels and p_scores should match
    assert(length(p_labels) == length(p_scores),...
        'Number of instances in p_labels and p_scores should match!');
    
    % sorting the scores and labels in a descending order
	[srtScores,ndxDesc] = sort(p_scores, 'descend');
    srtLabels = p_labels(ndxDesc);

    % number of Positive and Negative examples
	numP = sum(srtLabels == p_posClass);
    numN = length(srtLabels) - numP;
    assert((numP > 0)&&(numN > 0),...
        'Less than two classes are found in p_labels!');  
   
    % level of skew
    ps.OriginalSkew = numN / numP;
    ps.Thresholds = [Inf; srtScores];

    % correction of the equally scored instances 
    [~,ps.ndxUnique] = unique(ps.Thresholds,'last');        
    ps.ndxUnique = flipud(ps.ndxUnique);
    
    % confusion matrix values over all thresholds
	TPs = [0; cumsum(srtLabels == p_posClass)];
    FPs = [0; cumsum(srtLabels ~= p_posClass)];
    TNs = numN - FPs;
    FNs = numP - TPs;
    
    % changing the skew keeping the TPR and FPR constant
    if req.SetSkew 
        FPs = FPs * (ps.TargetSkew / ps.OriginalSkew);
        TNs = TNs * (ps.TargetSkew / ps.OriginalSkew);
        numN = numN * (ps.TargetSkew / ps.OriginalSkew);
    end
    
    % True Positive Rates
    if req.TPRs
        ps.TPRs = TPs / numP;
    end
    
    % False Positive Rates
    if req.FPRs
        ps.FPRs = FPs / numN;
    end

    % PPVs (Positive Predictive Values) aka Precision
    if req.PPVs
        ps.PPVs = TPs ./ (TPs + FPs);        
    end
    
    % Interpolated Precision 
    if req.IntPrecision
        ps.IntPrecision = ps.PPVs;
        for i = length(ps.PPVs)-1:-1:1
            ps.IntPrecision(i) = max(ps.PPVs(i),ps.IntPrecision(i+1));
        end
    end

    % Area Under ROC Curve
    if req.AUCROC
        Bases = abs(diff(ps.FPRs(ps.ndxUnique)));
        Heights = (ps.TPRs(ps.ndxUnique(1:end-1))+ps.TPRs(ps.ndxUnique(2:end)))*0.5;
        ps.AUCROC = sum(Bases .* Heights);  
    end

    % Area Under PR Curve (aka Average Precision)
    if req.AUCPR     
        ndx = find(~isnan(ps.PPVs));
        Bases = abs(diff(ps.TPRs(ndx)));
        Heights = (ps.PPVs(ndx(1:end-1))+ps.PPVs(ndx(2:end)))*0.5;
        ps.AUCPR = sum(Bases .* Heights);        
    end    
    
    % Precision-Recall Breakeven Point
    if req.PRBEP
        ndx = find(ps.TPRs > 0);
        [minVal,minInd] = min(abs(ps.TPRs(ndx) - ps.PPVs(ndx)));
        ps.PRBEP = (ps.TPRs(ndx(minInd)) + ps.PPVs(ndx(minInd))) / 2;
    end
    
end

