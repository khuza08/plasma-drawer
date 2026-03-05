# Issue: Excessive Commented-Out Code

## Summary
Multiple files contain significant amounts of commented-out code, reducing code clarity and suggesting incomplete refactoring or debugging artifacts.

## Locations & Examples

### 1. `contents/ui/main.qml`

#### Line 33-36: Debug logging
```qml
// onActiveFocusItemChanged: {
//     console.log("activeFocusItem", activeFocusItem);
// }
```

#### Lines 60-65: Unused debug function
```qml
function logModelChildren(model, leadingSpace = 0) {
    let spacing = Array(leadingSpace + 1).join(" ");
    // console.log(model.description);
    // console.log(model.data(model.index(0, 0), 0));
    // ...
}
```

#### Line 105: Commented initialization
```qml
// systemFavoritesModel.favorites = plasmoid.configuration.favoriteSystemActions;
```

### 2. `contents/ui/MenuRepresentation.qml`

#### Line 95: Commented function call
```qml
// appsGridView.returnToRootDirectory(false);
```

#### Line 220: Commented trigger
```qml
//content.item.triggerSelected();
```

### 3. `contents/ui/ConfigGeneral.qml`

#### Lines 290-300: Commented button
```qml
// RowLayout {
//     Layout.fillWidth: true
//     enabled: showSystemActions.checked
//     Button {
//         enabled: showSystemActions.checked
//         text: i18n("Unhide all system actions")
//         onClicked: {
//             cfg_favoriteSystemActions = ["shutdown", "reboot", "logout", "suspend", "lock-screen", "switch-user"];
//         }
//     }
// }
```

### 4. `contents/ui/AppsGridView.qml`

#### Line 180: Commented property access
```qml
// + hasChildren ? `(${model.modelForRow(i).count}) - ` : ' - '
```

## Problems
1. **Reduced Readability**: Clutters files, making active code harder to find
2. **Maintenance Confusion**: Unclear whether code should be restored or removed
3. **Version Control Redundancy**: Git history already preserves removed code
4. **Inconsistent State**: Commented code may be outdated or incompatible

## Proposed Actions

### Remove These Sections:
1. **Debug logging** (`console.log` statements)
2. **Unused utility functions** (`logModelChildren`)
3. **Fully commented UI blocks** (the "Unhide all system actions" button)
4. **Commented function calls** with no clear purpose

### Keep Commented If:
- Code is temporarily disabled pending a fix (add `// TODO:` with issue reference)
- Alternative implementation being tested (add `// EXPERIMENTAL:` with date/author)

## Cleanup Strategy
```bash
# Find all commented QML blocks
grep -rn "^//" contents/ui/*.qml | grep -v "i18n"

# Review each instance and either:
# 1. Delete if obsolete
# 2. Uncomment if needed
# 3. Add TODO comment with tracking
```

## Impact
- **Severity**: Low (no functional impact)
- **Code Quality**: Affects maintainability and readability
- **Effort**: Low (mechanical cleanup)

## Best Practice
Use version control for historical code. If code must be temporarily disabled:
```qml
// TODO(#123): Re-enable after Plasma 6.1 compatibility fix
// Original code: someFunction()
```
