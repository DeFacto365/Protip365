# Android 16 Upgrade - Agent Introduction Prompt

---

## Context: ProTip365 Android 16 UI/UX Upgrade Project

You are working on **ProTip365**, a tip tracking app for service industry workers. The app is built with:
- **Jetpack Compose** for UI
- **Material 3** design system
- **Kotlin** language
- **Hilt** for dependency injection
- **Supabase** for backend
- Currently targeting **Android SDK 35** (Android 15)

## Project Goal

Upgrade the app to comply with **Android 16** UI/UX guidelines and leverage new Android 16 features. This is a comprehensive upgrade spanning multiple phases over several months.

---

## 📁 Documentation Location

All Android 16 upgrade documentation is located in:
```
ProTip365Android/Android 16/
```

**Key Documents to Review:**
1. **`AGENT_INTRO.md`** - This file - read first!
2. **`TODO.md`** - Comprehensive task list with detailed implementation guidance for all phases (THIS IS YOUR MAIN WORK FILE)

---

## 🔴 CRITICAL: Must Fix First

Before any other work, these **2 critical issues** must be addressed:

1. **Predictive Back Gesture** - Not implemented (required for Android 16)
   - See: `TODO.md` Phase 0.1 for detailed implementation
   - Files: `MainActivity.kt`, `AppNavigation.kt`, all screen composables
   - Estimated: 2-3 days

2. **Window Insets Handling** - Content hidden behind system bars
   - See: `TODO.md` Phase 0.2 for detailed implementation
   - Issue: `enableEdgeToEdge()` is called but no WindowInsets handling
   - Files: All screen composables with Scaffold
   - Estimated: 2-3 days

---

## Current Implementation Status

### ✅ Already Implemented
- Material 3 components in use
- Dynamic color theming (Android 12+)
- Jetpack Compose UI framework
- Basic notification support
- Basic haptic feedback
- Edge-to-edge enabled (but needs insets handling fix)

### ❌ Needs Implementation
- Predictive Back Gesture (CRITICAL)
- Window Insets handling (CRITICAL)
- Enhanced notifications (Live Updates, grouping)
- Adaptive layouts for tablets/foldables
- Comprehensive accessibility features
- Enhanced haptic feedback patterns
- Adaptive Refresh Rate optimization
- Themed app icons
- System-triggered profiling
- App shortcuts (mentioned in docs, not implemented)
- Home screen widgets (mentioned in docs, not implemented)

---

## Project Structure

```
ProTip365Android/
├── Android 16/                    # All Android 16 documentation here
│   ├── AGENT_INTRO.md            # This file - read first!
│   └── TODO.md                   # Main task list with implementation details (all phases)
├── app/
│   └── src/main/java/com/protip365/app/
│       ├── MainActivity.kt
│       ├── presentation/
│       │   ├── navigation/
│       │   ├── dashboard/
│       │   ├── calendar/
│       │   ├── settings/
│       │   ├── entries/
│       │   ├── theme/
│       │   └── notifications/
│       └── ...
```

## Key Files You'll Work With

### Critical Files (Phase 0)
- `app/src/main/java/com/protip365/app/MainActivity.kt`
- `app/src/main/java/com/protip365/app/presentation/navigation/AppNavigation.kt`
- All screen composables (for WindowInsets and Predictive Back)

### Theme Files
- `app/src/main/java/com/protip365/app/presentation/theme/Theme.kt`
- `app/src/main/java/com/protip365/app/presentation/theme/Type.kt`

### Notification Files
- `app/src/main/java/com/protip365/app/presentation/notifications/NotificationManager.kt`

---

## Implementation Phases

The project is organized into **11 phases**:

- **Phase 0:** Critical Missing Features (DO FIRST - 1-2 weeks)
- **Phase 1:** Foundation & Setup (2-3 weeks)
- **Phase 2:** Notifications Enhancement (2-3 weeks)
- **Phase 3:** Adaptive Layouts (3-4 weeks)
- **Phase 4:** Accessibility Enhancements (3-4 weeks)
- **Phase 5:** Enhanced Haptic Feedback (1-2 weeks)
- **Phase 6:** Animation and Transitions (1-2 weeks)
- **Phase 7:** Component Updates (1-2 weeks)
- **Phase 8:** Security and Privacy (1-2 weeks)
- **Phase 9:** Testing (2-3 weeks)
- **Phase 10:** Documentation (1 week)
- **Phase 11:** Final Polish (1 week)

**Total Timeline:** 16-22 weeks (4-5.5 months)

---

## Your Task Assignment

**[Specify what phase/task you want the agent to work on]**

Example assignments:
- "Work on Phase 0.1: Implement Predictive Back Gesture"
- "Fix Window Insets handling in DashboardScreen.kt"
- "Add accessibility content descriptions to all screens"
- "Implement notification grouping in NotificationManager.kt"

---

## ⚠️ CRITICAL CONSTRAINTS - MUST FOLLOW

### ⚠️ NO CORNER CUTTING - 100% COMPLETION REQUIRED
- **MANDATORY:** Complete **100% of each task** before marking it as done
- **DO NOT** mark tasks as complete unless you have:
  - ✅ Implemented ALL steps listed in the task
  - ✅ Tested the implementation thoroughly
  - ✅ Verified the build succeeds
  - ✅ Confirmed all requirements are met
- **DO NOT** assume something is "done" or "good enough" - verify completeness
- **DO NOT** skip steps or subtasks within a task
- **DO NOT** mark multiple tasks as complete if you only worked on one
- **Remember:** Partial completion is NOT completion. If a task has 5 steps and you completed 4, the task is NOT done.

