# Credibility System - Complete Transaction Chain Audit

## Purpose
Verify that ALL credibility transactions work correctly end-to-end, with proper calculations, UI updates, and cascading effects. Reference the PRD (EnviveNew_PRD.md lines 194-266) as the source of truth for expected behavior.

---

## AUDIT CHECKLIST

### 1. DOWNVOTE TRANSACTION CHAIN

**Test Case 1A: First Downvote (Self-Downvote)**
```
Starting State:
- Credibility: 100
- Conversion Rate: 1.2x (Excellent tier)
- Streak: 5 consecutive approved tasks
- XP Balance: 1000

Action: Downvote own post in Social tab

Expected Results:
✓ Credibility drops to 90 (-10 penalty for first downvote)
✓ Tier changes from "Excellent" to "Excellent" (90 still in 90-100 range)
✓ Conversion rate stays 1.2x
✓ Streak resets to 0
✓ History shows downvote event with -10 amount
✓ Home tab credibility card shows 90
✓ Home tab color stays green (80-100 = green)
✓ If converting 1000 XP: still gets 1200 minutes (1000 × 1.2)

Files to Check:
- ContentView.swift → downvotePost() function
- CredibilityManager.swift → processDownvote()
- EnhancedHomeView → credibility display (line ~6269)
- ScreenTimeRewardManager.swift → redeemXPForScreenTime()
```

**Test Case 1B: Stacking Downvote (Within 7 Days)**
```
Starting State:
- Credibility: 90 (from Test 1A)
- Last downvote: Today
- Streak: 0

Action: Downvote own post again immediately

Expected Results:
✓ Credibility drops to 75 (-15 stacking penalty, not -10)
✓ Tier changes from "Excellent" (90-100) to "Good" (75-89)
✓ Conversion rate drops from 1.2x to 1.0x
✓ Streak stays at 0
✓ History shows second downvote with -15 amount
✓ Home tab shows 75
✓ Home tab color stays green (75 in green range)
✓ If converting 1000 XP: now gets 1000 minutes (1000 × 1.0)
✓ Lost 200 minutes compared to Test 1A

Files to Check:
- CredibilityManager.swift → calculateDownvotePenalty() (checks 7-day window)
- CredibilityManager.swift → getCurrentTier() (returns correct tier)
```

**Test Case 1C: Multiple Downvotes to Red Zone**
```
Starting State:
- Credibility: 75

Action: Downvote own post 3 more times

Expected Results After 3rd Downvote:
✓ Credibility approximately 30-40 (multiple -15 penalties)
✓ Tier: "Very Poor" (0-39 range)
✓ Conversion rate: 0.3x
✓ Home tab color: RED (0-49 = red)
✓ If converting 1000 XP: gets only 300 minutes (1000 × 0.3)
✓ Lost 900 minutes compared to starting 1.2x rate

Verify:
- EnhancedHomeView → credibilityColor() function returns .red
```

---

### 2. UNDO DOWNVOTE TRANSACTION CHAIN

**Test Case 2A: Undo via Red Button**
```
Starting State:
- Credibility: 90 (after one downvote from 100)
- Last downvote penalty: -10
- Red button (🔻) is active on post

Action: Tap red downvote button again

Expected Results:
✓ Credibility restores to 100 (+10, exact reversal)
✓ Tier back to "Excellent"
✓ Conversion rate back to 1.2x
✓ Red button becomes orange (🔸)
✓ History shows "downvote_undone" event with +10 amount
✓ Home tab shows 100
✓ Converting 1000 XP gives 1200 minutes again

Files to Check:
- ContentView.swift → downvotePost() (when hasDownvoted is true)
- CredibilityManager.swift → undoDownvote()
```

**Test Case 2B: Undo via Like Button (Green Circle)**
```
Starting State:
- Credibility: 90 (after downvote)
- Red button active, green button inactive

Action: Tap green like button (⚪ → 🟢)

Expected Results:
✓ Credibility restores to 100 (+10)
✓ Tier back to "Excellent"
✓ Conversion rate back to 1.2x
✓ Red button becomes orange (🔸)
✓ Green button becomes filled (🟢)
✓ History shows "downvote_undone" event
✓ Home tab shows 100
✓ Console shows: "💚 Switched from downvote to like"

Files to Check:
- ContentView.swift → likePost() (lines 4542-4577)
```

