---
id: en-snapshot-testing
title: Snapshot Testing UI
language: en
family: testing
---
Snapshot tests compare rendered output against recorded references. First run records the artifact — typically an image of a view — and subsequent runs diff against it, failing on any deviation and producing a visual comparison of what moved.

The economics are compelling for UI: three lines of test lock down an entire screen's layout. Parametrize across configurations and coverage multiplies — dark mode, Dynamic Type sizes from small to accessibility-huge, right-to-left locales, German strings that overflow English-sized buttons, each device width. Layout regressions that eyeball QA misses on the fifth review get caught mechanically on every commit.

In the Swift ecosystem, Point-Free's swift-snapshot-testing is the standard, and its strategies extend past pixels: view hierarchies dumped as text (resilient to GPU rendering noise), Codable values as JSON, network requests as raw text. Snapshotting a parser's output or a generated URL request is often more robust than image comparison.

Two disciplines keep suites healthy. Determinism: inject fixed dates and data, pin the simulator model and OS version, or cross-machine rendering differences will drown you in false failures. Review rigor: when an intentional change regenerates dozens of snapshots, each diff still deserves human eyes — rubber-stamped snapshots protect nothing. Keep reference artifacts in the repo and treat their diffs as first-class review content.
