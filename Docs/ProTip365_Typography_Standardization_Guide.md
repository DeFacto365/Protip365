# ProTip365 Typography Standardization Guide
**Version:** 1.0
**Date:** September 2025
**Platform:** iOS 18/26 & iPadOS 18/26

---

## 🎪 Current Typography Circus

Your app is indeed a "Christmas tree" with:
- **Mixed font sizes**: `.system(size: 16)`, `.system(size: 20)`, `.font(.headline)`, `.font(.body)` all over
- **Random weights**: `.bold`, `.semibold`, `.medium`, `.regular` with no logic
- **Color chaos**: `.gray`, `.black`, `.red`, `.green`, `.purple`, `.blue` hardcoded everywhere
- **Inconsistent text styles**: Same content, different styling across views

---

## Typography System Rules

### 1. Font Hierarchy (STRICT)

```swift
// ONLY USE THESE - NO EXCEPTIONS!

// Level 1: Screen Titles
.font(.largeTitle)          // 34pt - Main screen titles only
.foregroundStyle(.primary)   // Always primary

// Level 2: Section Headers
.font(.title2)               // 22pt - Major sections
.foregroundStyle(.primary)

// Level 3: Card Titles
.font(.headline)             // 17pt semibold - Card headers
.foregroundStyle(.primary)

// Level 4: Body Text
.font(.body)                 // 17pt regular - Main content
.foregroundStyle(.primary)

// Level 5: Captions
.font(.caption)              // 12pt - Supporting text
.foregroundStyle(.secondary)

// Level 6: Small Captions
.font(.caption2)             // 11pt - Timestamps, labels
.foregroundStyle(.tertiary)
```

### 2. Text Colors (NO CHRISTMAS TREE!)

```swift
// PRIMARY CONTENT
.foregroundStyle(.primary)    // Main text (adapts to dark mode)

// SECONDARY CONTENT
.foregroundStyle(.secondary)  // Supporting text

// TERTIARY CONTENT
.foregroundStyle(.tertiary)   // Least important

// STATUS COLORS ONLY
.foregroundStyle(.green)      // Success/positive ONLY
.foregroundStyle(.red)        // Error/negative ONLY
.foregroundStyle(.orange)     // Warning ONLY
.foregroundStyle(.blue)       // Links/actions ONLY

// NEVER USE THESE:
.foregroundColor(.black)     // ❌ BANNED
.foregroundColor(.gray)      // ❌ BANNED
.foregroundStyle(Color.gray) // ❌ BANNED
.foregroundColor(Color(...)) // ❌ BANNED
```

### 3. Font Weights (SIMPLIFIED)

```swift
// ONLY THREE WEIGHTS ALLOWED:

// Bold - For emphasis only
.fontWeight(.bold)           // Totals, important numbers

// Semibold - For headers
.fontWeight(.semibold)       // Section headers, card titles

// Regular - Everything else
.fontWeight(.regular)        // Body text (default)

// BANNED WEIGHTS:
.fontWeight(.medium)         // ❌ Use .semibold instead
.fontWeight(.light)          // ❌ Never use
.fontWeight(.heavy)          // ❌ Never use
.fontWeight(.black)          // ❌ Never use
```

---

## Component-Specific Typography

### Navigation Bar
```swift
// Title
.navigationTitle("Title")
.navigationBarTitleDisplayMode(.inline)
// No custom font - uses system default

// Bar items
.font(.body)
.foregroundStyle(.tint)
```

### Tab Bar
```swift
// Label
.font(.caption)              // 12pt
.fontWeight(isSelected ? .semibold : .regular)
.foregroundStyle(isSelected ? .tint : .secondary)
```

### Cards
```swift
// Card Title
Text(title)
    .font(.headline)         // 17pt semibold
    .foregroundStyle(.primary)

// Card Value (Large Number)
Text(value)
    .font(.title2)          // 22pt
    .fontWeight(.bold)      // Bold for emphasis
    .foregroundStyle(.primary)

// Card Subtitle
Text(subtitle)
    .font(.caption)         // 12pt
    .foregroundStyle(.secondary)
```

