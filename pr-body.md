This PR enhances the end-to-end workflow tests by adding comprehensive bottleneck tracking and documentation.

## What's Changed

- Added bottleneck tracking system with threshold-based detection
- Track timing for each workflow step across all test classes
- Automatic reporting of bottlenecks at test session end with severity levels (critical/warning)
- Enhanced existing test workflows with performance timing:
  - TestUserOnboardingWorkflow
  - TestDataQueryWorkflow
  - TestAgentInteractionWorkflow
- Added TestPlatformDesignWorkflow (design→manifest pipeline)
- Added TestComprehensiveEndToEndWorkflow (full platform journey)

## Problem

Issue #24 requires: "Bottlenecks identified and documented". The existing e2e tests passed but didn't identify or document performance bottlenecks.

## Solution

This enhancement automatically:
1. Measures duration of each workflow step
2. Compares against configurable thresholds
3. Flags steps exceeding thresholds as bottlenecks
4. Reports all bottlenecks at the end of the test session
5. Categorizes by severity (critical: >2x threshold, warning: >1x threshold)

## Impact

- Provides automatic bottleneck identification without manual analysis
- Establishes performance baselines for each workflow
- Enables trend tracking across refactors
- Helps guide optimization efforts
- Produces actionable performance reports in CI logs

## Testing

The enhanced test suite can be run with:
```bash
pytest tests/integration/test_e2e_enhanced.py -m e2e -v
```

Bottlenecks will be automatically printed at the end of the test session.

## Integration

This complements existing E2E tests (test_e2e_workflows.py). Both can coexist until merged, at which point this file will replace the original.

Closes #24