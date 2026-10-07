# Stuart–Maxwell marginal-homogeneity test

`pharma_stuart_maxwell_test()` tests equality of paired multinomial margins
for square K×K tables with K >= 3.

For the fixed 3×3 reference, the marginal difference is (d=(7,-4,-3)) and

[
V=
\begin{pmatrix}
13 & -10 & -3\\
-10 & 18 & -8\\
-3 & -8 & 11
\end{pmatrix}.
]

Using the first two independent components,

[
X^2=d_*^T V_*^{-1}d_* = \frac{265}{67} \approx 3.9552
]

with 2 degrees of freedom.

Simultaneous row/column permutations preserve the statistic; symmetric tables
have equal margins and statistic zero. This is marginal homogeneity, not symmetry,
agreement, or a transition model.
