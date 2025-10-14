# Envive Development Guide

## Table of Contents
- [Project Overview](#project-overview)
- [Architecture Principles](#architecture-principles)
- [Best Practices](#best-practices)
- [Troubleshooting Guide](#troubleshooting-guide)
- [Prompt Templates](#prompt-templates)
- [Code Standards](#code-standards)
- [Testing Guidelines](#testing-guidelines)

---

## Project Overview

Envive is an iOS screen time management app with a credibility scoring system for children and parental controls. The app has been refactored from a tightly-coupled, inheritance-based architecture to a modern, protocol-oriented design with dependency injection.

### Technology Stack
- **Platform:** iOS 18.0+
- **Language:** Swift 5
- **UI Framework:** SwiftUI
- **Key Dependencies:** FamilyControls, DeviceActivity, ManagedSettings, Supabase
- **Architecture:** MVVM with Protocol-Oriented Design
- **Testing:** XCTest with 69+ unit and integration tests

### Project Structure
```
EnviveNew/
├── Core/
│   ├── DependencyContainer.swift      # Centralized dependency injection
│   └── ViewModelFactory.swift         # Factory for creating view models
├── Protocols/
│   ├── CredibilityService.swift       # Service protocols
│   ├── StorageService.swift
│   └── ScreenTimeService.swift
├── Services/
│   ├── Credibility/                   # Credibility system services
│   ├── Camera/                        # Camera functionality
│   ├── Location/                      # Location services
│   ├── Notifications/                 # Push notifications
│   ├── UserDefaultsStorage.swift      # Production storage
│   └── MockStorage.swift              # Test storage
├── Repositories/
│   ├── CredibilityRepository.swift    # Data persistence layer
│   ├── AppSelectionRepository.swift
│   └── RewardRepository.swift
├── ViewModels/
│   └── MainViewModel.swift            # App-level view model
├── Views/
│   └── Home/                          # View components
├── Components/
│   ├── Credibility/                   # Reusable credibility UI
│   ├── Task/                          # Reusable task UI
│   └── Common/                        # Common UI components
└── EnviveNewTests/
    ├── Services/                      # Service tests
    ├── Repositories/                  # Repository tests
    ├── Integration/                   # Integration tests
    └── TestHelpers/                   # Mock objects
```

---

## Architecture Principles

### 1. Protocol-Oriented Design
✅ **DO:** Define protocols for all services
```swift
protocol CredibilityService {
    var credibilityScore: Int { get }
    func processDownvote(taskId: UUID, reviewerId: UUID, notes: String?)
}
```

❌ **DON'T:** Use concrete types directly in other services
```swift
// Bad
class MyService {
    let manager = CredibilityManager()  // Tight coupling
}

// Good
class MyService {
    let credibilityService: CredibilityService  // Protocol dependency
}
```

### 2. Dependency Injection
✅ **DO:** Inject dependencies through initializers
```swift
class MyService {
    private let storage: StorageService

    init(storage: StorageService) {
        self.storage = storage
    }
}
```

❌ **DON'T:** Create dependencies inside classes
```swift
// Bad
class MyService {
    private let storage = UserDefaultsStorage()  // Hard-coded dependency
}
```

### 3. Single Responsibility Principle
✅ **DO:** Keep classes focused on one responsibility
```swift
// Good - Calculator only does calculations
class CredibilityCalculator {
    func calculateDownvotePenalty(lastDownvoteDate: Date?) -> Int { }
}

// Good - Repository only handles persistence
class CredibilityRepository {
    func saveScore(_ score: Int) { }
    func loadScore() -> Int { }
}
```

❌ **DON'T:** Mix concerns in a single class
```swift
// Bad - Mixing calculation, persistence, and UI formatting
class CredibilityManager {
    func calculatePenalty() { }
    func saveScore() { }
    func getScoreColor() { }  // UI concern!
}
```

### 4. Repository Pattern
✅ **DO:** Access data through repositories
```swift
// Good
let repo = CredibilityRepository(storage: storage)
repo.saveScore(95)
let score = repo.loadScore()
```

❌ **DON'T:** Access UserDefaults directly
```swift
// Bad
UserDefaults.standard.set(95, forKey: "score")
```

### 5. MVVM Pattern
✅ **DO:** Use ViewModels to coordinate between services and views
```swift
class CredibilityStatusViewModel: ObservableObject {
    @Published var status: CredibilityStatus
    private let credibilityService: CredibilityService

    init(credibilityService: CredibilityService) {
        self.credibilityService = credibilityService
        self.status = credibilityService.getCredibilityStatus()
    }
}
```

---

## Best Practices

### File Organization
1. **One responsibility per file** - Don't create god files
2. **Group related files** - Use directories (Services/, Repositories/, etc.)
3. **Consistent naming** - `ServiceImpl`, `Repository`, `ViewModel` suffixes
4. **Keep files under 500 lines** - Split if larger

### Coding Standards
1. **Use MARK comments** for organization
   ```swift
   // MARK: - Public Methods
   // MARK: - Private Helpers
   // MARK: - Protocol Conformance
   ```

2. **Write descriptive names** - No abbreviations
   ```swift
   // Good
   func processApprovedTask(taskId: UUID, reviewerId: UUID)

   // Bad
   func procTask(tid: UUID, rid: UUID)
   ```

3. **Document complex logic** with inline comments
   ```swift
   // Calculate stacked penalty if last downvote was within 7 days
   if let lastDate = lastDownvoteDate,
      daysSince(lastDate) <= 7 {
       return -15
   }
   ```

4. **Use guard statements** for early returns
   ```swift
   guard let xp = xpAmount, xp > 0 else {
       return nil
   }
   ```

### Testing Standards
1. **Test naming:** `testMethodName_Scenario_ExpectedResult`
   ```swift
   func testProcessDownvote_RecentDownvote_AppliesStackedPenalty()
   ```

2. **Arrange-Act-Assert** pattern
   ```swift
   func testSaveScore() {
       // Arrange
       let repo = CredibilityRepository(storage: mockStorage)

       // Act
       repo.saveScore(85)

       // Assert
       XCTAssertEqual(repo.loadScore(), 85)
   }
   ```

3. **Use mock objects** for isolation
   ```swift
   let mockStorage = MockStorage()
   let service = CredibilityServiceImpl(storage: mockStorage, ...)
   ```

4. **Test edge cases** - boundaries, empty states, error conditions

### Git Commit Standards
1. **Format:** `<type>: <description>`
   ```
   feat: add redemption bonus banner component
   fix: resolve Combine import error in ViewModelFactory
   test: add integration tests for credibility workflow
   refactor: extract camera service from ContentView
   docs: update development guide with best practices
   ```

2. **Types:** `feat`, `fix`, `test`, `refactor`, `docs`, `style`, `perf`, `chore`

3. **Keep commits atomic** - One logical change per commit

---

## Troubleshooting Guide

### Common Build Issues

#### 1. Missing Import Errors
**Error:** `initializer 'init(wrappedValue:)' is not available`

**Solution:**
```swift
// Add missing import
import Combine  // For @Published properties
import SwiftUI  // For SwiftUI views
import FamilyControls  // For FamilyActivitySelection
```

#### 2. Xcode Project File Issues
**Error:** New files not showing in Xcode

**Solution:**
```bash
# This project uses PBXFileSystemSynchronizedRootGroup
# Files are auto-detected - just create them in the right location
# No manual Xcode project file editing needed
```

#### 3. Test Build Failures
**Error:** `Scheme not configured for test action`

**Solution:** Check that EnviveNewTests target is included in scheme
```xml
<!-- In Envive.xcscheme -->
<TestAction>
  <Testables>
    <TestableReference skipped="NO">
      <BuildableReference BlueprintName="EnviveNewTests" />
    </TestableReference>
  </Testables>
</TestAction>
```

#### 4. Module Not Found
**Error:** `No such module 'Supabase'`

**Solution:**
```bash
# Clean and rebuild
xcodebuild clean -project EnviveNew.xcodeproj -scheme Envive
xcodebuild build -project EnviveNew.xcodeproj -scheme Envive
```

### Runtime Issues

#### 1. Dependency Injection Failures
**Problem:** Services not working, crashes on init

**Checklist:**
- [ ] Is service registered in DependencyContainer?
- [ ] Are all dependencies injected in init?
- [ ] Is DependencyContainer.shared being used?
- [ ] Are protocols implemented correctly?

#### 2. Storage Not Persisting
**Problem:** Data lost between app launches

**Checklist:**
- [ ] Using repository pattern (not direct UserDefaults)?
- [ ] Are storage keys consistent?
- [ ] Is data being saved after changes?
- [ ] Check UserDefaults suite name

#### 3. UI Not Updating
**Problem:** Changes not reflected in UI

**Checklist:**
- [ ] Is ViewModel ObservableObject?
- [ ] Are properties @Published?
- [ ] Is @StateObject used for ViewModel?
- [ ] Is @EnvironmentObject passed down?

---

## Prompt Templates

### When Requesting New Features

```markdown
**Feature Request Template:**

Add [feature name] with the following requirements:
- [Requirement 1]
- [Requirement 2]

**Acceptance Criteria:**
- [ ] Follows MVVM pattern
- [ ] Uses dependency injection
- [ ] Includes unit tests (minimum 5)
- [ ] Uses existing components where possible
- [ ] Compiles without errors
- [ ] Updates documentation

**Example:** "Add a weekly credibility report feature that shows score trends over time, uses CredibilityService via DI, includes a reusable chart component, and has tests for trend calculation logic."
```

### When Reporting Bugs

```markdown
**Bug Report Template:**

**Issue:** [Brief description]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Behavior:** [What should happen]

**Actual Behavior:** [What actually happens]

**Error Message:**
```
[Paste full error if available]
```

**Files Involved:**
- [List relevant files]

**Environment:**
- Xcode version: [version]
- iOS version: [version]
- Device: [simulator/device]

**Example:** "CredibilityService crashes when processing downvote. Steps: 1) Open app, 2) Reject task, 3) App crashes. Error: 'Index out of bounds in credibilityHistory array'. File: CredibilityServiceImpl.swift:183"
```

### When Refactoring Code

```markdown
**Refactoring Request Template:**

Refactor [component/class name] to follow project architecture:

**Current Issues:**
- [Issue 1: e.g., God class with 1000+ lines]
- [Issue 2: e.g., Direct UserDefaults access]
- [Issue 3: e.g., No dependency injection]

**Desired Outcome:**
- [ ] Break into smaller, focused classes
- [ ] Add protocol abstraction
- [ ] Use dependency injection
- [ ] Add tests (if missing)
- [ ] Maintain backward compatibility
- [ ] Document changes

**Example:** "Refactor ParentDashboardView (currently 500 lines) to use new component library, extract ParentDashboardViewModel, use ViewModelFactory for DI, and add 8+ tests for key functionality."
```

### When Adding Tests

```markdown
**Testing Request Template:**

Add tests for [component name]:

**Test Coverage Needed:**
- [ ] Happy path scenarios
- [ ] Edge cases (empty, nil, boundaries)
- [ ] Error conditions
- [ ] Integration with other services

**Target:** [X tests, Y% coverage]

**Files to Test:**
- [File 1]
- [File 2]

**Example:** "Add comprehensive tests for XPRedemptionViewModel covering: valid/invalid amounts, conversion preview calculation, redemption success/failure, and integration with CredibilityService. Target: 12 tests, 85%+ coverage."
```

### When Debugging Build Issues

```markdown
**Build Issue Template:**

**Error:** [Copy exact error message]

**Command Used:**
```bash
[Paste command that failed]
```

**Last Successful Build:** [When it last worked]

**Recent Changes:**
- [Change 1]
- [Change 2]

**Attempted Solutions:**
- [ ] Clean build folder
- [ ] Check imports
- [ ] Verify file paths
- [ ] Check scheme configuration

**Example:**
**Error:** "Module 'Combine' not found in ViewModelFactory.swift"
**Command:** `xcodebuild build -project EnviveNew.xcodeproj -scheme Envive`
**Recent Changes:** Added ViewModelFactory.swift with @Published properties
**Solution Needed:** Add missing import statement
```

### When Creating Components

```markdown
**Component Creation Template:**

Create [component name] following these specs:

**Purpose:** [What does it do?]

**Props/Parameters:**
- [Param 1]: [Type] - [Description]
- [Param 2]: [Type] - [Description]

**Design:**
- Appearance: [Description or reference]
- Behavior: [Interactions]
- Accessibility: [Any special needs]

**Usage Example:**
```swift
[Code showing how component will be used]
```

**Location:** EnviveNew/Components/[Category]/[FileName].swift

**Example:**
Create `TaskProgressIndicator` component
**Purpose:** Shows task completion progress with percentage
**Props:**
- completed: Int - Number completed
- total: Int - Total tasks
- color: Color - Bar color
**Design:** Horizontal bar with percentage label, rounded corners, smooth animation
**Location:** EnviveNew/Components/Task/TaskProgressIndicator.swift
```

---

## Code Standards

### Swift Style Guide

#### Naming Conventions
```swift
// Classes, Structs, Enums, Protocols: PascalCase
class CredibilityService { }
struct TaskItem { }
enum TaskStatus { }
protocol StorageService { }

// Properties, Methods, Variables: camelCase
var credibilityScore: Int
func processApprovedTask() { }

// Constants: camelCase (not SCREAMING_SNAKE_CASE)
let maxScore = 100
let defaultTimeout = 30

// Acronyms: Treat as words
let xpAmount: Int  // Not XPAmount
let urlString: String  // Not URLString
```

#### Code Organization
```swift
// MARK: - Type Definition
struct MyStruct {
    // MARK: - Properties
    let id: UUID
    var name: String

    // MARK: - Initializers
    init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }

    // MARK: - Public Methods
    func doSomething() { }

    // MARK: - Private Methods
    private func helperMethod() { }
}

// MARK: - Protocol Conformance
extension MyStruct: Codable { }

// MARK: - Preview
struct MyStruct_Previews: PreviewProvider {
    static var previews: some View { }
}
```

#### Error Handling
```swift
// DO: Use Result type for operations that can fail
func loadData() -> Result<Data, Error> {
    do {
        let data = try fetchData()
        return .success(data)
    } catch {
        return .failure(error)
    }
}

// DO: Use throwing functions for critical errors
func saveData(_ data: Data) throws {
    try data.write(to: fileURL)
}

// DON'T: Silently ignore errors
func loadData() {
    do {
        let data = try fetchData()
    } catch { } // ❌ Silent failure
}
```

### SwiftUI Best Practices

#### View Composition
```swift
// DO: Break large views into smaller components
struct TaskListView: View {
    var body: some View {
        List {
            ForEach(tasks) { task in
                TaskRow(task: task)  // Extracted component
            }
        }
    }
}

// DON'T: Put everything in one view
struct TaskListView: View {
    var body: some View {
        List {
            ForEach(tasks) { task in
                // 50 lines of UI code here ❌
            }
        }
    }
}
```

#### State Management
```swift
// DO: Use appropriate property wrappers
@StateObject var viewModel: MyViewModel  // For owned objects
@ObservedObject var manager: MyManager   // For passed objects
@EnvironmentObject var model: AppModel   // For environment objects
@State private var isShowing = false     // For local state
@Binding var selectedItem: Item?         // For two-way binding

// DON'T: Create StateObjects in subviews
struct SubView: View {
    @StateObject var model = MyModel()  // ❌ Will recreate on every render
}
```

---

## Testing Guidelines

### Test Structure
```swift
final class MyServiceTests: XCTestCase {
    var sut: MyService!  // System Under Test
    var mockStorage: MockStorage!

    override func setUp() {
        super.setUp()
        mockStorage = MockStorage()
        sut = MyService(storage: mockStorage)
    }

    override func tearDown() {
        sut = nil
        mockStorage = nil
        super.tearDown()
    }

    // MARK: - [Feature] Tests

    func testFeature_Scenario_ExpectedResult() {
        // Arrange
        let input = "test"

        // Act
        let result = sut.process(input)

        // Assert
        XCTAssertEqual(result, "expected")
    }
}
```

### Test Coverage Goals
- **Unit Tests:** 80%+ coverage for business logic
- **Integration Tests:** Cover key user workflows
- **Edge Cases:** Test boundaries, empty states, nil values
- **Error Cases:** Test error handling paths

### Mock Object Pattern
```swift
final class MockCredibilityService: CredibilityService {
    // Track calls
    var processDownvoteCalled = false
    var lastTaskId: UUID?

    // Configurable responses
    var credibilityScoreToReturn = 100

    var credibilityScore: Int {
        credibilityScoreToReturn
    }

    func processDownvote(taskId: UUID, reviewerId: UUID, notes: String?) {
        processDownvoteCalled = true
        lastTaskId = taskId
    }
}
```

---

## Quick Reference: Prompt Formatting

### General Structure
```markdown
1. **Clear Objective** - State what you want accomplished
2. **Context** - Provide relevant background
3. **Constraints** - List requirements/limitations
4. **Success Criteria** - Define what "done" looks like
5. **Examples** - Show desired format if applicable
```

### Effective Prompts

✅ **GOOD:**
```
Refactor ScreenTimeRewardManager to use dependency injection:
- Extract RewardService protocol
- Move to Services/Reward/ directory
- Inject CredibilityService and StorageService
- Add 10+ unit tests covering XP redemption
- Maintain backward compatibility
- Build must succeed without errors

This follows Phase 2 of the refactoring plan where we're establishing DI throughout the app.
```

❌ **BAD:**
```
Fix the rewards thing
```

### When Stuck

**Template:**
```markdown
I'm stuck on [specific issue].

**What I'm trying to do:** [Goal]

**What I've tried:**
1. [Attempt 1] - [Result]
2. [Attempt 2] - [Result]

**Current error:**
```
[Error message]
```

**Relevant files:** [List files]

**Question:** [Specific question]
```

---

## Additional Resources

### Project Documentation
- `_report.md` - Comprehensive refactoring plan and progress
- `DEVELOPMENT_GUIDE.md` - This file
- Inline code comments - Explain complex business logic

### External References
- [Swift Style Guide](https://google.github.io/swift/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [XCTest Documentation](https://developer.apple.com/documentation/xctest)

### Xcode Commands Reference
```bash
# Build project
xcodebuild build -project EnviveNew.xcodeproj -scheme Envive -destination 'generic/platform=iOS'

# Run tests
xcodebuild test -project EnviveNew.xcodeproj -scheme Envive -destination 'platform=iOS Simulator,name=iPhone 16'

# Clean build
xcodebuild clean -project EnviveNew.xcodeproj -scheme Envive

# List schemes
xcodebuild -list -project EnviveNew.xcodeproj
```

---

## Maintenance Checklist

### Before Starting Work
- [ ] Pull latest changes from main
- [ ] Review recent commits
- [ ] Check for failing tests
- [ ] Understand the feature/fix scope

### During Development
- [ ] Follow architecture principles
- [ ] Write tests as you go
- [ ] Keep commits atomic
- [ ] Document complex logic
- [ ] Build frequently

### Before Committing
- [ ] All tests pass
- [ ] No compiler warnings (unless documented)
- [ ] Code formatted consistently
- [ ] Remove debug code
- [ ] Update documentation if needed
- [ ] Review your own changes

### Code Review Checklist
- [ ] Follows project architecture
- [ ] Has adequate tests
- [ ] No hard-coded dependencies
- [ ] Uses protocols for abstraction
- [ ] Properly documented
- [ ] No breaking changes (or documented)

---

## Version History

- **v1.0** (2025-10-12) - Initial guide after Phase 1-6 refactoring
  - Architecture principles established
  - 69 tests, 34 components created
  - MVVM pattern implemented
  - DI throughout codebase

---

**Remember:** When in doubt, ask! Provide context, be specific, and include error messages. Good communication leads to better solutions faster.