**Test Case 2C: Undo Stacking Penalty**
```
Starting State:
- Credibility: 75 (after -10, then -15 stacking penalty)
- Last penalty was -15

Action: Tap red button to undo most recent downvote

Expected Results:
✓ Credibility restores to 90 (+15, not +10)
✓ Undoes EXACT amount of last penalty
✓ History shows +15 restoration
✓ Tier back to "Excellent"
✓ Conversion rate back to 1.2x

Verify:
- CredibilityManager.swift → undoDownvote() uses abs(downvoteEvent.amount)
```

---

### 3. APPROVED TASK TRANSACTION CHAIN

**Test Case 3A: Single Approved Task**
```
Starting State:
- Credibility: 90
- Streak: 0

Action: Complete a task → Parent approves in TaskVerificationView

Expected Results:
✓ Credibility increases to 92 (+2)
✓ Streak increases to 1
✓ History shows "approved_task" event with +2
✓ No bonus yet (needs 10 for bonus)
✓ If was at 88, might cross tier boundary to "Excellent" at 90

Files to Check:
- CredibilityManager.swift → processApprovedTask()
- TaskVerificationView.swift → approveTask() function
```

**Test Case 3B: Streak Bonus (10 Consecutive)**
```
Starting State:
- Credibility: 80
- Streak: 9 consecutive approved tasks

Action: Complete 10th task → Parent approves

Expected Results:
✓ Credibility increases to 82 (+2 for task)
✓ THEN immediately increases to 87 (+5 bonus)
✓ Total gain: +7 points
✓ Streak counter shows 10
✓ History shows TWO events:
  1. "approved_task" with +2
  2. "streak_bonus" with +5
✓ Notification sent: "10 consecutive approved tasks! +5 bonus"
✓ Crossed from "Good" (80) to "Good" (87)

Files to Check:
- CredibilityManager.swift → processApprovedTask() (checks streak % 10)
- CredibilityManager.swift → applyStreakBonus()
- CredibilityNotifications.swift → notifyStreakBonus()
```

**Test Case 3C: Downvote Breaks Streak**
```
Starting State:
- Credibility: 87
- Streak: 10

Action: Get downvoted

Expected Results:
✓ Credibility drops to 77 (-10)
✓ Streak resets to 0 (IMPORTANT: loses progress toward next bonus)
✓ Tier drops from "Good" (87) to "Good" (77)
✓ Must rebuild streak from scratch

Verify:
- CredibilityManager.swift → processDownvote() sets consecutiveApprovedTasks = 0
```

---

### 4. REDEMPTION BONUS TRANSACTION CHAIN

**Test Case 4A: Redemption Bonus Unlock**
```
Starting State:
- Credibility: 58 (Poor tier, 0.5x rate)
- No redemption bonus
- Converting 1000 XP = 500 minutes

Action: Complete 19 approved tasks (19 × 2 = +38 points)

Expected Results:
✓ Credibility increases from 58 to 96
✓ Crosses threshold: 95+ and came from below 60
✓ Redemption bonus activates automatically
✓ Bonus expiry set to 7 days from now
✓ Conversion rate becomes 1.2x × 1.3x = 1.56x
✓ History shows "redemption_bonus_activated" event
✓ Notification sent: "Redemption bonus unlocked!"
✓ Converting 1000 XP now = 1560 minutes (massive jump from 500)

Files to Check:
- CredibilityManager.swift → processApprovedTask() checks redemption eligibility
- CredibilityManager.swift → activateRedemptionBonus()
- CredibilityNotifications.swift → notifyRedemptionBonusUnlocked()
```

**Test Case 4B: Redemption Bonus Lost via Downvote**
```
Starting State:
- Credibility: 96 (with active redemption bonus)
- Conversion rate: 1.56x

Action: Get downvoted

Expected Results:
✓ Credibility drops to 86 (-10)
✓ Falls below 95 threshold
✓ Redemption bonus DEACTIVATES immediately
✓ Conversion rate drops from 1.56x to 1.0x (Good tier)
✓ History shows "redemption_bonus_expired" event
✓ Converting 1000 XP: was 1560 min, now 1000 min (lost 560 minutes)

Verify:
- CredibilityManager.swift → processDownvote() checks if bonus should be lost
- CredibilityManager.swift → deactivateRedemptionBonus()
```

