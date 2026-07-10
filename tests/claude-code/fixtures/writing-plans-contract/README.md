# Writing Plans Structural Contract Fixtures

These files are **structural contract fixtures, NOT generated executable plans**.

They isolate the three v6 planning structures checked by the deterministic test:

- verbatim Global Constraints copied from an approved spec;
- one `**Interfaces:**` wrapper with exact `Consumes` and `Produces` contracts;
- one right-sized vertical task containing DB, API, UI, configuration, test, and documentation artifacts;
- two unrelated behaviors kept as two tasks despite sharing one registry file;
- explicit `N/A — <specific reason>` contracts that reject empty and generic N/A values.

They intentionally do not claim to satisfy the full `t-writing-plans` contract for complete implementation code, exhaustive RED/GREEN steps, or production-ready commands. Live behavior evidence is recorded under `docsDev/changes/20260710-writing-plans-v6/transcripts/` and is not a CI dependency.
