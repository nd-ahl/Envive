-- Migration: Create task_verifications table
-- Description: Tracks parent approval/rejection of child tasks with notes and timestamps
-- Phase: 1 - Database Schema Foundation

-- Create task_verifications table
CREATE TABLE IF NOT EXISTS task_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL,
    user_id UUID NOT NULL, -- Child who completed the task
    reviewer_id UUID NOT NULL, -- Parent who reviewed the task
    status TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'rejected', 'appealed')),
    notes TEXT, -- Optional notes from parent about approval/rejection
    appeal_notes TEXT, -- Optional notes from child when appealing
    appeal_deadline TIMESTAMP WITH TIME ZONE, -- 24-hour window for appeals
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_at TIMESTAMP WITH TIME ZONE, -- When parent made decision

    -- Foreign key constraints
    CONSTRAINT fk_task_verifications_task FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    CONSTRAINT fk_task_verifications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_task_verifications_reviewer FOREIGN KEY (reviewer_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_task_verifications_task_id ON task_verifications(task_id);
CREATE INDEX IF NOT EXISTS idx_task_verifications_user_id ON task_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_task_verifications_reviewer_id ON task_verifications(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_task_verifications_status ON task_verifications(status);
CREATE INDEX IF NOT EXISTS idx_task_verifications_created_at ON task_verifications(created_at DESC);

-- Composite index for parent dashboard (reviewer viewing pending tasks)
CREATE INDEX IF NOT EXISTS idx_task_verifications_reviewer_status
ON task_verifications(reviewer_id, status)
WHERE status = 'pending';

-- Row-level security policies
ALTER TABLE task_verifications ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own task verifications (as child)
CREATE POLICY "Users can view their own task verifications"
ON task_verifications FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Parents can view task verifications they created
CREATE POLICY "Reviewers can view task verifications they created"
ON task_verifications FOR SELECT
USING (auth.uid() = reviewer_id);

-- Policy: Parents can create task verifications for their children
CREATE POLICY "Parents can create task verifications for their children"
ON task_verifications FOR INSERT
WITH CHECK (
    auth.uid() = reviewer_id AND
    EXISTS (
        SELECT 1 FROM user_relationships
        WHERE parent_id = auth.uid()
        AND child_id = user_id
        AND status = 'accepted'
    )
);

-- Policy: Parents can update their own task verifications
CREATE POLICY "Reviewers can update their own task verifications"
ON task_verifications FOR UPDATE
USING (auth.uid() = reviewer_id)
WITH CHECK (auth.uid() = reviewer_id);

-- Policy: Children can update task verifications to appeal
CREATE POLICY "Users can appeal their task verifications"
ON task_verifications FOR UPDATE
USING (
    auth.uid() = user_id AND
    status = 'rejected' AND
    appeal_deadline > NOW()
)
WITH CHECK (
    auth.uid() = user_id AND
    status = 'appealed'
);

-- Function to automatically set updated_at timestamp
CREATE OR REPLACE FUNCTION update_task_verifications_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on row changes
CREATE TRIGGER trigger_update_task_verifications_updated_at
BEFORE UPDATE ON task_verifications
FOR EACH ROW
EXECUTE FUNCTION update_task_verifications_updated_at();

-- Function to set appeal deadline when task is rejected
CREATE OR REPLACE FUNCTION set_appeal_deadline()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'rejected' AND OLD.status != 'rejected' THEN
        NEW.appeal_deadline = NOW() + INTERVAL '24 hours';
        NEW.reviewed_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically set appeal deadline on rejection
CREATE TRIGGER trigger_set_appeal_deadline
BEFORE UPDATE ON task_verifications
FOR EACH ROW
EXECUTE FUNCTION set_appeal_deadline();

-- Comments for documentation
COMMENT ON TABLE task_verifications IS 'Tracks parent approval/rejection of child tasks with credibility impact';
COMMENT ON COLUMN task_verifications.status IS 'Status: pending (awaiting review), approved, rejected, appealed (child contested rejection)';
COMMENT ON COLUMN task_verifications.appeal_deadline IS '24-hour window after rejection for child to appeal decision';
COMMENT ON COLUMN task_verifications.notes IS 'Parent notes explaining approval or rejection decision';
COMMENT ON COLUMN task_verifications.appeal_notes IS 'Child notes when appealing a rejection';