### Build Testing Requirement
- **MANDATORY:** After completing any implementation work, you **MUST** test the build
- Run: `./gradlew assembleDebug` or use Android Studio to build
- Verify: Build succeeds without errors
- Report: Any build errors or warnings encountered
- **Never submit code that doesn't build successfully**

### Field Modifications Restriction
- **DO NOT** add, delete, or modify data model fields without explicit permission
- **DO NOT** modify fields if logic is implied or depends on the field structure
- **Ask first** before making any changes to:
  - Data models (ShiftEntry, CompletedShift, Employer, etc.)
  - Database schemas
  - API contracts
  - ViewModel state fields
- **Exception:** UI-only fields (like temporary state) may be modified if clearly needed

### Logic and Page Modifications
- **DO NOT** modify business logic without asking first
- **DO NOT** create new pages/screens without explicit approval
- **DO NOT** change existing navigation flows without permission
- **Ask first** before:
  - Changing calculation logic
  - Modifying data flow
  - Creating new screens
  - Changing navigation patterns
  - Modifying repository or use case logic

### When to Ask
When in doubt, **ASK FIRST**. It's better to ask for clarification than to:
- Break existing functionality
- Introduce bugs
- Create technical debt
- Modify critical logic incorrectly

---

## Important Guidelines

1. **Always Read First:** Review relevant documentation files before starting
2. **Check Code Examples:** Review `TODO.md` for implementation patterns and examples
3. **100% Completion Required:** Never mark a task as done unless ALL steps are completed - no corner cutting!
4. **Test Build After Changes:** **MANDATORY** - Always test build after completing work
5. **Test Thoroughly:** Test each feature as you implement it
6. **Backward Compatibility:** Ensure features degrade gracefully on older Android versions
7. **Android Version Checks:** Always check `Build.VERSION.SDK_INT` before using new APIs
8. **Follow Conventions:** Maintain existing code style and patterns
9. **Update TODO:** Mark completed tasks in `TODO.md` and update the "Last Updated" date
10. **Update Progress:** After completing work, update the Progress Tracking section in `TODO.md`
11. **Ask Before Modifying:** Don't modify fields, logic, or create new pages without asking
12. **Verify Completion:** Before marking any task complete, verify you've done ALL subtasks and requirements

---

## Code Style

- Use Kotlin coding conventions
- Follow existing code patterns in the codebase
- Add KDoc comments for new functions
- Use descriptive variable names
- Keep functions focused and small
- Handle errors gracefully

---

## Dependencies

Current key dependencies:
- `compileSdk = 35` (update to 36 when Android 16 SDK available)
- `targetSdk = 35` (update to 36)
- Compose BOM: `2024.12.01`
- Material 3: Latest version
- Navigation: `2.8.4`
- Hilt: `2.57.2`

---

## Testing Requirements

### Build Testing (MANDATORY)
- **After every change:** Run `./gradlew assembleDebug` or build in Android Studio
- **Verify:** Build completes successfully without errors
- **Report:** Any build errors, warnings, or issues

### Functional Testing
- Test on Android 16 devices/emulators when available
- Test backward compatibility (minimum API 26)
- Test accessibility features (TalkBack, dynamic type)
- Test on various screen sizes (phone, tablet, foldable)
- Test in both portrait and landscape orientations

---

## Questions to Ask Before Starting

1. Which specific phase/task should I work on?
2. Are there any constraints or deadlines I should know about?
3. Should I update the TODO list as I complete tasks?
4. Do you want me to create new files or modify existing ones?
5. Are there any specific Android 16 features you want prioritized?

---

## Output Expectations

When completing tasks, provide:
1. **Summary** of what was implemented
2. **Files modified** with brief descriptions
3. **Build test results** - Confirm build succeeded (MANDATORY)
4. **Testing performed** (what was tested functionally)
5. **Any issues** encountered or blockers
6. **Next steps** or recommendations
7. **TODO.md Updated** - Confirm you've updated `TODO.md` with:
   - Marked completed tasks as done
   - Updated the "Last Updated" date at the top
   - Updated Progress Tracking section if a phase was completed
8. **Completion Verification** - List ALL subtasks completed and confirm 100% completion

**⚠️ CRITICAL:** Before marking any task complete, verify:
- ✅ Every single step/subtask in the task is done
- ✅ Build tests pass
- ✅ Implementation matches requirements
- ✅ No shortcuts were taken
- ✅ All files mentioned in the task were updated

**Remember:** 
- Always include build test confirmation in your output!
- **MANDATORY:** Update `TODO.md` after completing any work - mark tasks complete and update the date
- **MANDATORY:** Never mark a task complete unless 100% done - partial completion is NOT acceptable

---

## Quick Reference Summary

**📁 Documentation:** `ProTip365Android/Android 16/`

**🔴 Critical Fixes:**
- Predictive Back Gesture (required for Android 16)
- Window Insets Handling (content visibility issue)

**⚠️ Must Follow:**
- Test build after every change
- Ask before modifying fields/logic/pages
- Never submit code that doesn't build
- **Complete 100% of each task - NO corner cutting!**
- Verify all subtasks are done before marking complete

**📚 Key Docs:**
- `AGENT_INTRO.md` - This file (read first!)
- `TODO.md` - Main task list with implementation details and explanations (YOUR PRIMARY WORK FILE)

**Timeline:** 16-22 weeks total, Phase 0 (Critical) is 1-2 weeks

---

## Ready to Start

Please review the documentation in `ProTip365Android/Android 16/` and let me know:
1. Which phase/task you'd like me to work on
2. Any specific requirements or constraints
3. Your preferred approach or priorities

I'm ready to help upgrade ProTip365 to Android 16 compliance!

---

**End of Introduction Prompt**