### Forms
```swift
// Section Header
Text("SECTION")
    .font(.caption)         // 12pt
    .textCase(.uppercase)   // Always uppercase
    .foregroundStyle(.secondary)

// Field Label
Text("Label")
    .font(.body)           // 17pt
    .foregroundStyle(.primary)

// Field Value
TextField("", text: $value)
    .font(.body)           // 17pt
    .foregroundStyle(.primary)

// Helper Text
Text("Helper")
    .font(.caption2)       // 11pt
    .foregroundStyle(.tertiary)
```

### Buttons
```swift
// Primary Button
Text("Action")
    .font(.body)           // 17pt
    .fontWeight(.semibold) // Semibold for buttons
    .foregroundStyle(.white)

// Secondary Button
Text("Cancel")
    .font(.body)           // 17pt
    .fontWeight(.regular)  // Regular weight
    .foregroundStyle(.tint)
```

### Lists
```swift
// List Item Title
Text(title)
    .font(.body)           // 17pt
    .foregroundStyle(.primary)

// List Item Subtitle
Text(subtitle)
    .font(.caption)        // 12pt
    .foregroundStyle(.secondary)

// List Item Value
Text(value)
    .font(.body)           // 17pt
    .fontWeight(.semibold) // Emphasis
    .foregroundStyle(.primary)
```

### Stat Displays
```swift
// Stat Value (Money)
Text(formatCurrency(amount))
    .font(.title2)         // 22pt
    .fontWeight(.bold)     // Bold for money
    .foregroundStyle(.primary)

// Stat Label
Text("Total Revenue")
    .font(.caption)        // 12pt
    .foregroundStyle(.secondary)

// Percentage
Text("\(percentage)%")
    .font(.body)           // 17pt
    .fontWeight(.semibold) // Semibold for metrics
    .foregroundStyle(color) // Color based on performance
```

---

## Color Usage by Context

### Financial Values
```swift
// Positive money (income, tips)
.foregroundStyle(.green)    // ONLY for positive amounts

// Negative money (tip-out, expenses)
.foregroundStyle(.red)      // ONLY for negative amounts

// Neutral money (sales, totals)
.foregroundStyle(.primary)  // Default for neutral

// Target/Budget comparisons
.foregroundStyle(.blue)     // When showing vs target
```

### Performance Indicators
```swift
// Exceeded target (>100%)
.foregroundStyle(.green)

// Good performance (75-99%)
.foregroundStyle(.blue)

// Needs improvement (50-74%)
.foregroundStyle(.orange)

// Poor performance (<50%)
.foregroundStyle(.red)
```

### Status Messages
```swift
// Success messages
.foregroundStyle(.green)

// Error messages
.foregroundStyle(.red)

// Info messages
.foregroundStyle(.blue)

// Warning messages
.foregroundStyle(.orange)
```

---

## Migration Checklist

### Phase 1: Critical Text Fixes

#### Dashboard (DashboardView.swift)
- [ ] Line 54: `.font(.caption)` not `.font(.system(size: 11))`
- [ ] Line 72: `.fontWeight(.semibold)` not `.fontWeight(.bold)`
- [ ] Line 94: `.foregroundStyle(.secondary)` not `.foregroundColor(.gray)`
- [ ] All stat cards: Use `.font(.title2).fontWeight(.bold)` for values
- [ ] All subtitles: Use `.font(.caption).foregroundStyle(.secondary)`

#### Calendar (CalendarShiftsView.swift)
- [ ] Line 147: `.font(.caption).textCase(.uppercase)` for date headers
- [ ] Line 733: `.font(.subheadline).fontWeight(.semibold)` for employer names
- [ ] Line 835-897: Consistent `.font(.caption2)` for labels, `.font(.subheadline).fontWeight(.semibold)` for values
- [ ] Remove all `.foregroundColor(.black)` - use `.foregroundStyle(.primary)`

#### Settings (SettingsView.swift)
- [ ] Section headers: `.font(.caption).textCase(.uppercase).foregroundStyle(.secondary)`
- [ ] List items: `.font(.body).foregroundStyle(.primary)`
- [ ] Values: `.font(.body).fontWeight(.semibold).foregroundStyle(.primary)`
- [ ] Remove all hardcoded colors

#### Forms (AddEntryView.swift)
- [ ] Field labels: `.font(.body).foregroundStyle(.primary)`
- [ ] Input text: `.font(.body).foregroundStyle(.primary)`
- [ ] Error messages: `.font(.caption).foregroundStyle(.red)`
- [ ] Helper text: `.font(.caption2).foregroundStyle(.tertiary)`

