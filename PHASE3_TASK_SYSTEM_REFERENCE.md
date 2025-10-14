# Envive App - Phase 3 Task Assignment System - Complete Reference

**Last Updated:** 2025-10-14
**Status:** Phase 3 Backend Complete, UI Integrated, Child Views Pending

---

## 🎯 PROJECT OVERVIEW

Envive is an iOS SwiftUI app that helps parents manage children's screen time through a task-based reward system. Children complete real-world tasks (chores, homework, etc.) to earn XP, which converts to screen time minutes.

### **Core Concept:**
- Child completes tasks → Parent approves → Child earns XP based on credibility → XP converts 1:1 to screen time minutes

---

## 📋 PHASE 3: TASK ASSIGNMENT SYSTEM (CURRENT)

### **What We Built:**

Phase 3 implements a complete parent approval workflow for task management:

1. **5-Level Task Difficulty System** (Level 1-5)
2. **200+ Pre-seeded Task Templates** (11 categories)
3. **Parent Approval Workflow** (approve/decline/edit)
4. **Photo Evidence Requirement** (all tasks)
5. **Credibility-Based XP Earning** (score = earning percentage)
6. **Simplified 1:1 XP Redemption** (no multipliers)

---

## 🎨 CRITICAL DESIGN DECISIONS

### **1. Task Level System (NOT Duration-Based)**

**IMPORTANT:** Levels represent **SCREEN TIME REWARD**, not work duration.

```
Level 1: 5 XP   = 5 minutes screen time   (Quick tasks: make bed, feed pet)
Level 2: 15 XP  = 15 minutes screen time  (Easy tasks: dishes, vacuum room)
Level 3: 30 XP  = 30 minutes screen time  (Medium tasks: mow lawn, deep clean)
Level 4: 45 XP  = 45 minutes screen time  (Hard tasks: wash car, organize garage)
Level 5: 60 XP  = 60 minutes screen time  (Very hard: weed garden, chop wood)
```

**Example:** "Doing the dishes" might take 20 minutes but is only Level 2 (15 XP) because that's the VALUE the parent assigns to it.

**Parent controls the level** - this prevents gaming the system.

### **2. Credibility System (SIMPLIFIED)**

**Old System (Phase 2):** Complex tiers with different multipliers
**New System (Phase 3):** Direct percentage

```swift
// Credibility Score = Earning Percentage
90 credibility + 100 XP task = 90 XP earned (90% of 100)
50 credibility + 100 XP task = 50 XP earned (50% of 100)
```

**Credibility Changes:**
- ✅ **Approved Task:** +5 credibility (max 100)
- ❌ **Declined Task:** -20 credibility (min 0)

**NO multipliers at redemption** - credibility only affects earning, not spending.

### **3. XP to Screen Time Conversion**

```
1 XP = 1 minute screen time (always)
```

No multipliers, no bonuses, no complexity. Simple 1:1 conversion.

### **4. Photo Evidence Required**

**All tasks require a photo** to prevent dishonesty and gaming.

### **5. Parent Approval Required**

**No XP is awarded until parent reviews and approves the task.**

---

## 📂 FILE STRUCTURE

### **Core Models**

```
EnviveNew/Core/Models/
├── TaskLevel.swift              ✅ COMPLETE - 5 difficulty levels, XP calculations
├── TaskTemplate.swift           ✅ COMPLETE - 200+ seeded tasks, 11 categories
└── TaskAssignment.swift         ✅ COMPLETE - Task instances with status tracking
```

**Key Code Reference:**

```swift
// TaskLevel.swift - Lines 5-45
enum TaskLevel: Int, Codable, CaseIterable {
    case level1 = 1  // 5 XP
    case level2 = 2  // 15 XP
    case level3 = 3  // 30 XP
    case level4 = 4  // 45 XP
    case level5 = 5  // 60 XP

    var baseXP: Int {
        switch self {
        case .level1: return 5
        case .level2: return 15
        case .level3: return 30
        case .level4: return 45
        case .level5: return 60
        }
    }

    func calculateEarnedXP(credibilityScore: Int) -> Int {
        let percentage = Double(credibilityScore) / 100.0
        let earned = Double(baseXP) * percentage
        return max(1, Int(earned))  // Min 1 XP
    }
}
```

### **Repository Layer**

