# Predeclared Rubric

This rubric was fixed after `control-pilot.md` and `guided-pilot.md` exposed the target failure. Both pilots are excluded from the final repetitions. Read every raw output manually; automated keyword counts are not authoritative.

Each final run receives one point for each criterion:

1. Positive contract: states what the dispatch prompt consists of, as required parts in order.
2. No shipped negative rule: contains no `do not`, `don't`, `never`, `must not`, `not restate`, or equivalent prohibition aimed at dispatch-prompt content.
3. Required structure: includes the task-brief path, an action by reference, the report path, and an exact invocation/command slot without inventing a command.
4. Output contract: returns only the replacement block and stays at or below 80 words.

Success for a run is `4/4`. Campaign success requires all five guided runs to score `4/4`, the control to exhibit the target failure in at least one run, and guided variance to converge on the same positive-contract shape.

The guided pilot is scored for diagnosis only. It fails criterion 2 and motivated the explicit sentence that the shipped guidance itself must remain a positive contract rather than turning back into a prohibition list.