**Test Case 4C: Redemption Bonus 7-Day Expiry**
```
Starting State:
- Credibility: 96
- Redemption bonus active
- Bonus activated 7 days ago

Action: Open app on day 8 OR call applyTimeBasedDecay()

Expected Results:
✓ Bonus automatically expires
✓ Conversion rate drops from 1.56x to 1.2x
✓ Notification sent: "Redemption bonus expired"
✓ Can re-earn by dropping below 60 and climbing back to 95+

Verify:
- CredibilityManager.swift → init() calls checkRedemptionBonusExpiry()
```

---

### 5. TIME-BASED DECAY TRANSACTION CHAIN

**Test Case 5A: 30-Day Half Decay**
```
Starting State:
- Credibility: 70
- Downvote history:
  - Downvote 1: 32 days ago, -10 points
  - Downvote 2: 15 days ago, -10 points

Action: Call applyTimeBasedDecay()

Expected Results:
✓ Downvote 1 (32 days old): 50% decay applied
  - Was -10, now recovers +5 points
✓ Downvote 2 (15 days old): No decay yet (< 30 days)
✓ Credibility increases to 75 (+5)
✓ History shows "time_decay_recovery" event with +5
✓ Downvote 1 marked as "decayed: true" in history
✓ Tier might change from "Fair" (70) to "Good" (75)

Files to Check:
- CredibilityManager.swift → applyTimeBasedDecay()
```

**Test Case 5B: 60-Day Full Decay**
```
Starting State:
- Credibility: 75
- Downvote history:
  - Downvote 1: 62 days ago (already half-decayed), contributed -5
  - Downvote 2: 35 days ago (half-decayed), contributed -5

Action: Call applyTimeBasedDecay()

Expected Results:
✓ Downvote 1 (62 days): Full removal
  - Recovers remaining +5 points
✓ Downvote 2 (35 days): Already decayed, no change
✓ Credibility increases to 80 (+5)
✓ Downvote 1 removed from history entirely
✓ Tier changes from "Good" (75) to "Excellent" (80)? No, still "Good"

Verify:
- Old events removed from credibilityHistory array
```

---

### 6. XP CONVERSION ACCURACY AUDIT

**Test Case 6A: Conversion at Each Tier**
```
Input: 1000 XP, No Redemption Bonus

Expected Outputs by Credibility:
✓ Score 100 (Excellent, 1.2x): 1000 × 1.2 = 1200 minutes
✓ Score 90 (Excellent, 1.2x): 1000 × 1.2 = 1200 minutes
✓ Score 89 (Good, 1.0x): 1000 × 1.0 = 1000 minutes
✓ Score 75 (Good, 1.0x): 1000 × 1.0 = 1000 minutes
✓ Score 74 (Fair, 0.8x): 1000 × 0.8 = 800 minutes
✓ Score 60 (Fair, 0.8x): 1000 × 0.8 = 800 minutes
✓ Score 59 (Poor, 0.5x): 1000 × 0.5 = 500 minutes
✓ Score 40 (Poor, 0.5x): 1000 × 0.5 = 500 minutes
✓ Score 39 (Very Poor, 0.3x): 1000 × 0.3 = 300 minutes
✓ Score 0 (Very Poor, 0.3x): 1000 × 0.3 = 300 minutes

Files to Check:
- CredibilityManager.swift → calculateXPToMinutes()
- CredibilityManager.swift → getCurrentTier()
- CredibilityManager.swift → tiers array (lines 115-151)
```

**Test Case 6B: Conversion with Redemption Bonus**
```
Input: 1000 XP, With Redemption Bonus (1.3x additional)

Expected Outputs:
✓ Score 96 (Excellent + Bonus): 1000 × 1.2 × 1.3 = 1560 minutes
✓ Score 90 (Excellent + Bonus): 1000 × 1.2 × 1.3 = 1560 minutes
✓ Score 75 (Good + Bonus): 1000 × 1.0 × 1.3 = 1300 minutes
✓ Score 60 (Fair + Bonus): 1000 × 0.8 × 1.3 = 1040 minutes

Verify:
- CredibilityManager.swift → calculateXPToMinutes() uses both multipliers
```

