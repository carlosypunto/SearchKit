---
id: en-ci-cd
title: CI/CD Pipelines for Mobile
language: en
family: devops
---
Continuous integration is a feedback machine: every push builds the project, runs the tests, and reports within minutes. The economics are about defect latency — bugs caught while context is fresh cost minutes; the same bugs discovered at release time cost days of bisection.

Continuous delivery automates the path from green build to users' hands. For Apple platforms that path has distinctive terrain: code signing with certificates and provisioning profiles (tamed by fastlane match, which stores signing assets in an encrypted repo), archive and export via xcodebuild, and upload to TestFlight for staged rollout.

Tooling options in practice: Xcode Cloud integrates natively with App Store Connect and requires near-zero configuration; GitHub Actions offers macOS runners and infinite flexibility through community actions; fastlane sits above either, encoding your build/test/beta/release procedures as reviewable Ruby lanes.

Pipeline health metrics that matter: total duration (keep it under fifteen minutes; parallelize test plans when it grows), flakiness (quarantine intermittent tests immediately — a suite people retry is a suite people ignore), and secret hygiene (signing keys and API tokens belong in the CI secret store, never in the repository).

The cultural core: releases should be boring. If shipping requires heroics, the pipeline has gaps.
