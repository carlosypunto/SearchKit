---
id: en-coreml
title: On-Device ML with Core ML
language: en
family: ai-ml
---
Core ML executes trained machine-learning models on Apple devices, automatically scheduling work across CPU, GPU, and the Neural Engine. Your app makes a typed method call; the framework decides where the math runs.

Integration is refreshingly boring. Drop an `.mlpackage` into Xcode and it generates a Swift class with strongly typed inputs and outputs. Image models accept `CVPixelBuffer`, sequence models take `MLMultiArray`, and predictions are synchronous calls you dispatch off the main thread or async variants.

Models originate from conversion or training. The coremltools Python package converts PyTorch models, applying optimizations that matter enormously on mobile: palettization and 4-bit quantization to shrink weights, and compute-unit tuning. Create ML covers the simpler end — train an image or text classifier on your Mac via transfer learning, no ML expertise required.

The on-device trade is structural: zero network latency, complete privacy, no per-inference cost — against device memory ceilings, app-size budgets, and models far smaller than server-side giants. Design around it: run smaller models more often, cache aggressively.

Before shipping a custom model, check whether Vision, NaturalLanguage, or Sound Analysis already solves the task — Apple's built-in models handle OCR, object detection, and sentiment with zero added megabytes.