```
EnviveNew/Repositories/
└── TaskRepository.swift         ✅ COMPLETE - Data persistence, caching
```

**Key Methods:**
- `getAllTemplates()` - Get 200+ task templates
- `searchTemplates(query:)` - Search tasks by title/tags
- `getPendingReviewTasks()` - Get tasks awaiting parent approval
- `saveAssignment(_:)` - Persist task assignments

### **Service Layer**

```
EnviveNew/Services/Tasks/
└── TaskService.swift            ✅ COMPLETE - Business logic
```

**Key Methods:**

```swift
// Child Operations
func claimTask(template: TaskTemplate, childId: UUID, level: TaskLevel) -> TaskAssignment
func completeTask(assignmentId: UUID, photoURL: String, notes: String?, timeMinutes: Int?) -> Bool

// Parent Operations
func approveTask(assignmentId: UUID, parentId: UUID, parentNotes: String?, credibilityScore: Int) -> TaskServiceApprovalResult
func approveTaskWithEdits(assignmentId: UUID, parentId: UUID, newLevel: TaskLevel, parentNotes: String?, credibilityScore: Int) -> TaskServiceApprovalResult
func declineTask(assignmentId: UUID, parentId: UUID, reason: String, credibilityScore: Int) -> TaskServiceDeclineResult
```

**Approval Flow (Lines 132-186):**
1. Get task assignment from repository
2. Calculate XP based on level + credibility: `xpService.awardXP()`
3. Increase credibility (+5): `credibilityService.processApprovedTask()`
4. Update assignment status to `.approved`
5. Save assignment and return result

**Decline Flow (Lines 250-294):**
1. Get task assignment
2. Decrease credibility (-20): `credibilityService.processDownvote()`
3. Set status to `.declined`, XP = 0
4. Save and return result

### **Updated Services**

```
EnviveNew/Services/XP/
└── XPServiceImpl.swift          ✅ UPDATED - Simplified credibility

EnviveNew/Services/Credibility/
└── CredibilityCalculator.swift  ✅ UPDATED - New penalties (+5/-20)
```

**XPServiceImpl Changes (Line 91-98):**

```swift
func credibilityMultiplier(score: Int) -> Double {
    // SIMPLIFIED: Credibility score directly = earning percentage
    // 100 credibility = 100% XP (1.0x)
    // 90 credibility = 90% XP (0.9x)
    let percentage = Double(max(0, min(100, score))) / 100.0
    return percentage
}
```

### **Parent Views**

```
EnviveNew/Views/Parent/
├── ParentDashboardView.swift    ✅ COMPLETE - Main parent screen
└── TaskReviewView.swift         ✅ COMPLETE - Approve/decline/edit interface
```

**ParentDashboardView Structure:**

```swift
// Lines 44-79: Pending Approvals Section
// - Shows count badge
// - Lists all pending tasks
// - NavigationLink to TaskReviewView

// Lines 83-102: Empty State
// - "All Caught Up!" when no pending tasks

// Lines 106-129: Quick Actions
// - "Assign Task" button (placeholder)
// - "Emergency Grant" button (placeholder)

// Lines 133-147: Children Overview
// - Shows each child's credibility, XP, pending count
```

**TaskReviewView Features:**

```swift
// Lines 30-94: Task Info Display
// - Task header with title, category, level
// - Photo evidence display
// - Child notes
// - Completion time

// Lines 96-133: Child Stats Section
// - Current credibility score
// - Credibility tier indicator
// - Task completion streak

// Lines 135-168: XP Calculation Display
// - Base XP (from level)
// - × Credibility percentage
// - = Final XP child will earn

// Lines 170-214: Decision Buttons
// - ✅ Approve Button (green)
// - ✏️ Edit Level Button (blue)
// - ❌ Decline Button (red)
```

### **Dependency Injection**

```
EnviveNew/Core/
└── DependencyContainer.swift    ✅ UPDATED - Added TaskService
```

**Added (Lines 38-40, 72-78):**

```swift
lazy var taskRepository: TaskRepository = {
    TaskRepositoryImpl(storage: storage)
}()

lazy var taskService: TaskService = {
    TaskServiceImpl(
        repository: taskRepository,
        xpService: xpService,
        credibilityService: credibilityService
    )
}()
```

### **App Integration**

```
EnviveNew/
└── ContentView.swift            ✅ UPDATED - Tab 5 now shows ParentDashboardView
```