### Phase 2: Component Standardization

#### Buttons
- [ ] All primary buttons: `.font(.body).fontWeight(.semibold)`
- [ ] All secondary buttons: `.font(.body).fontWeight(.regular)`
- [ ] All text buttons: `.font(.body).foregroundStyle(.tint)`

#### Cards
- [ ] All card titles: `.font(.headline)`
- [ ] All card values: `.font(.title2).fontWeight(.bold)`
- [ ] All card subtitles: `.font(.caption).foregroundStyle(.secondary)`

#### Lists
- [ ] All list headers: `.font(.caption).textCase(.uppercase)`
- [ ] All list items: `.font(.body)`
- [ ] All list values: `.font(.body).fontWeight(.semibold)`

---

## Examples

### ❌ WRONG (Current Chaos)
```swift
// Random sizes
Text("Sales")
    .font(.system(size: 16, weight: .bold))  // ❌
    .foregroundColor(.black)                  // ❌

// Hardcoded colors
Text("$1,234")
    .font(.title.bold())                      // ❌
    .foregroundColor(Color.green)             // ❌

// Mixed weights
Text("Tips")
    .fontWeight(.medium)                      // ❌
    .foregroundColor(.gray)                   // ❌
```

### ✅ CORRECT (Standardized)
```swift
// Card title
Text("Sales")
    .font(.headline)                          // ✅
    .foregroundStyle(.primary)                // ✅

// Money value
Text("$1,234")
    .font(.title2)                           // ✅
    .fontWeight(.bold)                       // ✅
    .foregroundStyle(.primary)               // ✅

// Supporting text
Text("Tips")
    .font(.caption)                          // ✅
    .foregroundStyle(.secondary)             // ✅
```

---

## Quick Reference

| Content Type | Font | Weight | Color |
|-------------|------|--------|-------|
| Screen Title | `.largeTitle` | Regular | `.primary` |
| Section Header | `.title2` | Regular | `.primary` |
| Card Title | `.headline` | Semibold | `.primary` |
| Card Value | `.title2` | Bold | `.primary` |
| Body Text | `.body` | Regular | `.primary` |
| Supporting Text | `.caption` | Regular | `.secondary` |
| Label | `.caption2` | Regular | `.tertiary` |
| Money (positive) | `.title2` | Bold | `.green` |
| Money (negative) | `.title2` | Bold | `.red` |
| Percentage | `.body` | Semibold | Context color |
| Button Text | `.body` | Semibold | `.white` or `.tint` |
| Error Message | `.caption` | Regular | `.red` |
| Success Message | `.caption` | Regular | `.green` |

---

## Enforcement Rules

1. **NO HARDCODED SIZES**: Never use `.system(size: X)`
2. **NO HARDCODED COLORS**: Never use `Color.black`, `Color.gray`, etc.
3. **NO MIXED WEIGHTS**: Only `.bold`, `.semibold`, `.regular`
4. **NO CUSTOM FONTS**: Only system fonts
5. **ALWAYS SEMANTIC**: Use `.primary`, `.secondary`, `.tertiary`
6. **CONSISTENT HIERARCHY**: Larger fonts for more important content

---

## Testing Checklist

For every text element:
1. [ ] Uses system font style (`.body`, `.headline`, etc.)
2. [ ] Uses approved weight (`.bold`, `.semibold`, `.regular` only)
3. [ ] Uses semantic color (`.primary`, `.secondary`, etc.)
4. [ ] Follows hierarchy rules (important = larger)
5. [ ] Adapts to dark mode properly
6. [ ] Supports Dynamic Type
7. [ ] Consistent with similar elements

---

## Common Violations to Fix

1. **DashboardView.swift**: 50+ hardcoded colors and sizes
2. **CalendarShiftsView.swift**: Mixed `.foregroundColor` and `.foregroundStyle`
3. **SettingsView.swift**: Inconsistent section headers
4. **AddEntryView.swift**: Random font weights
5. **TipCalculatorView.swift**: Hardcoded `.system(size: 20)`

---

**Remember**: This is a SERIOUS APP, not a Christmas tree! Keep it clean, consistent, and professional.

**Document Version:** 1.0
**Last Updated:** September 14, 2025
**Enforcement:** MANDATORY