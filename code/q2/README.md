# Question 2: travel costs and routing

`main.R` checks the column names of an available travel log. It skips the check
when the file is absent. The separate `q2a_cost_matrix.R` script builds the
part (a) matrix. By default, it reads
`data/raw/q2/ahmad_travel_logs.csv` when that file exists; otherwise it uses the
clearly labeled synthetic fallback at
`data/synthetic/q2/ahmad_travel_logs.csv`. It writes cleaned rows to
`data/processed/q2/ahmad_travel_logs_filtered.csv` and the matrix and heatmap to
`outputs/q2/`. The prototype is not yet integrated with the runner;
Nearest Neighbour routing remains pending.

For the actual or hidden grading data, place `ahmad_travel_logs.csv` at
`data/raw/q2/ahmad_travel_logs.csv`, then run the matrix script from the project
root:

```powershell
Rscript code/q2/q2a_cost_matrix.R
```

The matrix script also accepts an explicit CSV path:

```powershell
Rscript code/q2/q2a_cost_matrix.R "C:/path/to/ahmad_travel_logs.csv"
```
`Rscript code/run.R q2` currently checks the schema only; it does not run the
matrix calculation.

## Implementation sequence

1. Generate a small, clearly labeled synthetic dataset for local development.
   Store synthetic data separately from the eventual grading input.
2. Validate coordinates, conditions, and travel times using the documented
   schema. Filter the relevant observations for a rainy morning and justify
   anomaly handling, including `NA` and `-1` road closure records.
3. Construct a 10 x 10 cost matrix using each route's 75th percentile valid
   travel time. Assign a documented severe penalty where no valid route history
   remains. Make directionality, missing observations, and diagonal treatment
   explicit; do not assume opposite directions have identical costs.
4. Implement Nearest Neighbour with a deterministic tie rule. Visit every point
   once, return to the start, and calculate the full tour cost.
5. Check behavior on blocked routes, missing route histories, reordered rows,
   and unseen datasets with the same schema. Explain when any penalty edge is
   used in a resulting tour.

The ten point coordinates and CSV schema are fixed assignment inputs. Row
indices, route costs, chosen routes, and results must come from the dataset and
algorithm rather than manual overrides.

The generated filtered CSV contains Rainy Morning rows with listed endpoints
and non-negative, non-missing travel times; a later script can read this
processed file. The synthetic fallback is for development only and must not be
presented as observed travel data.
The synthetic fixture covers all three weather types and all three times of day
with repeated observations for every directed route. P3 to P8 has only missing
or closure records during Rainy Morning to demonstrate the penalty case.
The generated heatmap marks a penalty cell with `P`; its numeric cost remains in
the matrix CSV and console output. One additional Rainy Morning record has an
unlisted endpoint to demonstrate the coordinate filter.

## Severe penalty calculation

After calculating the observed route percentiles, let `M` be the largest cost
currently in the matrix (including the zero diagonal). Each off-diagonal cell
still equal to `NA` has no valid travel history and is assigned:

```text
penalty = 11 * M + 1 minute
```

The 10-point tour contains 10 directed legs. A tour using only observed route
costs can therefore cost at most `10 * M`; one penalty edge costs more than
that. This makes a route with missing history much less attractive while
preserving a numeric matrix. The penalty is not a hard ban: a Nearest Neighbour
tour can still include it if its choices leave no other way to visit a required
point or return to the start. If any valid complete tour avoids penalties, a
globally minimum-cost tour will prefer it; Nearest Neighbour is a greedy method
and is not guaranteed to find that global tour.

In the current synthetic example, `M` is 24 minutes, so the penalty is
`11 * 24 + 1 = 265` minutes. This value changes with the observed route costs.

Write cleaned or aggregated data to `data/processed/q2/` and cost matrices,
route summaries, validation output, and figures to `outputs/q2/`. Insert selected
results into the Question 2 section of the
[shared Google Docs report](https://docs.google.com/document/d/1GAB7_rqw0hhjneBch7KhtM-GNt_AlFTzSP1gphYUyOE/edit?usp=drive_link)
and explain the cleaning, penalties, and route selection there.
