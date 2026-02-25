---
name: accessibility-audit
description: Audits Flutter Dart files for WCAG 2.1 AA accessibility issues. Platform-agnostic. Run on any widget, screen, or feature before merging UI changes.
---

Run a Flutter accessibility audit on the provided file(s) or, if none specified, all `lib/**/*_view.dart` and `lib/**/*_page.dart` files.

## Scope

Read every target `.dart` file. Also read any theme/color token files (e.g. `lib/theme/`) to resolve color values for contrast checks.

## Checks

Severity: **CRITICAL** · **MAJOR** · **MINOR**

---

### A · Semantics & Screen Reader
Patterns: `Image`, `GestureDetector`, `InkWell`, `IconButton`, `Icon`, `Semantics`, `ExcludeSemantics`, `MergeSemantics`

- `Image` → must have `semanticLabel` or `Semantics(label:)` · WCAG 1.1.1
- `GestureDetector(onTap:)` without a semantic button wrapper → flag; prefer `InkWell`/`ElevatedButton` or add `Semantics(label:, button: true)` · WCAG 4.1.2
- `ExcludeSemantics` on non-decorative content → CRITICAL · WCAG 1.3.1
- Dynamic/loading/error content → needs `Semantics(liveRegion: true)` or `SemanticsService.announce()` · WCAG 4.1.3
- Icon-only buttons → must have `Tooltip` or `Semantics(label:)` · WCAG 1.1.1
- Empty `semanticLabel: ''` on meaningful content → CRITICAL

### B · Touch Target Sizes
Patterns: `GestureDetector`, `InkWell`, `IconButton`, `TextButton`, `ElevatedButton`

- Minimum 48 × 48 dp for all interactive elements · WCAG 2.5.5
- If constrained by a `SizedBox` or `Container` smaller than 48 dp → flag and suggest wrapping with `SizedBox(width: 48, height: 48)` or adding `padding`

### C · Focus & Keyboard
Patterns: `FocusTraversalGroup`, `Focus`, `FocusNode`, `GestureDetector`

- `GestureDetector` without a `Focus` wrapper → not keyboard-accessible · WCAG 2.1.1
- Dialogs/overlays must request focus on open and restore it on dismiss · WCAG 2.4.3
- No keyboard traps — every focusable widget must be exitable · WCAG 2.1.2
- `FocusTraversalGroup` required where tab order would mismatch visual order · WCAG 1.3.2
- Custom focus indicators must meet 3:1 contrast · WCAG 2.4.11

### D · Color Contrast
Patterns: `Color(`, `Colors.`, `TextStyle(color:`

- Normal text (< 18 pt / 14 pt bold): ≥ 4.5:1 · WCAG 1.4.3
- Large text (≥ 18 pt / 14 pt bold): ≥ 3:1 · WCAG 1.4.3
- UI components & focus rings: ≥ 3:1 · WCAG 1.4.11
- Color as sole differentiator (no label/icon/shape) → MAJOR · WCAG 1.4.1

### E · Text Scaling
Patterns: `TextStyle`, `Text`, `SizedBox` with fixed height near text

- Hardcoded `textScaleFactor` or `textScaler` that clamps user prefs → MAJOR · WCAG 1.4.4
- Fixed-height containers wrapping `Text` → risk of clipping at 1.5–2× scale → flag
- `TextOverflow.clip` without visible fallback → MINOR

### F · Animation & Motion
Patterns: `AnimationController`, `AnimatedContainer`, `AnimatedOpacity`, `Hero`, `PageRoute`

- Animations not gated on `MediaQuery.of(context).disableAnimations` → MAJOR · WCAG 2.3.3
- Flashing content > 3 Hz → CRITICAL · WCAG 2.3.1

---

## Output Format

```
# Flutter Accessibility Audit

Files audited: [list]

## Summary
| Severity | Count |
|----------|-------|
| CRITICAL |  X    |
| MAJOR    |  X    |
| MINOR    |  X    |

## Findings

### 1. [Title]
- File: path/to/file.dart ~L42
- WCAG: 1.4.3
- Severity: CRITICAL
- Issue: [description]
- Fix:
  // Before
  [code]
  // After
  [code]

## Passed Checks
[List passed checks to confirm audit completeness]

## Next Steps
1. Run `@flutter-accessibility-expert` to apply fixes and write tests automatically.
2. Fix all CRITICAL before merging.
3. Schedule MAJOR for next sprint.
4. Test with TalkBack/VoiceOver on a real device.
5. Re-run audit after fixes.
```

## Test Suggestions

For each CRITICAL or MAJOR finding, output a `flutter_test` snippet:

```dart
testWidgets('description', (tester) async {
  final handle = tester.ensureSemantics();
  await tester.pumpWidget(/* widget */);
  expect(tester.getSemantics(find.byType(MyWidget)).label, 'Expected label');
  handle.dispose();
});
```
