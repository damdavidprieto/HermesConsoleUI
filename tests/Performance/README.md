# Performance Benchmarking Suite for HermesConsoleUI

This directory contains performance benchmarking and profiling tools for HermesConsoleUI.

## Quick Start

```powershell
# Run all benchmarks
.\Invoke-PerformanceBenchmark.ps1

# Run specific benchmark
.\Benchmark-TableRendering.ps1

# Check for performance regressions
.\Test-PerformanceRegression.Tests.ps1
```

## Benchmark Scripts

- **Invoke-PerformanceBenchmark.ps1** - Master script that runs all benchmarks
- **Benchmark-TableRendering.ps1** - Measures table rendering performance
- **Benchmark-Spinners.ps1** - Measures spinner animation performance
- **Benchmark-MenuInteraction.ps1** - Measures menu interaction performance
- **Benchmark-ColorProcessing.ps1** - Measures color/ANSI processing performance

## Profiling Scripts

- **Measure-MemoryProfile.ps1** - Memory consumption and leak detection
- **Measure-CPUProfile.ps1** - CPU usage analysis

## Test Scripts

- **Test-PerformanceRegression.Tests.ps1** - Pester tests for performance regression

## Baseline

- **PerformanceBaseline.json** - Baseline metrics for regression detection
