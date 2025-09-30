# Live Credibility Testing Guide

## Purpose
This guide helps you verify that button presses in the app actually affect credibility correctly by watching the Xcode console.

---

## Setup

1. **Build and Run** (Cmd+R)
2. **Open Xcode Console** (Cmd+Shift+Y to show debug area)
3. **Filter Console**: Type "━" or "🔸" or "🟢" in the filter box to see only credibility logs

---

## What to Test

### Test 1: Downvote Your Own Post

**Steps:**
1. Go to Social tab
2. Find a post with YOUR username
3. Note your credibility in Home tab (e.g., 100)
4. Tap the **orange diamond button** (🔸)
5. Watch the console

**Expected Console Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔸 DOWNVOTE BUTTON PRESSED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Current State BEFORE:
  - Credibility: 100
  - User has liked: false
  - User has downvoted: false
  - Post author ID: [YOUR-ID]
  - Current user ID: [YOUR-ID]
  - Is own post: true
➡️  Action: ADDING DOWNVOTE
🔻 APPLYING CREDIBILITY PENALTY (self-downvote)
💔 Downvote processed: -10 points. Score: 100 → 90
🔻 Self-downvote applied:
   BEFORE: 100
   AFTER: 90
   PENALTY: -10
📊 Final State AFTER:
  - Credibility: 90
  - Tier: Excellent
  - Conversion Rate: 1.2x
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**What to Check:**
- ✅ "Is own post: true"
- ✅ "APPLYING CREDIBILITY PENALTY"
- ✅ BEFORE: 100, AFTER: 90, PENALTY: -10
- ✅ Home tab shows 90 immediately

**If You Don't See This:**
- ❌ If "Is own post: false" → You're not logged in as the post author
- ❌ If no "APPLYING CREDIBILITY PENALTY" → Self-check failed
- ❌ If no console output at all → Button not wired up

---

### Test 2: Undo Downvote (Tap Red Button Again)

**Steps:**
1. Same post as Test 1 (red button should be active 🔻)
2. Tap the **red button** again
3. Watch console

**Expected Console Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔸 DOWNVOTE BUTTON PRESSED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Current State BEFORE:
  - Credibility: 90
  - User has downvoted: true
  - Is own post: true
➡️  Action: REMOVING DOWNVOTE
🔄 RESTORING CREDIBILITY (undo self-downvote)
↩️  Downvote undone: +10 points. Score: 90 → 100
↩️  Self-downvote removed - Credibility restored:
   BEFORE: 90
   AFTER: 100
   CHANGE: +10
📊 Final State AFTER:
  - Credibility: 100
  - Tier: Excellent
  - Conversion Rate: 1.2x
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**What to Check:**
- ✅ "User has downvoted: true" (from previous test)
- ✅ "RESTORING CREDIBILITY"
- ✅ BEFORE: 90, AFTER: 100, CHANGE: +10
- ✅ Home tab shows 100 again

---

### Test 3: Switch from Downvote to Like

**Steps:**
1. Downvote your post again (100 → 90)
2. Instead of tapping red button, tap **green circle** (⚪)
3. Watch console

**Expected Console Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🟢 LIKE BUTTON PRESSED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Current State BEFORE:
  - Credibility: 90
  - User has downvoted: true
  - Is own post: true
➡️  Action: ADDING LIKE
⚠️  User previously downvoted this post - removing downvote first
🔄 RESTORING CREDIBILITY (self-downvote undo)
↩️  Downvote undone: +10 points. Score: 90 → 100
💚 Switched from downvote to like - Credibility restored:
   BEFORE: 90
   AFTER: 100
   CHANGE: +10
✓ Like added successfully
📊 Final State AFTER:
  - Credibility: 100
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**What to Check:**
- ✅ "User previously downvoted this post"
- ✅ "RESTORING CREDIBILITY"
- ✅ Credibility restored to 100
- ✅ Like added AND downvote removed

---

### Test 4: Downvote Someone Else's Post

**Steps:**
1. Find a post with a DIFFERENT username
2. Tap orange diamond
3. Watch console

**Expected Console Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔸 DOWNVOTE BUTTON PRESSED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Current State BEFORE:
  - Credibility: 100
  - Post author ID: [OTHER-ID]
  - Current user ID: [YOUR-ID]
  - Is own post: false
