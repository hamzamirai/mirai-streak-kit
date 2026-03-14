# Repository Guidelines

## Project Structure & Module Organization
Root `Package.swift` defines the single `MiraiStreakKit` library and its `MiraiStreakKitTests` target. Library code lives under `Sources/MiraiStreakKit/`; create focused files per feature instead of expanding `MiraiStreakKit.swift` indefinitely. Keep test-only helpers and fixtures in `Tests/MiraiStreakKitTests/` (add `Fixtures/` subfolders as needed) so the library target remains production-only.

## Build, Test, and Development Commands
Use `swift build` to compile the package with Swift 6 toolchains; run this before opening a PR. Run `swift test` for the full asynchronous test suite that uses the `Testing` module and `#expect` assertions. When you need coverage numbers, execute `swift test --enable-code-coverage` and inspect the `.profdata` output via Xcode or `llvm-cov report`.

## Coding Style & Naming Conventions
Follow Swift API Design Guidelines with 4-space indentation, trailing commas in multi-line literals, and `UpperCamelCase` types / `lowerCamelCase` members. Prefer small, extension-oriented types that expose minimal public surface; document `public` APIs with Swift doc comments. Run `swift format --in-place Sources Tests` before committing to normalize spacing and brace placement; avoid introducing compiler warnings.

## Testing Guidelines
Name tests after the behavior under check (e.g., `@Test func streakResetsAfterGap()`), and group related coverage inside helper extensions. Mirror the directory structure between `Sources` and `Tests` so every type gains a companion spec. For new features, add async tests exercising success and failure paths, and guard regressions with boundary cases; aim for at least 80% coverage on touched files.

## Commit & Pull Request Guidelines
Write imperative, concise commit summaries (single sentence under 70 characters) followed by optional detail lines. Reference related issues using `Refs #123` in the body when applicable, and split large changes into reviewable commits. PRs should include a short description of the change, testing performed (`swift test` output), and screenshots or screen recordings if the update affects UI consumers in downstream apps.
