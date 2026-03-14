# Contributing to MiraiStreakKit

Thank you for your interest in contributing to MiraiStreakKit! This document provides guidelines and information for contributors.

## Code of Conduct

- Be respectful and constructive in all interactions
- Follow Swift community best practices
- Keep discussions focused and professional

## Getting Started

1. **Fork the repository**
2. **Clone your fork:**
   ```bash
   git clone https://github.com/hamzamirai/MiraiStreakKit.git
   cd MiraiStreakKit
   ```
3. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Guidelines

### Code Style

Follow the guidelines in [AGENTS.md](AGENTS.md):
- Use 4-space indentation
- Follow Swift API Design Guidelines
- Use `UpperCamelCase` for types, `lowerCamelCase` for members
- Document `public` APIs with Swift doc comments
- Run `swift format --in-place Sources Tests` before committing

### Building and Testing

```bash
# Build the package
swift build

# Run tests
swift test

# Run tests with coverage
swift test --enable-code-coverage
```

### Testing Requirements

- Write tests for all new features
- Maintain at least 80% code coverage
- Use descriptive test names (e.g., `@Test func streakResetsAfterGap()`)
- Mark tests with `@MainActor` when testing `StreakManager`
- Use the Swift Testing framework with `#expect` assertions

Example test:

```swift
@Test
@MainActor
func newFeatureBehavesCorrectly() throws {
    let store = InMemoryStore()
    let manager = StreakManager(store: store)
    
    // Test your feature
    manager.updateStreak()
    
    #expect(manager.streak.length == 1)
}
```

## Submitting Changes

### Pull Request Process

1. **Update documentation:**
   - Update README.md if adding features
   - Add examples to EXAMPLES.md if appropriate
   - Update CHANGELOG.md under `[Unreleased]`

2. **Ensure tests pass:**
   ```bash
   swift test
   ```

3. **Check for errors:**
   ```bash
   swift build
   ```

4. **Commit your changes:**
   ```bash
   git add .
   git commit -m "Add feature: brief description"
   ```
   
   Follow commit message conventions:
   - Use imperative mood ("Add feature" not "Added feature")
   - Keep first line under 70 characters
   - Reference issues: "Fixes #123" or "Refs #123"

5. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Open a Pull Request:**
   - Provide a clear description of changes
   - Include test output showing all tests pass
   - Add screenshots/recordings if UI-related
   - Link related issues

### Pull Request Template

```markdown
## Description
Brief description of changes

## Changes Made
- Added/Modified/Fixed: ...
- Added tests for: ...

## Testing
- [ ] All tests pass (`swift test`)
- [ ] Code coverage maintained/improved
- [ ] Manual testing performed

## Checklist
- [ ] Updated README.md (if needed)
- [ ] Updated EXAMPLES.md (if needed)
- [ ] Updated CHANGELOG.md
- [ ] Added tests
- [ ] Ran `swift format`
- [ ] No compiler warnings

Closes #XXX
```

## Types of Contributions

### Bug Fixes
- Check existing issues first
- Include reproduction steps
- Add tests that verify the fix

### New Features
- Open an issue to discuss first
- Ensure it fits the project scope
- Update all relevant documentation
- Include comprehensive tests

### Documentation
- Fix typos and improve clarity
- Add examples for complex features
- Keep tone professional and concise

### Performance Improvements
- Include benchmarks showing improvement
- Ensure no functionality regression
- Document trade-offs if any

## Issue Guidelines

### Reporting Bugs

```markdown
**Description**
Clear description of the bug

**Reproduction Steps**
1. Step one
2. Step two
3. ...

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Environment**
- MiraiStreakKit version: X.X.X
- Platform: iOS 17.0 / macOS 14.0 / visionOS 2.0
- Xcode version: X.X
- Swift version: 6.X
```

### Feature Requests

```markdown
**Feature Description**
Clear description of the proposed feature

**Use Case**
Why this feature would be useful

**Proposed API**
Example code showing how it might work

**Alternatives Considered**
Other approaches you've thought about
```

## Architecture Decisions

### Observation vs Combine

MiraiStreakKit uses Swift's Observation framework (`@Observable`) instead of Combine because:
- Simpler API for consumers
- Better SwiftUI integration
- Reduced boilerplate
- Swift 6 native

### MainActor Isolation

`StreakManager` is `@MainActor` isolated because:
- Primary use case is SwiftUI
- Simplifies concurrency model
- Prevents race conditions
- Clear actor boundaries

### Persistence Protocol

The `StreakStore` protocol allows:
- Custom backends (CloudKit, Core Data, etc.)
- Easy testing with mocks
- Platform-specific implementations
- Zero forced dependencies

## Questions?

- Open a [Discussion](https://github.com/hamzamirai/MiraiStreakKit/discussions) for questions
- Check [AGENTS.md](AGENTS.md) for repository guidelines
- Review [EXAMPLES.md](EXAMPLES.md) for usage patterns

Thank you for contributing! 🙏
