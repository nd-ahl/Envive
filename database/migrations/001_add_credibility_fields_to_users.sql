-- Migration: Add credibility tracking fields to users table
-- Description: Adds credibility_score, credibility_history, and streak tracking to users
-- Phase: 1 - Database Schema Foundation

-- Add credibility score field (0-100 range, default 100)
ALTER TABLE users
ADD COLUMN IF NOT EXISTS credibility_score INTEGER DEFAULT 100
CHECK (credibility_score >= 0 AND credibility_score <= 100);

-- Add credibility history as JSONB to track downvote events with timestamps
-- Structure: [{"event": "downvote", "amount": -10, "timestamp": "2024-01-01T00:00:00Z", "reason": "Task rejected", "task_id": "uuid"}]
ALTER TABLE users
ADD COLUMN IF NOT EXISTS credibility_history JSONB DEFAULT '[]'::jsonb;

-- Add consecutive approved tasks counter for streak tracking
ALTER TABLE users
ADD COLUMN IF NOT EXISTS consecutive_approved_tasks INTEGER DEFAULT 0;

-- Add index on credibility_score for efficient queries
CREATE INDEX IF NOT EXISTS idx_users_credibility_score
ON users(credibility_score);

-- Add comment for documentation
COMMENT ON COLUMN users.credibility_score IS 'User credibility score (0-100). Affects XP-to-minutes conversion rate. Decreases with rejected tasks, increases with approved tasks.';
COMMENT ON COLUMN users.credibility_history IS 'JSON array tracking credibility events: downvotes, recoveries, and time-based decay adjustments.';
COMMENT ON COLUMN users.consecutive_approved_tasks IS 'Counter for consecutive approved tasks. Resets on rejection. +5 bonus at 10 streak.';