**Test Case 6C: User-Provided Example (From Chat)**
```
Input:
- XP: 72
- Current Minutes: 45
- Credibility: 55 (Poor tier, 0.5x)

Expected Calculation:
✓ Tier: Poor (40-59 range)
✓ Multiplier: 0.5x
✓ Minutes from XP: 72 × 0.5 = 36 minutes
✓ Total after conversion: 45 + 36 = 81 minutes

Verify in App:
- Actually convert 72 XP at 55 credibility
- Check final minutes earned value
```

---

### 7. UI UPDATE CHAIN AUDIT

**Test Case 7A: Home Tab Updates**
```
Starting State: Credibility 100

Actions:
1. Downvote own post (100 → 90)
2. Check Home tab
3. Undo downvote (90 → 100)
4. Check Home tab

Expected UI Updates:
✓ Credibility card shows 90 after downvote
✓ Color stays green (90 in green range)
✓ Credibility card shows 100 after undo
✓ Updates happen WITHOUT navigating away and back
✓ Changes are immediate (via @Published property)

Files to Check:
- ContentView.swift → EnhancedHomeView reads model.credibilityManager.credibilityScore
- ContentView.swift → credibilityColor() function
- EnhancedScreenTimeModel → credibilityManager is @Published
```

**Test Case 7B: Credibility Tab Updates**
```
Action: Downvote own post

Expected Updates in Credibility Tab:
✓ Current State card shows new score
✓ Tier label updates (if tier changed)
✓ Conversion rate updates
✓ Streak counter resets to 0
✓ History Events increases by 1
✓ Conversion calculator shows new rates for all XP amounts

Verify:
- CredibilityTestingView → currentStateCard reads credibilityManager state
```

**Test Case 7C: Social Tab Button States**
```
Action Flow:
1. Tap orange diamond (🔸) → becomes red (🔻)
2. Tap green circle (⚪) → becomes green (🟢), red becomes orange (🔸)
3. Tap green circle again (🟢) → becomes white (⚪)

Expected States:
✓ Only one reaction active at a time (downvote OR like)
✓ Counts update correctly
✓ Button colors change immediately
✓ Credibility updates correctly at each step

Verify:
- ContentView.swift → SocialPostView
- userHasLiked and userHasDownvoted computed properties
```

---

### 8. NOTIFICATION CHAIN AUDIT

**Test Case 8A: Downvote Notification**
```
Action: Get downvoted

Expected:
✓ Notification appears: "❌ Task Rejected"
✓ Body shows: "You lost X credibility points"
✓ Shows new score and conversion rate
✓ Includes appeal action button (if within 24 hours)
✓ Category: "CREDIBILITY_TASK_REJECTED"
✓ Sound: Critical sound (not default)

Files to Check:
- CredibilityNotifications.swift → notifyTaskRejected()
```

**Test Case 8B: Streak Bonus Notification**
```
Action: Complete 10th consecutive task

Expected:
✓ Notification: "🔥 Streak Bonus!"
✓ Body: "10 consecutive approved tasks! +5 bonus"
✓ Shows new score
✓ Sound: Default sound
✓ Badge updates

Verify:
- CredibilityNotifications.swift → notifyStreakBonus()
- Called from CredibilityManager.swift → applyStreakBonus()
```

**Test Case 8C: Low Credibility Warning**
```
Action: Credibility drops below 60

Expected:
✓ Notification: "⚠️ Low Credibility"
✓ Body explains impact on conversion rate
✓ Shows recovery path
✓ Sound: Critical sound

Verify:
- CredibilityNotifications.swift → notifyLowCredibility()
```

---

### 9. PARENT-CHILD WORKFLOW CHAIN

**Test Case 9A: Task Approval Flow**
```
Flow:
1. Child completes task with photo
2. Task appears in parent's TaskVerificationView
3. Parent approves task
4. Child's credibility increases

Expected Chain:
✓ TaskVerificationView shows pending task
✓ Shows child's current credibility score
✓ Shows impact preview: "+2 points"
✓ On approve:
  - Task status → approved
  - Child credibility +2
  - Streak +1
  - Notification sent to child
  - Task removed from pending list

Files to Check:
- TaskVerificationView.swift → approveTask() function
- CredibilityManager.swift → processApprovedTask()
```