**Integration (Lines 5742-5753):**

```swift
ParentDashboardView(
    viewModel: ParentDashboardViewModel(
        taskService: DependencyContainer.shared.taskService,
        credibilityService: DependencyContainer.shared.credibilityService,
        parentId: UUID() // TODO: Replace with actual parent ID
    )
)
    .tabItem {
        Image(systemName: "checkmark.seal.fill")
        Text("Task Approvals")
    }
    .tag(4)
```

---

## ✅ COMPLETED FEATURES

### **Backend (100% Complete)**

- [x] TaskLevel enum with 5 difficulty levels
- [x] TaskTemplate model with 200+ seeded tasks across 11 categories
- [x] TaskAssignment model with full status tracking
- [x] TaskRepository with caching and persistence
- [x] TaskService with approve/decline/edit logic
- [x] XPService updated to simplified credibility system
- [x] CredibilityService updated with new penalties
- [x] DependencyContainer integration
- [x] All naming conflicts resolved
- [x] Build succeeds without errors

### **UI (Partial - Parent Views Only)**

- [x] ParentDashboardView showing pending approvals
- [x] TaskReviewView with approve/decline/edit interface
- [x] Wired into ContentView Tab 5 "Task Approvals"
- [x] Proper dependency injection
- [x] Navigation between dashboard → review

---

## 🚧 PENDING FEATURES

### **Child-Facing Views (5 Views Needed)**

1. **ChildDashboardView** - Child home screen
   - Show available tasks
   - Display current XP balance
   - Show active tasks
   - Quick stats (credibility, streak)

2. **ChildTasksView** - Task list view
   - Filter by status (available, in-progress, pending review, completed)
   - Search functionality
   - Category filtering

3. **TaskSearchView** - Search 200+ task templates
   - Search bar with live filtering
   - Category tabs
   - Task cards with level suggestions
   - "Claim Task" button

4. **TaskDetailView** - View task details + select level
   - Task description
   - Estimated time
   - Level selector (1-5)
   - XP preview based on current credibility
   - "Start Task" button

5. **TaskInProgressView** - Photo capture + completion
   - Camera integration
   - Photo preview
   - Notes field (optional)
   - Time tracker
   - "Submit for Review" button

### **Additional Parent Views**

6. **AssignTaskView** - Parent assigns tasks to children
   - Search task templates
   - Select child
   - Choose level
   - Set due date (optional)
   - "Assign" button

### **Services**

7. **NotificationService** - Push and in-app notifications
   - Parent notification when child completes task
   - Child notification when parent approves/declines
   - Badge counts for pending approvals

### **Integration Testing**

8. **Complete Workflow Test**
   - Child claims task → starts task → captures photo → submits
   - Parent receives notification → reviews → approves
   - Child receives XP → credibility increases → can redeem for screen time

---

## 🎯 TASK CATEGORIES (11 Total)

```swift
// TaskTemplate.swift - Line 37
enum TaskTemplateCategory: String, Codable {
    case kitchen = "Kitchen & Cooking"           // 🍳 Dishes, cooking, cleanup
    case indoorCleaning = "Indoor Cleaning"      // 🧹 Vacuum, dusting, organizing
    case outdoor = "Outdoor & Yard"              // 🌳 Mowing, weeding, raking
    case petCare = "Pet Care"                    // 🐕 Feeding, walking, grooming
    case automotive = "Automotive"               // 🚗 Washing car, cleaning interior
    case errands = "Errands & Shopping"          // 🛒 Grocery shopping, mail
    case siblingCare = "Sibling Care"            // 👶 Babysitting, helping with homework
    case academic = "Academic & Study"           // 📚 Homework, reading, practice
    case personalDevelopment = "Personal Dev"    // 💪 Exercise, skills, hobbies
    case homeImprovement = "Home Improvement"    // 🔨 Painting, repairs, assembly
    case other = "Other"                         // 📦 Miscellaneous tasks
}
```

---

## 📊 EXAMPLE TASKS BY LEVEL

### Level 1 (5 XP = 5 min)
- Make bed
- Feed pets
- Take out trash
- Put away shoes
- Water plants

### Level 2 (15 XP = 15 min)
- Do dishes
- Vacuum one room
- Clean bathroom sink
- Fold laundry
- Set/clear table

