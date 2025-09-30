# Credibility & Accountability System - Testing Guide

## ⚠️ IMPORTANT: Source of Truth

**Always reference `EnviveNew_PRD.md` (lines 194-266)** for the official credibility system specification before making any changes.

## System Overview

The credibility system affects how much screen time users earn from XP. Lower credibility = fewer minutes per XP.

### Key Metrics
- **Score Range**: 0-100 (starts at 100)
- **Downvote Penalty**: -10 points (first), -15 points (if within 7 days of previous)
- **Recovery**: +2 per approved task, +5 bonus every 10 tasks
- **Time Decay**: 50% reduction after 30 days, full removal after 60 days

### Conversion Rates (from PRD)
- **90-100**: 1.2x multiplier (Excellent) - 1000 XP = 120 minutes
- **75-89**: 1.0x multiplier (Good) - 1000 XP = 100 minutes
- **60-74**: 0.8x multiplier (Fair) - 1000 XP = 80 minutes
- **40-59**: 0.5x multiplier (Poor) - 1000 XP = 50 minutes
- **0-39**: 0.3x multiplier (Very Poor) - 1000 XP = 30 minutes

## How to Test the System

### Method 1: Use the Credibility Testing Tab (Safest)

1. Build and run app (Cmd+B, then Cmd+R)
2. Navigate to **"Credibility" tab** at bottom (chart icon)
3. Use test controls:
   - **"Reject Task"** button: Simulates a downvote (-10 to -15 points)
   - **"Approve Task"** button: Simulates approval (+2 points)
   - **Load Scenarios**: Pre-configured test states
   - **Manual Controls**: Add/remove specific point amounts

### Method 2: Test via Social Feed

**⚠️ IMPORTANT: Currently only self-downvotes affect YOUR credibility**
- Downvoting **your own post** = you lose credibility (for testing)
- Downvoting **someone else's post** = button changes but YOUR credibility unchanged
- In production with multi-user support, downvoting affects the **post author's** credibility

**Applying Self-Downvote:**
1. Go to **"Social" tab**
2. Find **YOUR OWN post** (shows your username)
3. Tap the **orange diamond button** (🔸) below the post
4. Button turns **red** (🔻) = downvote applied
5. Go to **"Home" tab**
6. Check **"Credibility" stat card** - score should be lower (100 → 90)
7. Try redeeming XP - you'll get fewer minutes

**Undoing Self-Downvote (Method 1 - Tap Red Button):**
1. Go back to **"Social" tab**
2. Tap the **red button** (🔻) again on YOUR post
3. Button turns back to **orange** (🔸) = downvote removed
4. Go to **"Home" tab**
5. Check **"Credibility" stat card** - score should be restored (90 → 100)
6. Credibility penalty is completely reversed!

**Undoing Self-Downvote (Method 2 - Switch to Like):**
1. Go back to **"Social" tab**
2. Tap the **green circle** (⚪ or 🟢) on YOUR downvoted post
3. Button turns green, red button turns orange
4. Go to **"Home" tab**
5. Check **"Credibility" stat card** - score should be restored (90 → 100)
6. Switching from downvote to like automatically undoes the penalty!

### Method 3: Test via Parent Task Verification (Future)

When parent verification is fully integrated:
1. Parent goes to TaskVerificationView
2. Parent rejects a child's task
3. Child's credibility drops automatically

## Verifying It's Working

After downvoting, check these 3 places:

### 1. Home Tab - Credibility Card
- Should show reduced score (e.g., 100 → 90)
- Color changes: Green (80+) → Yellow (50-79) → Red (0-49)

### 2. Credibility Tab - Current State
- Score updates in real-time
- Tier may change (Excellent → Good → Fair → Poor → Very Poor)
- Conversion rate worsens (e.g., 1.2x → 1.15x)
- Streak resets to 0

### 3. XP Redemption
- When converting XP to minutes, you get less time
- Example: 1000 XP at 100 score = 120 min, at 90 score = 115 min

## Development Guidelines

### DO:
✅ Always test in the **Credibility Testing Tab** first
✅ Reference `EnviveNew_PRD.md` before making changes
✅ Use the shared `model.credibilityManager` instance
✅ Sync scores: `model.currentUser.credibilityScore = Double(model.credibilityManager.credibilityScore)`
✅ Check Xcode console for debug logs (🔻 emoji)

### DON'T:
❌ Don't create new `@StateObject private var credibilityManager` instances
❌ Don't modify credibility logic without checking PRD
❌ Don't skip syncing credibilityManager ↔ currentUser
❌ Don't test on production user data

## Key Files

### Core System
- **`CredibilityManager.swift`** - All scoring logic (lines 203-216 in PRD)
- **`EnviveNew_PRD.md`** - Official specification (lines 194-266)

### UI Integration
- **`ContentView.swift`** - EnhancedScreenTimeModel with shared credibilityManager
- **`ContentView.swift`** - EnhancedHomeView displays score (line ~6269)
- **`ContentView.swift`** - SocialPostView downvote handler (line ~4585)
- **`CredibilityTestingView.swift`** - Testing interface

### Testing
- **`CredibilityTests.swift`** - Unit tests
- **`CredibilityTestingView.swift`** - Interactive testing UI

## Database Schema (from PRD)

When connecting to Supabase, these fields exist on `users` table:
- `credibility_score` (INTEGER, 0-100, default 100)
- `credibility_history` (JSONB array)
- `consecutive_approved_tasks` (INTEGER)

## Common Issues

### Issue: Downvote doesn't affect score
**Solution**: Check that you're using `model.credibilityManager` (shared instance), not a local `@StateObject`

### Issue: Home page doesn't update
**Solution**: Make sure sync happens after downvote:
```swift
model.currentUser.credibilityScore = Double(model.credibilityManager.credibilityScore)
```

### Issue: Score changes but conversion rate doesn't
**Solution**: ScreenTimeRewardManager needs to read from credibilityManager when converting XP

## Testing Checklist

Before committing credibility changes:

- [ ] Test downvote in Credibility tab - score drops by 10-15
- [ ] Test downvote in Social feed - button turns red, score drops
- [ ] **Test undo downvote (tap red button again) - score restores to previous value**
- [ ] **Test undo by switching to like (tap green circle) - score restores same as red button method**
- [ ] Check Home tab - Credibility card updates in real-time
- [ ] Test multiple downvotes - stacking penalty applies (-15 after first)
- [ ] Test undo after multiple downvotes - each undo restores exact penalty amount
- [ ] Test approved task - score increases by +2
- [ ] Test 10 consecutive approvals - get +5 bonus
- [ ] Test XP redemption at different scores - conversion rate changes
- [ ] Verify history shows both downvote and downvote_undone events
- [ ] Test switching downvote→like→downvote - credibility changes correctly each time
- [ ] Run CredibilityTests.swift - all tests pass

## Questions?

If unsure about any behavior, always check **EnviveNew_PRD.md lines 194-266** first.