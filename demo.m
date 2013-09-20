clear all;
clc;

%--------------------------------------------------------------------------
% 1st figure: performance graphs
%--------------------------------------------------------------------------
figure(1);
clf;

% generated classifier output
NUM_SAMPLES = 10000;
LABELS = 2*(rand(NUM_SAMPLES,1) < 0.5)-1;
SCORES(LABELS == 1) = randn(sum(LABELS == 1),1) + 1;
SCORES(LABELS == -1) = randn(sum(LABELS == -1),1) - 1;

% calculate performance scores
ps = CalcRankPerformance( LABELS, SCORES, 1, 'All' );

% plot score histogram
subplot(3,2,[1 2]);
    PlotScoreHist( LABELS, SCORES, 1 );

% plot ROC curve
subplot(3,2,3);
PlotROC( ps, true );

% plot PR curve
subplot(3,2,4);
PlotPR( ps, true );

% plot P-R breakeven point
subplot(3,2,[5 6]);
hold on;
hPrec = plot( ps.Thresholds, ps.PPVs, 'b', 'LineWidth', 2 );
hRec = plot( ps.Thresholds, ps.TPRs, 'g', 'LineWidth', 2 );
plot( [ps.Thresholds(2); ps.Thresholds(end)], [ps.PRBEP; ps.PRBEP], 'k:', 'LineWidth', 1 );
xlabel('Thresholds'); 
ylabel('Precision/Recall'); 
title(['Precision-Recall Breakeven Point: ' num2str(ps.PRBEP)]);
legend([hPrec,hRec],'Precision','Recall','Location','Southwest');

%--------------------------------------------------------------------------
% 2nd figure: PR-Curves, PR-BEP in function of skew
%--------------------------------------------------------------------------
figure(2);
clf;

% skew ratio between 1/32x - 32x
SKEW = [1./(33:-1:1) 2:33];
SKEW_LABELS = {'1/33','1/25','1/17','1/9','1','9','17','25','33'};
colors = colormap(jet);
colors = [colors; colors(end,:)];

PRBEPs = zeros(length(SKEW),1);
AUCPRs = zeros(length(SKEW),1);

subplot(1,2,1);
hold on;

for i = 1:length(SKEW)
    ps2 = CalcRankPerformance( LABELS, SCORES, 1, 'SetSkew', SKEW(i), 'All' );
    PRBEPs(i) = ps2.PRBEP;
    AUCPRs(i) = ps2.AUCPR;
    
    hPR = PlotPR(ps2);
    set(hPR,'color',colors(i,:));
end
title('Precision-Recall Curves [color shows the degree of skew]');
hColorBar = colorbar;
set(hColorBar, 'YTickLabel', SKEW(1:4:end));
set(hColorBar, 'YTick', 1:4:length(SKEW));

hSubplot = subplot(1,2,2);
hold on;
hPRBEPs = plot(PRBEPs,'r','LineWidth',3);
hAUCPRs = plot(AUCPRs,'b','LineWidth',3);
legend([hPRBEPs,hAUCPRs],'PR-BEP','AUC-PR');
title('PR-BEP and AUC-PR as the function of skew');
xlabel('Skew');
ylabel('Performance Score'); 
set(gca, 'XLim', [1 length(SKEW)]);
set(gca, 'YLim', [0 1]);
set(gca, 'XTick', [1:8:length(SKEW)]);
set(gca, 'XTickLabel', SKEW_LABELS);
grid on;

%--------------------------------------------------------------------------
% 3rd figure: Threshold-metrics in function of skew
%--------------------------------------------------------------------------
figure(3);
clf;

% ground truth labels (balanced case)
GT_LABELS = [ones(NUM_SAMPLES / 2, 1); -ones(NUM_SAMPLES / 2, 1)];