### Level 3 (30 XP = 30 min)
- Mow lawn
- Deep clean bathroom
- Organize closet
- Wash car exterior
- Cook a meal

### Level 4 (45 XP = 45 min)
- Wash & dry car (full detail)
- Clean entire kitchen
- Organize garage section
- Paint a room
- Deep clean carpets

### Level 5 (60 XP = 60 min)
- Weed entire garden
- Chop/stack firewood
- Deep clean whole house
- Organize entire garage
- Major yard work project

---

## 🔧 HOW TO USE THIS REFERENCE IN A NEW CHAT

### **Option 1: Paste This Entire File**

Copy this entire markdown file and paste it at the start of your new chat with:

```
I'm continuing development on the Envive iOS app. Below is the complete reference for Phase 3 (Task Assignment System) that was just completed:

[PASTE ENTIRE CONTENTS OF THIS FILE]

I need help with: [YOUR REQUEST]
```

### **Option 2: Reference Specific Sections**

If you just need to work on a specific feature, paste the relevant sections:

**For Child Views:**
- Paste: "Pending Features → Child-Facing Views"
- Paste: "Critical Design Decisions" (so Claude knows the level system)
- Paste: "File Structure → Core Models"

**For Parent Features:**
- Paste: "Completed Features → UI"
- Paste: "File Structure → Parent Views"
- Paste: "Critical Design Decisions"

**For Service Work:**
- Paste: "File Structure → Service Layer"
- Paste: "Critical Design Decisions → Credibility System"

### **Option 3: Save Key Files as Context**

Tell Claude to read these files directly:

```
Please read these files to understand the Phase 3 Task System:

1. /Users/nealahlstrom/github/Envive/EnviveNew/Core/Models/TaskLevel.swift
2. /Users/nealahlstrom/github/Envive/EnviveNew/Core/Models/TaskTemplate.swift
3. /Users/nealahlstrom/github/Envive/EnviveNew/Core/Models/TaskAssignment.swift
4. /Users/nealahlstrom/github/Envive/EnviveNew/Services/Tasks/TaskService.swift
5. /Users/nealahlstrom/github/Envive/EnviveNew/Views/Parent/ParentDashboardView.swift
6. /Users/nealahlstrom/github/Envive/EnviveNew/Views/Parent/TaskReviewView.swift
7. /Users/nealahlstrom/github/Envive/PHASE3_TASK_SYSTEM_REFERENCE.md

Then help me with: [YOUR REQUEST]
```

---

## 💡 COMMON NEXT TASKS

### **"Build the child dashboard view"**

Paste this reference + request:
```
I need to build ChildDashboardView that shows:
- Available tasks to claim
- Current XP balance
- Active in-progress tasks
- Credibility score

Use the existing ParentDashboardView as a style reference.
```

### **"Build the task search/claim flow"**

```
Build TaskSearchView that allows children to:
1. Search through 200+ task templates
2. Filter by category
3. View task details
4. Select difficulty level (1-5)
5. Claim the task

Remember: Level = screen time reward, not work duration.
```

### **"Add parent task assignment feature"**

```
Build AssignTaskView for parents to assign tasks to children.
Similar to child claiming, but parent-initiated with these differences:
- Parent selects the child
- Parent sets the level (child can't change)
- Optional due date
```

### **"Test the complete workflow"**

```
Help me test the full workflow:
1. Child claims task
2. Child completes and submits with photo
3. Parent receives notification
4. Parent reviews and approves
5. Child receives XP based on credibility
6. Verify credibility increased by +5
```

---

## 🐛 KNOWN ISSUES / TODOS

1. **Parent ID Hardcoded**
   - Location: `ContentView.swift:5746`
   - Current: `parentId: UUID()` (generates new UUID each time)
   - TODO: Replace with actual parent ID from user authentication/session

2. **Child Data Mock**
   - Location: `ParentDashboardView.swift:307-315`
   - Current: Mock ChildSummary with hardcoded data
   - TODO: Load actual children from database/user service

3. **Quick Action Buttons**
   - Location: `ParentDashboardView.swift:112-128`
   - Current: Navigate to placeholder `Text("Assign Task View")`
   - TODO: Build actual AssignTaskView and EmergencyGrantView

4. **No User Authentication**
   - Currently no login system
   - No way to identify parent vs child
   - TODO: Implement user authentication and roles

---