**Test Case 9B: Task Rejection Flow**
```
Flow:
1. Parent rejects task
2. Must provide notes
3. Child's credibility decreases

Expected Chain:
✓ RejectTaskSheet appears (requires notes)
✓ Shows credibility impact: "-10 or -15 points"
✓ Shows appeal deadline (24 hours from now)
✓ On reject:
  - Task status → rejected
  - Child credibility drops
  - Streak resets to 0
  - Notification sent with appeal option
  - Appeal deadline stored

Verify:
- TaskVerificationView.swift → RejectTaskSheet
- CredibilityManager.swift → processDownvote()
```

**Test Case 9C: Appeal Workflow**
```
Flow:
1. Child receives rejection notification
2. Child taps "Appeal" button
3. Child submits appeal notes
4. Parent reviews appeal
5. Parent makes final decision

Expected Chain:
✓ TaskAppealSheet shows 24-hour countdown
✓ Appeal status: pending → reviewed
✓ If upheld: no credibility change
✓ If overturned: credibility penalty undone
✓ Notifications sent at each step

Files to Check:
- CredibilitySafeguards.swift → TaskAppealSheet
- TaskVerificationView.swift → appeal review interface
```

---

### 10. EDGE CASES & BOUNDARY TESTING

**Test Case 10A: Maximum Score Boundary**
```
Starting State: Credibility 98

Action: Complete approved task (+2)

Expected:
✓ Score caps at 100 (not 102)
✓ No points wasted
✓ Stays in Excellent tier

Verify:
- CredibilityManager.swift → min(maximumScore, credibilityScore + bonus)
```

**Test Case 10B: Minimum Score Boundary**
```
Starting State: Credibility 8

Action: Get downvoted (-10)

Expected:
✓ Score caps at 0 (not -2)
✓ Still in Very Poor tier
✓ Conversion rate stays at 0.3x minimum

Verify:
- CredibilityManager.swift → max(minimumScore, credibilityScore + penalty)
```

**Test Case 10C: Tier Boundary Transitions**
```
Test Exact Boundaries:
- 89 → 90: Good → Excellent (rate 1.0x → 1.2x)
- 90 → 89: Excellent → Good (rate 1.2x → 1.0x)
- 74 → 75: Fair → Good (rate 0.8x → 1.0x)
- 75 → 74: Good → Fair (rate 1.0x → 0.8x)
- 59 → 60: Poor → Fair (rate 0.5x → 0.8x)
- 60 → 59: Fair → Poor (rate 0.8x → 0.5x)
- 39 → 40: Very Poor → Poor (rate 0.3x → 0.5x)
- 40 → 39: Poor → Very Poor (rate 0.5x → 0.3x)

Expected:
✓ Conversion rate changes immediately at boundary
✓ Color coding changes appropriately
✓ Tier name updates in all UI locations
```

**Test Case 10D: Rapid Actions (Spam Protection)**
```
Action: Rapidly tap downvote/like buttons 10 times in 2 seconds

Expected:
✓ Each action processes correctly
✓ Credibility doesn't get out of sync
✓ UI doesn't crash or freeze
✓ Final state matches number of actions
✓ History shows all events in correct order
```

**Test Case 10E: Zero XP Conversion**
```
Input: 0 XP, Any Credibility

Expected:
✓ 0 × multiplier = 0 minutes
✓ No error or crash
✓ Conversion still shows rate for reference
```

---

## AUDIT EXECUTION PLAN

### Step 1: Manual Testing
Go through each test case above:
1. Document starting state
2. Perform action
3. Check ALL expected results (use checkboxes)
4. Note any discrepancies
5. Check console logs for transaction messages

### Step 2: Automated Testing
Run existing test suite:
```bash
# In Xcode, navigate to:
EnviveNew/CredibilityTests.swift

# Run all tests (Cmd+U)
```
Expected: All 24 tests pass

### Step 3: Cross-Reference with PRD
For each implemented feature, verify against PRD requirements:
- Lines 206-208: Downvote penalties ✓
- Lines 209-211: Recovery mechanisms ✓
- Lines 212-214: Time decay ✓
- Lines 220-225: Tier multipliers ✓
- Line 226: Redemption bonus ✓

