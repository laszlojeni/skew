function [ ps ] = CalcPerformance( p_labels, p_predLabels, p_posClass, varargin )
%--------------------------------------------------------------------------
%CalcPerformance Compute Threshold-based Performance Scores
%    
%   [ps] = CalcPerformance( p_labels, p_predLabels, p_posClass, ... ) 
%   computes threshold-metrics-based performance scores (Accuracy, 
%   Krippendorff's alpha, Cohen's Kappa, F-Beta, Matthews correlation 
%   coefficient, True Positive Rate, False Positive Rate, Positive 
%   Predictive Value).
%   
%   Vector p_predLabels is a vector of the predicted labels returned by a 
%   classifier. Vector p_labels contains the ground truth class labels and 
%   p_posClass indicates the positive class label. The returned struct (ps) 
%   contains the performance scores.
%
%   With exception of TPR and FPR, performance scores are attenuated by 
%   skewed distributions. 
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
%   [ps] = CalcPerformance( p_labels, p_predLabels, p_posClass, ...
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
%      'All' - Calculates all the performance scores (default). 
%              To speed up calculations is it possible to define only a
%              subset of the performance metrics (see below).
%
%      'TPR' - True Positive Rate (or Recall).
%
%      'FPR' - False Positive Rate.
%
%      'PPV' - Positive Predictive Value (or Precision)
%
%      'Alpha' - Krippendorff's alpha.
%
%      'CohenKappa' - Cohen's Kappa.
%
%      'FBeta' - F_Beta score.
%
%      'F1' - F1 score (Beta == 1).
%
%      'MCC' - Matthews correlation coefficient.
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
    if size(p_predLabels,2) ~= 1
        p_predLabels = p_predLabels';
    end
    assert(size(p_predLabels,2)==1,...
        'Array of predicted labels must be a vector');    
    
    % processing parameters
	req.Accuracy = false;
    req.Alpha = false;        
    req.CohenKappa = false;    
    req.FBeta = false;   
    req.MCC = false;
    req.TPR = false;
    req.FPR = false;    
    req.PPV = false;
    req.SetSkew = false;    
    
    if (length(varargin) == 0)
        varargin = [varargin 'All'];
    end
    
	i = 0;
    while i < length(varargin)
        i = i + 1;
        switch upper(varargin{i})
            case 'ALL'
                varargin = [varargin 'Accuracy' 'TPR' 'FPR' 'PPV' 'F1' 'CohenKappa' 'Alpha','MCC'];
            case 'ACCURACY'
                req.Accuracy = true;
            case 'ALPHA'
                req.Alpha = true;                
            case 'COHENKAPPA'
                req.CohenKappa = true;                
            case 'FBETA'
                assert(i < length(varargin),...
                    'Error in FBeta argument (beta value missing)');
                assert(isnumeric(varargin{i+1}),...
                    'Error in FBeta argument (beta must be a numeric value)');
                req.FBeta = true;
                i = i + 1;
                parBeta = varargin{i};
            case 'F1'
                req.Accuracy = true;
                varargin = [varargin 'FBeta' 1];
            case 'MCC'
                req.MCC = true;
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
            case 'TPR'
                req.TPR = true;                                
            case 'FPR'
                req.FPR = true;                                
            case 'PPV'
                req.PPV = true;                                                
            otherwise
                error(['unknown parameter: ' varargin{i}]);
        end   
        if (req.SetSkew)&&(i==length(varargin))&&(length(varargin)<=2)
            varargin = [varargin 'All'];
        end        
    end

    % number of instances in p_labels and p_scores should match
    assert(length(p_labels) == length(p_predLabels),...
        'Number of instances in p_labels and p_predLabels should match!');
            
    % confusion matrix
	TP = sum((p_labels == p_posClass)&(p_predLabels == p_posClass));
    FP = sum((p_labels ~= p_posClass)&(p_predLabels == p_posClass));
    TN = sum((p_labels ~= p_posClass)&(p_predLabels ~= p_posClass));
    FN = sum((p_labels == p_posClass)&(p_predLabels ~= p_posClass));
    
    % number of Positive and Negative examples
	numP = TP + FN;
    numN = TN + FP;
    numPredP = TP + FP;
    numPredN = TN + FN;
    numTotal = numP + numN;
    
    % level of skew
    ps.OriginalSkew = numN / numP;    
    
    % changing the skew keeping the TPR and FPR constant
    if req.SetSkew 
        FP = FP * (ps.TargetSkew / ps.OriginalSkew);
        TN = TN * (ps.TargetSkew / ps.OriginalSkew);
        
        % Negative examples after skew
        numN = TN + FP;
        numPredP = TP + FP;
        numPredN = TN + FN;
        numTotal = numP + numN;        
    end    
    
    % Accuracy
    if req.Accuracy
        ps.Accuracy = (TP+TN) / numTotal;
    end    
    
    % True Positive Rate
    if req.TPR
        ps.TPR = TP / numP;
    end

    % False Positive Rates
    if req.FPR
        ps.FPR = FP / numN;
    end

    % PPVs (Positive Predictive Values) aka Precision
    if req.PPV
        ps.PPV = TP / (TP + FP);
    end
    
    % F-Beta
    if req.FBeta
        beta2 = parBeta^2;
        ps.FBeta = (1+beta2) * TP / ((1+beta2)*TP+beta2*FN+FP);
        ps.parBeta = parBeta;
    end

    % Cohen's Kappa
    if req.CohenKappa        
        P_Obs = (TP + TN) / numTotal; % observed agreement
        PRate = numP/numTotal;
        PredPRate = numPredP/numTotal;
        NRate = numN/numTotal;
        PredNRate = numPredN/numTotal;
        P_Chance_Cohen = (PRate*PredPRate + NRate*PredNRate);
        ps.CohenKappa = (P_Obs - P_Chance_Cohen) / (1 - P_Chance_Cohen);
    end
    
    % Krippendorff's alpha
    if req.Alpha
        o_01 = FN+FP;
        n_0 = 2*TP + FN + FP;
        n_1 = 2*TN + FN + FP;
        ps.Alpha = 1 - (2 * numTotal - 1) * (o_01) / (n_0*n_1);         
    end
    
    % Matthews correlation coefficient
    if req.MCC
        ps.MCC = (TP*TN - FP*FN) / sqrt((TP+FP)*(TP+FN)*(TN+FP)*(TN+FN));
    end
    
    
end