## 📱 HOW TO TEST CURRENT FEATURES

### **1. See the Parent Dashboard**

Run app → Tab 5 "Task Approvals" → You'll see:
- "All Caught Up!" empty state (no pending tasks yet)
- Quick action buttons
- Children overview (mock data)

### **2. Test with Mock Data**

Add to `ParentDashboardViewModel.loadData()`:

```swift
func loadData() {
    // Create mock pending tasks for testing
    let mockTask = TaskAssignment.fromTemplate(
        TaskTemplate(
            id: UUID(),
            title: "Do the dishes",
            description: "Wash, dry, and put away all dishes",
            category: .kitchen,
            suggestedLevel: .level2,
            estimatedMinutes: 15,
            tags: ["dishes", "kitchen", "cleaning"],
            isDefault: true,
            createdBy: nil
        ),
        childId: UUID(),
        assignedBy: parentId,
        level: .level2
    )

    var mockAssignment = mockTask
    mockAssignment.status = .pendingReview
    mockAssignment.completedAt = Date()
    mockAssignment.photoURL = "mock-photo-url"
    mockAssignment.childNotes = "All done! Kitchen is spotless."

    pendingApprovals = [mockAssignment]

    // Rest of existing code...
}
```

### **3. Test Approval Flow**

With mock data above:
1. Tap the pending task card
2. See TaskReviewView with task details
3. Tap "Approve" → Should update credibility and award XP
4. Tap back → Task should be gone from pending list

---

## 🎓 DESIGN PHILOSOPHY

### **Why This System?**

1. **Level ≠ Duration** prevents gaming
   - Parent decides task VALUE
   - Child can't game by claiming "5-hour tasks"

2. **Photo Required** prevents lying
   - Visual evidence for all tasks
   - Builds trust and accountability

3. **Parent Approval Required** prevents cheating
   - Parent verifies work quality
   - Can adjust level if over/under-estimated

4. **Credibility = Earning %** encourages honesty
   - High credibility = earn more XP
   - Low credibility = earn less XP
   - Can recover by being honest

5. **Simple 1:1 Redemption** easy to understand
   - 30 XP earned = 30 minutes screen time
   - No complex math for kids

---

## 🔗 RELATED DOCUMENTATION

### **Previous Phases**

- **Phase 1:** XP System (earning and storage)
- **Phase 2:** Credibility System (original complex tiers)
- **Phase 3:** Task Assignment System ← **CURRENT**

### **Future Phases**

- **Phase 4:** Social Features (friends, sharing, kudos)
- **Phase 5:** Advanced Rewards (achievements, streaks, bonuses)
- **Phase 6:** Analytics Dashboard (parent insights)

---

## 📞 QUICK REFERENCE

### **File Locations**

```
EnviveNew/
├── Core/
│   ├── Models/
│   │   ├── TaskLevel.swift          ✅ 5 levels, XP calculations
│   │   ├── TaskTemplate.swift       ✅ 200+ tasks, 11 categories
│   │   └── TaskAssignment.swift     ✅ Status tracking
│   └── DependencyContainer.swift    ✅ Service injection
├── Repositories/
│   └── TaskRepository.swift         ✅ Data persistence
├── Services/
│   ├── Tasks/
│   │   └── TaskService.swift        ✅ Business logic
│   ├── XP/
│   │   └── XPServiceImpl.swift      ✅ Credibility % earning
│   └── Credibility/
│       └── CredibilityCalculator.swift ✅ +5/-20 penalties
└── Views/
    └── Parent/
        ├── ParentDashboardView.swift    ✅ Main parent screen
        └── TaskReviewView.swift         ✅ Approve/decline UI
```

### **Key Constants**

```swift
// Task Levels
Level 1 = 5 XP
Level 2 = 15 XP
Level 3 = 30 XP
Level 4 = 45 XP
Level 5 = 60 XP

// Credibility Changes
Approved = +5
Declined = -20

// XP Conversion
1 XP = 1 minute (always)

// Credibility Earning
Score % = Earning %
(90 credibility = earn 90% of task XP)
```

---

## ✨ END OF REFERENCE

**Last Build:** ✅ Successful (2025-10-14)
**Next Step:** Build child-facing views (ChildDashboardView, TaskSearchView, etc.)

---

**Version:** 1.0
**Maintained by:** Claude Code Session 2025-10-14