➡️  Action: ADDING DOWNVOTE
🔻 Downvoted another user's post (their credibility would decrease in multi-user system)
📊 Final State AFTER:
  - Credibility: 100  ← UNCHANGED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**What to Check:**
- ✅ "Is own post: false"
- ✅ "Downvoted another user's post"
- ✅ Credibility UNCHANGED (stays 100)
- ✅ Button still turns red (UI works)

---

### Test 5: Stacking Penalty (Second Downvote Within 7 Days)

**Steps:**
1. Downvote your own post (100 → 90)
2. Undo it (90 → 100)
3. Downvote it again IMMEDIATELY
4. Watch console

**Expected Console Output:**
```
🔸 DOWNVOTE BUTTON PRESSED
📊 Current State BEFORE:
  - Credibility: 100
🔻 APPLYING CREDIBILITY PENALTY (self-downvote)
💔 Downvote processed: -15 points. Score: 100 → 85  ← NOTICE -15!
🔻 Self-downvote applied:
   BEFORE: 100
   AFTER: 85
   PENALTY: -15  ← STACKING PENALTY
📊 Final State AFTER:
  - Credibility: 85
  - Tier: Good
```

**What to Check:**
- ✅ PENALTY: -15 (not -10)
- ✅ Tier changed from Excellent to Good
- ✅ Stacking logic works

---

### Test 6: Multiple Downvotes (Tier Changes)

**Steps:**
1. Start at 100
2. Downvote your post 6 times
3. Watch tier changes in console

**Expected Tier Changes:**
```
100 (Excellent, 1.2x) → downvote
90 (Excellent, 1.2x) → downvote
75 (Good, 1.0x) → downvote      ← TIER CHANGE
60 (Fair, 0.8x) → downvote      ← TIER CHANGE
45 (Poor, 0.5x) → downvote      ← TIER CHANGE
30 (Very Poor, 0.3x) → downvote ← TIER CHANGE
```

**What to Check:**
- ✅ Each tier boundary triggers correctly
- ✅ Conversion rate changes at boundaries
- ✅ Home tab color changes (green → yellow → red)

---

## Troubleshooting

### Issue: No Console Output
**Solution:**
- Make sure Xcode console is visible (Cmd+Shift+Y)
- Check you're running the app from Xcode (not TestFlight)
- Clear console and try again (Cmd+K)

### Issue: "Is own post: false" when it should be true
**Solution:**
- Check post.userId matches your current user
- Look at "Post author ID" vs "Current user ID" in logs
- You might be looking at a mock post from another user

### Issue: Button press doesn't trigger function
**Solution:**
- Check if button is disabled
- Make sure you're tapping the button area, not just near it
- Try force-quitting app and rebuilding

### Issue: Credibility changes but UI doesn't update
**Solution:**
- Check if `model.currentUser.credibilityScore = ...` is being called
- Look for "📊 Final State AFTER" in logs
- Navigate to different tab and back to force refresh

---

## Success Criteria

✅ **All Tests Pass If:**
1. Console shows detailed logs for EVERY button press
2. Self-downvotes affect credibility correctly
3. Other user downvotes DON'T affect your credibility
4. Undo operations restore EXACT penalty amounts
5. Tier changes happen at correct boundaries
6. Home tab updates in real-time
7. Stacking penalty applies after 2nd downvote within 7 days

---

## Quick Reference: Console Emojis

| Emoji | Meaning |
|-------|---------|
| 🔸 | Downvote button pressed |
| 🟢 | Like button pressed |
| 🔻 | Applying penalty |
| 🔄 | Restoring credibility |
| ↩️ | Undo completed |
| 💚 | Switched from downvote to like |
| 💔 | Downvote processed in manager |
| ✓ | Action completed successfully |
| ⚠️ | Warning or state change |
| ❌ | Error occurred |
| 📊 | State snapshot |

---

## After Testing

Once you've verified everything works:
1. Build for release (these logs won't appear in production)
2. Or remove/comment out the print statements if they're too verbose
3. Keep the logs during development for debugging

The detailed logging proves the transaction chain is working correctly!