for i = 0:10
    % performance scores
    ACCs = zeros(length(SKEW),1);
    F1s = zeros(length(SKEW),1);
    KAPPAs = zeros(length(SKEW),1);
    ALPHAs = zeros(length(SKEW),1);
    MCCs = zeros(length(SKEW),1);
    PPVs = zeros(length(SKEW),1);
    
    % generate predicted labels (symmetric confusion matrix)
    N2 = floor(NUM_SAMPLES / 2);
    N = floor((i/10) * N2);
    PRED_LABELS = [ ones(N, 1);...        % TP
                   -ones(N2 - N, 1);...   % FN
                   -ones(N, 1);...        % TN
                    ones(N2 - N, 1)];     % FP  	

    for j = 1:length(SKEW)
        ps3 = CalcPerformance( GT_LABELS, PRED_LABELS, 1, 'SetSkew', SKEW(j), 'All' );
        ACCs(j) = ps3.Accuracy;
        F1s(j) = ps3.FBeta;
        KAPPAs(j) = ps3.CohenKappa;
        ALPHAs(j) = ps3.Alpha;
        MCCs(j) = ps3.MCC;
        PPVs(j) = ps3.PPV;
    end

    % the red line shows the performance of random guessing 
    if i == 5
        colCurve = 'r';
    else
        colCurve = 'b';
    end
    
    subplot(2,3,1);
    hold on;
    plot(ACCs,colCurve,'LineWidth',3);
    xlabel('Skew');
    ylabel('Accuracy'); 
    set(gca, 'XLim', [1 length(SKEW)]);
    set(gca, 'YLim', [0 1]);
    set(gca, 'XTick', [1:8:length(SKEW)]);
    set(gca, 'XTickLabel', SKEW_LABELS);
    grid on;
    
    subplot(2,3,2);
    hold on;
    plot(F1s,colCurve,'LineWidth',3);    
    xlabel('Skew');
    ylabel('F_1 score'); 
    set(gca, 'XLim', [1 length(SKEW)]);
    set(gca, 'YLim', [0 1]);
    set(gca, 'XTick', [1:8:length(SKEW)]);
    set(gca, 'XTickLabel', SKEW_LABELS);
    grid on;

    subplot(2,3,3);
    hold on;
    plot(KAPPAs,colCurve,'LineWidth',3);    
    xlabel('Skew');
    ylabel('Cohen''s Kappa'); 
    set(gca, 'XLim', [1 length(SKEW)]);
    set(gca, 'YLim', [-1 1]);
    set(gca, 'XTick', [1:8:length(SKEW)]);
    set(gca, 'XTickLabel', SKEW_LABELS);
    grid on;

    subplot(2,3,4);
    hold on;
    plot(ALPHAs,colCurve,'LineWidth',3);    
    xlabel('Skew');
    ylabel('Krippendorff''s Alpha'); 
    set(gca, 'XLim', [1 length(SKEW)]);
    set(gca, 'YLim', [-1 1]);
    set(gca, 'XTick', [1:8:length(SKEW)]);
    set(gca, 'XTickLabel', SKEW_LABELS);
    grid on;

    subplot(2,3,5);
    hold on;
    plot(MCCs,colCurve,'LineWidth',3);    
    xlabel('Skew');
    ylabel('Matthews Correlation Coefficient'); 
    set(gca, 'XLim', [1 length(SKEW)]);
    set(gca, 'YLim', [-1 1]);
    set(gca, 'XTick', [1:8:length(SKEW)]);
    set(gca, 'XTickLabel', SKEW_LABELS);
    grid on;

    subplot(2,3,6);
    hold on;
    plot(PPVs,colCurve,'LineWidth',3);    
    xlabel('Skew');
    ylabel('Precision (PPV)'); 
    set(gca, 'XLim', [1 length(SKEW)]);
    set(gca, 'YLim', [0 1]);
    set(gca, 'XTick', [1:8:length(SKEW)]);
    set(gca, 'XTickLabel', SKEW_LABELS);
    grid on;
    
end