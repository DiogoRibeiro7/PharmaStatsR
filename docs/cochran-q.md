# Cochran Q test for repeated binary outcomes

`pharma_cochran_q_test()` compares matched binary responses across two or more
conditions. Rows are subjects and columns are conditions; values must be complete
0/1 observations.

For the fixed 6×3 reference, condition totals are ((4,3,1)), subject totals
are ((3,2,1,1,1,0)), and the grand total is 8. The formula gives

[
Q = rac{28}{8}=3.5
]

with 2 degrees of freedom.

Condition permutation leaves Q unchanged. Identical conditions give Q=0 and p=1.
With exactly two conditions, Q equals the uncorrected McNemar statistic.

This is an omnibus matched-binary test; it does not identify pairwise differences,
handle missing repeated observations, or provide multiplicity-adjusted post-hoc inference.
