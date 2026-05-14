# Contributing to Vivd

Thank you for your interest in contributing! This document provides guidelines for contributing to the Vivd SDK.

## Development Setup

### Prerequisites

- Flutter 3.29+
- Dart 3.6+
- Melos (for monorepo management)

### Setup

```bash
# Clone
git clone https://github.com/ajianaz/vivd.git
cd vivd

# Install Melos
dart pub global activate melos

# Bootstrap all packages
melos bootstrap

# Run all tests
melos run test
```

## Project Structure

```
vivd/
├── packages/
│   ├── vivd/              ← Core SDK (Apache 2.0)
│   └── vivd_pro/          ← Pro SDK (BSL 1.1)
├── melos.yaml
└── README.md
```

## Coding Standards

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- All public APIs must have documentation comments
- Target 80%+ test coverage
- Use `flutter analyze` — zero warnings

## Pull Request Process

1. Create a feature branch from `develop`
2. Write tests for new functionality
3. Ensure `melos run analyze` passes
4. Ensure `melos run test` passes
5. Submit PR with clear description

## Reporting Issues

Please use [GitHub Issues](https://github.com/ajianaz/vivd/issues) with:
- Flutter version
- Device/simulator details
- Steps to reproduce
- Expected vs actual behavior
