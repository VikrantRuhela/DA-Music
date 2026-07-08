# DA Music: Development Guide 🛠️

This document covers project setup, testing guidelines, code generation, and release build procedures.

## Developer Setup

### 1. Code Generation
DA Music utilizes `freezed`, `json_serializable`, and `drift` libraries. Ensure code generation is run after making changes to models:
- **Build once**:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
- **Watch mode** (continuous generation):
  ```bash
  dart run build_runner watch --delete-conflicting-outputs
  ```

### 2. Styling Rules
- **Themes**: Query color tokens from custom extensions instead of ThemeData fields:
  ```dart
  final colors = context.daColors;
  final typography = context.daTypography;
  ```
- **Motion**: Wrap interactive elements in `InteractiveScale` and configure duration and curves utilizing `DAMotion` tokens.

### 3. Static Analysis & Formatting
Before submitting pull requests or packaging builds, run checks:
```bash
flutter format .
flutter analyze
```

## Testing Checklist

### 1. Run Tests
Ensure all unit and widget tests pass:
```bash
flutter test
```

### 2. Manual Verification
- Resize the desktop window from 1400px down to 500px, verifying sidebars collapse and the floating Mini Player displays smoothly.
- Launch settings, enable Reduced Motion, and check that entrance animations collapse instantly.
- Toggle dark/light themes and check readability of text against secondary surfaces.
