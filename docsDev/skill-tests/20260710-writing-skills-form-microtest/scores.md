# Manual Scores

Every response was read in full. Bold markup around `not` in control runs 01, 02, 04, and 05 is a negative rule even though a naive plain-text phrase matcher can miss it.

| Run | Positive contract | No negative rule | Required structure | Output contract | Total |
|---|---:|---:|---:|---:|---:|
| control-01 | 1 | 0 | 1 | 1 | 3/4 |
| control-02 | 1 | 0 | 1 | 1 | 3/4 |
| control-03 | 0 | 0 | 0 | 1 | 1/4 |
| control-04 | 1 | 0 | 1 | 1 | 3/4 |
| control-05 | 1 | 0 | 1 | 1 | 3/4 |
| guided-v1-01 | 1 | 0 | 1 | 1 | 3/4 |
| guided-v1-02 | 1 | 0 | 1 | 1 | 3/4 |
| guided-v1-03 | 1 | 0 | 1 | 1 | 3/4 |
| guided-v1-04 | 1 | 0 | 1 | 1 | 3/4 |
| guided-v1-05 | 1 | 0 | 1 | 1 | 3/4 |
| guided-v2-01 | 1 | 1 | 1 | 1 | 4/4 |
| guided-v2-02 | 1 | 1 | 1 | 1 | 4/4 |
| guided-v2-03 | 1 | 1 | 1 | 1 | 4/4 |
| guided-v2-04 | 1 | 1 | 1 | 1 | 4/4 |
| guided-v2-05 | 1 | 1 | 1 | 1 | 4/4 |

## Result

- Control RED: 5/5 runs shipped a negative content rule; scores varied from 1/4 to 3/4.
- Candidate v1 remained RED: 5/5 runs converged structurally but appended a negative rule.
- Guided v2 GREEN: 5/5 runs scored 4/4 and converged on the same four-part positive contract; raw lengths were 32–46 words.
- The no-guidance control clearly exhibits the failure, the refactor is causally motivated by preserved failed runs, and the final result satisfies the predeclared campaign gate.
