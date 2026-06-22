## Description

<!-- Brief description of what this PR changes + why. -->

## Type of Change

Mark all that apply:

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] ♻️ Refactor (code change that neither fixes a bug nor adds a feature)
- [ ] 🎨 UI/UX (styling, layout, animations, accessibility)
- [ ] ⚡ Performance (improves speed, memory, or battery)
- [ ] 🔒 Security (auth, encryption, audit, secrets handling)
- [ ] 📚 Documentation (README, code comments, API docs)
- [ ] 🔧 CI/CD (GitHub Actions, build, release)
- [ ] 🧪 Tests (unit, widget, integration)
- [ ] 🌐 Internationalization (i18n / l10n)
- [ ] 🤖 New AI provider integration

## Affected Subsystems

<!-- List the subsystems touched by this PR. e.g. Chat AI, RAG, MCP, etc. -->

## Testing

- [ ] `dart analyze` passes with no errors
- [ ] `flutter analyze` passes with no errors
- [ ] `flutter test` passes with no failures
- [ ] `dart format lib/ test/` produces no diffs
- [ ] No new TODO / FIXME / placeholder / UnimplementedError introduced
- [ ] Tested on physical device (Android 12+)
- [ ] Tested on tablet / foldable form factor
- [ ] Tested in dark mode + light mode

## Screenshots / Recordings

<!-- If this PR changes UI, attach before/after screenshots or a screen recording. -->

<details>
<summary>Before</summary>

<!-- screenshot -->

</details>

<details>
<summary>After</summary>

<!-- screenshot -->

</details>

## Security Checklist

- [ ] No API keys / tokens / passwords hardcoded
- [ ] No new path-traversal / injection vulnerabilities
- [ ] No new dependencies with known CVEs
- [ ] Encryption keys remain in Android Keystore (not exported)
- [ ] Audit log entries added for any new security-relevant operation
- [ ] Biometric / PIN prompts not bypassed by new code path

## Performance Checklist

- [ ] No new `print()` statements (use `AppLogger`)
- [ ] No new widget rebuilds on every frame
- [ ] No new `setState()` in `build()` methods
- [ ] No new blocking I/O on the UI thread
- [ ] No new large image assets without caching
- [ ] Target frame rate: 60fps minimum, 120fps where supported

## Migration Notes

<!-- If this is a breaking change, describe how users should migrate. -->

## Release Notes

<!-- One-line summary suitable for the changelog. e.g. "Added GLM-5.2 support" -->

## References

- Closes #
- Related to #
- Depends on #

## Reviewer Notes

<!-- Anything specific reviewers should pay attention to? -->

## Checklist

- [ ] My code follows the project's style guide (`dart format`)
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published in downstream modules
