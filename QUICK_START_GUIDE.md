# Quick Start Guide - For New Claude Code Sessions

## 📋 How to Continue Development in a New Chat

### **Method 1: Full Context (Recommended for Major Work)**

Paste this at the start of your new chat:

```
I'm continuing development on the Envive iOS app. Please read this reference file to get full context:

/Users/nealahlstrom/github/Envive/PHASE3_TASK_SYSTEM_REFERENCE.md

Then help me with: [YOUR SPECIFIC REQUEST]
```

---

### **Method 2: Quick Context (For Small Tasks)**

Use this template:

```
I'm working on the Envive iOS app - an iOS SwiftUI task/screen-time management system.

CONTEXT:
- Phase 3 Task System is complete (backend + parent views)
- 5-level task difficulty system (Level 1=5 XP, Level 2=15 XP, up to Level 5=60 XP)
- Level = screen time reward (NOT work duration)
- Parent must approve all tasks before XP is awarded
- Credibility score = earning percentage (90 credibility = earn 90% of XP)
- 1 XP = 1 minute screen time (always)
- Photo required for all tasks

COMPLETED:
✅ ParentDashboardView - shows pending task approvals
✅ TaskReviewView - approve/decline/edit interface
✅ TaskService - business logic
✅ TaskRepository - data persistence
✅ 200+ pre-seeded task templates

NEXT: [YOUR REQUEST]

Reference file: /Users/nealahlstrom/github/Envive/PHASE3_TASK_SYSTEM_REFERENCE.md
```

---

### **Method 3: File-Based Context**

```
Please read these files to understand the task system:

1. /Users/nealahlstrom/github/Envive/PHASE3_TASK_SYSTEM_REFERENCE.md
2. /Users/nealahlstrom/github/Envive/EnviveNew/Core/Models/TaskLevel.swift
3. /Users/nealahlstrom/github/Envive/EnviveNew/Views/Parent/ParentDashboardView.swift

I need help with: [YOUR REQUEST]
```

---

## 🎯 Common Requests - Copy & Paste Templates

### **Build Child Dashboard**

```
Read reference: /Users/nealahlstrom/github/Envive/PHASE3_TASK_SYSTEM_REFERENCE.md

Build ChildDashboardView with these sections:
1. XP Balance display
2. Credibility score indicator
3. Available tasks (search/browse)
4. Active tasks in progress
5. Recently completed tasks

Use ParentDashboardView.swift as a style reference. Match the existing UI patterns.
```

### **Build Task Search/Claim Flow**

```
Read reference: /Users/nealahlstrom/github/Envive/PHASE3_TASK_SYSTEM_REFERENCE.md

Build TaskSearchView for children to:
- Search 200+ task templates (use TaskRepository.searchTemplates)
- Filter by 11 categories
- View task details
- Select level 1-5 (IMPORTANT: level = reward, not duration)
- Claim task (TaskService.claimTask)

Then build TaskDetailView for showing full task info + level selection.
```

### **Build Task Completion Flow**

```
Read reference: /Users/nealahlstrom/github/Envive/PHASE3_TASK_SYSTEM_REFERENCE.md

Build TaskInProgressView for completing tasks:
- Camera integration (photo required)
- Photo preview
- Optional notes field
- Time tracker
- Submit button (TaskService.completeTask)

Task should go to .pendingReview status after submission.
```

### **Add Mock Data for Testing**

```
Read: /Users/nealahlstrom/github/Envive/PHASE3_TASK_SYSTEM_REFERENCE.md
Section: "How to Test Current Features → Test with Mock Data"

Add mock pending tasks to ParentDashboardViewModel so I can test the approval UI.
Create 3-5 different tasks across different categories and levels.
```

### **Fix a Bug**

```
Context: Envive iOS app, Phase 3 Task System complete
Reference: /Users/nealahlstrom/github/Envive/PHASE3_TASK_SYSTEM_REFERENCE.md

Issue: [DESCRIBE THE BUG]

Relevant files: [LIST FILES IF KNOWN]
```

---

## 🔑 Key File Paths (Copy-Paste Ready)

### **Reference Documents**
```
/Users/nealahlstrom/github/Envive/PHASE3_TASK_SYSTEM_REFERENCE.md
/Users/nealahlstrom/github/Envive/QUICK_START_GUIDE.md
```

### **Core Models**
```
/Users/nealahlstrom/github/Envive/EnviveNew/Core/Models/TaskLevel.swift
/Users/nealahlstrom/github/Envive/EnviveNew/Core/Models/TaskTemplate.swift
/Users/nealahlstrom/github/Envive/EnviveNew/Core/Models/TaskAssignment.swift
```

### **Services**
```
/Users/nealahlstrom/github/Envive/EnviveNew/Services/Tasks/TaskService.swift
/Users/nealahlstrom/github/Envive/EnviveNew/Repositories/TaskRepository.swift
/Users/nealahlstrom/github/Envive/EnviveNew/Core/DependencyContainer.swift
```

### **Parent Views**
```
/Users/nealahlstrom/github/Envive/EnviveNew/Views/Parent/ParentDashboardView.swift
/Users/nealahlstrom/github/Envive/EnviveNew/Views/Parent/TaskReviewView.swift
```

### **App Entry Point**
```
/Users/nealahlstrom/github/Envive/EnviveNew/EnviveNewApp.swift
/Users/nealahlstrom/github/Envive/EnviveNew/ContentView.swift
```

---

## ⚡ Critical Design Rules (Always Mention)

When asking for help, always include these if relevant:

1. **Level = Screen Time Reward (NOT duration)**
   - Level 2 (15 XP) might be a 30-minute task
   - Parent controls level to prevent gaming

2. **Photo Required for ALL Tasks**
   - No exceptions

3. **Parent Approval Required**
   - Child doesn't get XP until approved

4. **Credibility = Earning Percentage**
   - 90 credibility = earn 90% of task XP
   - Approved: +5, Declined: -20

5. **1 XP = 1 Minute Always**
   - No multipliers, no complexity

---

## 🚨 Common Pitfalls to Avoid

When starting a new chat, make sure Claude knows:

1. ✅ **We already built the parent approval views** (don't rebuild them)
2. ✅ **TaskService is complete** (don't change the API)
3. ✅ **200+ tasks are pre-seeded** (don't create new templates)
4. ✅ **Credibility system is simplified** (don't use old tier multipliers)
5. ✅ **Phase 3 is integrated into ContentView Tab 5** (don't recreate navigation)

---

## 📱 How to Test Your Changes

Always include in your request if you want testing help:

```
After you make the changes, also:
1. Verify the build succeeds
2. Show me how to test the new feature
3. Add mock data if needed for testing
```

---

## 💾 Save This File!

**Important:** Keep these files safe:
- `PHASE3_TASK_SYSTEM_REFERENCE.md` - Complete technical reference
- `QUICK_START_GUIDE.md` - This file (quick templates)

They contain ALL the context about your Phase 3 implementation.

---

**Last Updated:** 2025-10-14
