# Credibility System Simplification

## Problem
The current credibility system is too complex and makes parents feel like they need to do math. This hurts UX and makes the app feel like work.

## Current System Issues
1. **Too many percentages** - Parents see 95%, 100%, earning rates, etc.
2. **Explicit math formulas** - "Base XP × Credibility %" shown to users
3. **Complex stats** - Consecutive approvals, recent declines, earning rate all separate
4. **Unclear impacts** - "Credibility -20" doesn't mean much to parents

## Simplified System

### For Parents (Task Review)
**OLD:**
```
Current Credibility: 85%
Recent Approvals: 7
Recent Declines: 1
Earning Rate: 85%

XP Calculation:
Base XP: 30 XP
× Credibility: 85%
─────────────
Child will earn: 26 XP
```

**NEW:**
```
[Child Name]'s Trust Level: ⭐⭐⭐⭐ Good

This task will earn: 26 XP
```

### Trust Levels (Internal mapping)
- ⭐⭐⭐⭐⭐ **Excellent** (90-100%) - Green
- ⭐⭐⭐⭐ **Good** (75-89%) - Blue
- ⭐⭐⭐ **Fair** (50-74%) - Yellow
- ⭐⭐ **Needs Work** (25-49%) - Orange
- ⭐ **Poor** (0-24%) - Red

### Decline Message
**OLD:**
```
This will:
• Give 0 XP to child
• Reduce credibility by 20 points
• Reset consecutive approval streak

Current: 85%
After decline: 65%
```

**NEW:**
```
Declining will:
• Give child 0 XP
• Lower trust rating (from Good → Fair)
• Child needs 4 approved tasks to regain Good rating
```

### Child View
**OLD:**
```
Credibility: 85%
Earning Rate: 85%
Conversion Rate: 0.85x
```

**NEW:**
```
Your Trust: ⭐⭐⭐⭐ Good
Keep completing honest tasks to maintain it!
```

## Implementation Changes

### 1. Create TrustLevel enum
```swift
enum TrustLevel {
    case excellent  // 90-100
    case good       // 75-89
    case fair       // 50-74
    case needsWork  // 25-49
    case poor       // 0-24

    var display: String
    var stars: String
    var color: Color
    var description: String
}
```

### 2. Remove Complex UI Elements
- Remove "XP Calculation" section with formula
- Remove "Earning Rate" stat
- Remove percentage displays
- Keep simple "will earn X XP" in approve button

### 3. Simplify Messaging
- Decline: "will lower trust" instead of "-20 credibility"
- Approve: Just show "+30 XP" not the multiplication
- Show trust level change visually: ⭐⭐⭐⭐ → ⭐⭐⭐

## Benefits
1. **No math required** - Parent just sees stars and colors
2. **Clear outcomes** - "Good" vs "Fair" is intuitive
3. **Simple decisions** - Focus on approve/decline, not calculations
4. **Visual feedback** - Stars are easier to understand than percentages
5. **Trust metaphor** - "Trust level" is clearer than "credibility score"
