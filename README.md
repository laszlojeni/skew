skew
====

Performance Metrics Package for Imbalanced Data

The package provides MATLAB functions to calculate rank-based and threshold-based performance metrics for imbalanced datasets. Imbalanced datasets are frequently found in many applications. In a typical binary 
classiﬁcation problem the imbalance of data can be deﬁned by the skew ratio between the classes:

	skew = negative examples / positive examples

In most cases the vast majority of examples are from one class, but the practitioner is typically interested in the minority (positive) class. With a few exceptions, performance scores are attenuated by skewed distributions. 
Skew is a critical factor in evaluating performance metrics. To avoid or minimize skew-biased estimates of performance, is it possible to normalize the performance scores to a fully balanced set. In these way, classiﬁers can be compared across databases free of confounds introduced by skew.

The package contains the following performance metrics:

- Rank-based Metrics:
	- Area Under ROC Curve
	- Area Under Precision-Recall Curve
	- Interpolated Precision
	- Precision-Recall Breakeven Point

- Threshold metrics:
	- Accuracy
	- Precision
	- Recall
	- F-Beta scores
	- Cohen's Kappa
	- Krippendorff's Alpha
	- Matthews Correlation Coefficient


For more details on the effect of skew, see

L. A. Jeni, J. F. Cohn and F. De la Torre. 2013. 
Facing imbalanced data - recommendations for the use of performance metrics.
Affective Computing and Intelligent Interaction (ACII 2013)
http://www.pitt.edu/~jeffcohn/skew/PID2829477.pdf