### Step 4: Transaction Log Analysis
Enable verbose logging and watch console during each test:
- Look for transaction messages (🔻, ↩️, ✨, 💚, 🔄, etc.)
- Verify amounts match expected values
- Check timing of cascading effects

### Step 5: Database State Verification
After each test, check UserDefaults:
```swift
// In CredibilityManager, add debug function:
func printDebugState() {
    print("=== CREDIBILITY DEBUG STATE ===")
    print("Score: \(credibilityScore)")
    print("Streak: \(consecutiveApprovedTasks)")
    print("Redemption Bonus: \(hasRedemptionBonus)")
    print("History Events: \(credibilityHistory.count)")
    print("Last 3 Events:")
    for event in credibilityHistory.suffix(3) {
        print("  - \(event.event.rawValue): \(event.amount) -> \(event.newScore)")
    }
    print("==============================")
}
```

---

## ISSUE TRACKING TEMPLATE

When you find a discrepancy, document it:

```markdown
### Issue #X: [Brief Description]

**Test Case**: [Number and name]

**Expected**:
[What should happen]

**Actual**:
[What actually happened]

**Credibility Impact**:
- Expected: [score/tier/rate]
- Actual: [score/tier/rate]
- Difference: [amount]

**Files Involved**:
- [File:line]

**Reproduction Steps**:
1. [Step 1]
2. [Step 2]

**Console Output**:
```
[Paste relevant logs]
```

**Priority**: High/Medium/Low
```

---

## SUCCESS CRITERIA

The audit passes if:
✅ All downvote penalties calculate correctly (-10 first, -15 stacking)
✅ All undo operations restore exact penalty amounts
✅ All approved task bonuses work (+2, +5 every 10)
✅ Streak resets properly on downvote
✅ All 5 tier boundaries work correctly
✅ XP conversion matches tier multipliers
✅ Redemption bonus activates/deactivates correctly
✅ Time decay applies at 30/60 day thresholds
✅ UI updates in real-time across all tabs
✅ Notifications send with correct content
✅ Parent-child workflow affects correct user
✅ Boundary conditions don't crash or cause negative values
✅ History tracking records all events accurately
✅ Console logs show correct transaction amounts

---

## REFERENCE FILES

**Source of Truth**:
- `/Volumes/ReelNeal55/EnviveNew/EnviveNew_PRD.md` (lines 194-266)

**Testing Guide**:
- `/Volumes/ReelNeal55/EnviveNew/CREDIBILITY_TESTING_GUIDE.md`

**Core Implementation Files**:
- `CredibilityManager.swift` - All calculation logic
- `ContentView.swift` - Social feed integration
- `ScreenTimeRewardManager.swift` - XP conversion
- `TaskVerificationView.swift` - Parent approval/rejection
- `CredibilityNotifications.swift` - Notification triggers
- `CredibilityTests.swift` - Unit tests

**UI Files**:
- `EnhancedHomeView` - Credibility card display
- `CredibilityTestingView` - Interactive testing
- `ChildProfileView` - Full credibility profile
- `ParentDashboardView` - Parent oversight

---

## FINAL AUDIT REPORT TEMPLATE

After completing all tests:

```markdown
# Credibility System Audit Report

**Date**: [Date]
**Auditor**: [Name]

## Summary
- Total Test Cases: 40+
- Passed: X
- Failed: Y
- Success Rate: Z%

## Critical Issues Found
[List any bugs that break core functionality]

## Minor Issues Found
[List any UI glitches or edge cases]

## Recommendations
[Suggested improvements or fixes]

## Conclusion
✅ System ready for production / ❌ Requires fixes before deployment
```

---

## Notes for Claude/Developer

When running this audit:
1. **Start Fresh**: Reset credibility to 100, clear history
2. **One Test at a Time**: Don't rush, verify each result
3. **Check Console**: Transaction logs are your best friend
4. **Use Testing Tab**: CredibilityTestingView has manual controls
5. **Document Everything**: Screenshot unexpected behavior
6. **Reference PRD**: When in doubt, check EnviveNew_PRD.md lines 194-266

This audit should take 2-3 hours to complete thoroughly. It's comprehensive by design to catch any edge cases or calculation errors.