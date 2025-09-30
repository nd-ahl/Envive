-- Migration: Create XP conversion calculation function
-- Description: Database function to calculate screen time minutes from XP based on credibility score
-- Phase: 1 - Database Schema Foundation

-- Function to calculate XP to minutes conversion based on credibility score
-- Formula: minutes = XP × (0.3 + (credibility_score / 100) × 0.9)
-- This gives a range of 0.3x (score 0) to 1.2x (score 100) multiplier
CREATE OR REPLACE FUNCTION calculate_xp_to_minutes(
    xp_amount INTEGER,
    credibility_score INTEGER,
    has_redemption_bonus BOOLEAN DEFAULT FALSE
)
RETURNS DECIMAL AS $$
DECLARE
    base_conversion_rate DECIMAL;
    tier_multiplier DECIMAL;
    redemption_multiplier DECIMAL;
    final_minutes DECIMAL;
BEGIN
    -- Ensure credibility_score is within valid range
    credibility_score := GREATEST(0, LEAST(100, credibility_score));

    -- Calculate base conversion rate (0.3 to 1.2)
    base_conversion_rate := 0.3 + (credibility_score::DECIMAL / 100.0) * 0.9;

    -- Determine tier multiplier based on credibility score
    -- 90-100: 1.2x (Excellent)
    -- 75-89:  1.0x (Good)
    -- 60-74:  0.8x (Fair)
    -- 40-59:  0.5x (Poor)
    -- 0-39:   0.3x (Very Poor)
    tier_multiplier := CASE
        WHEN credibility_score >= 90 THEN 1.2
        WHEN credibility_score >= 75 THEN 1.0
        WHEN credibility_score >= 60 THEN 0.8
        WHEN credibility_score >= 40 THEN 0.5
        ELSE 0.3
    END;

    -- Apply redemption bonus if eligible (1.3x for 7 days when reaching 95+ from below 60)
    redemption_multiplier := CASE
        WHEN has_redemption_bonus THEN 1.3
        ELSE 1.0
    END;

    -- Calculate final minutes: XP × tier_multiplier × redemption_multiplier
    final_minutes := xp_amount * tier_multiplier * redemption_multiplier;

    -- Round to 2 decimal places
    RETURN ROUND(final_minutes, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to get conversion rate tier information
CREATE OR REPLACE FUNCTION get_conversion_rate_tier(credibility_score INTEGER)
RETURNS TABLE (
    tier_name TEXT,
    tier_multiplier DECIMAL,
    tier_color TEXT,
    tier_description TEXT
) AS $$
BEGIN
    -- Ensure credibility_score is within valid range
    credibility_score := GREATEST(0, LEAST(100, credibility_score));

    RETURN QUERY SELECT
        CASE
            WHEN credibility_score >= 90 THEN 'Excellent'
            WHEN credibility_score >= 75 THEN 'Good'
            WHEN credibility_score >= 60 THEN 'Fair'
            WHEN credibility_score >= 40 THEN 'Poor'
            ELSE 'Very Poor'
        END AS tier_name,
        CASE
            WHEN credibility_score >= 90 THEN 1.2::DECIMAL
            WHEN credibility_score >= 75 THEN 1.0::DECIMAL
            WHEN credibility_score >= 60 THEN 0.8::DECIMAL
            WHEN credibility_score >= 40 THEN 0.5::DECIMAL
            ELSE 0.3::DECIMAL
        END AS tier_multiplier,
        CASE
            WHEN credibility_score >= 80 THEN 'green'
            WHEN credibility_score >= 50 THEN 'yellow'
            ELSE 'red'
        END AS tier_color,
        CASE
            WHEN credibility_score >= 90 THEN 'Outstanding credibility! Maximum conversion rate.'
            WHEN credibility_score >= 75 THEN 'Good standing. Standard conversion rate.'
            WHEN credibility_score >= 60 THEN 'Fair standing. Reduced conversion rate.'
            WHEN credibility_score >= 40 THEN 'Poor standing. Significantly reduced rate.'
            ELSE 'Very poor standing. Minimum conversion rate.'
        END AS tier_description;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to update credibility score based on task verification
CREATE OR REPLACE FUNCTION update_credibility_on_verification()
RETURNS TRIGGER AS $$
DECLARE
    user_record RECORD;
    last_downvote_date TIMESTAMP WITH TIME ZONE;
    days_since_last_downvote INTEGER;
    penalty_amount INTEGER;
BEGIN
    -- Only process when status changes to approved or rejected
    IF (NEW.status = OLD.status) THEN
        RETURN NEW;
    END IF;

    -- Get user's current credibility data
    SELECT credibility_score, credibility_history, consecutive_approved_tasks
    INTO user_record
    FROM users
    WHERE id = NEW.user_id;

    IF NEW.status = 'approved' THEN
        -- Increase credibility score by 2 points
        UPDATE users
        SET
            credibility_score = LEAST(100, user_record.credibility_score + 2),
            consecutive_approved_tasks = user_record.consecutive_approved_tasks + 1,
            credibility_history = user_record.credibility_history ||
                jsonb_build_object(
                    'event', 'approved_task',
                    'amount', 2,
                    'timestamp', NOW(),
                    'task_id', NEW.task_id,
                    'new_score', LEAST(100, user_record.credibility_score + 2)
                )
        WHERE id = NEW.user_id;

        -- Check for 10-streak bonus
        IF (user_record.consecutive_approved_tasks + 1) % 10 = 0 THEN
            UPDATE users
            SET
                credibility_score = LEAST(100, credibility_score + 5),
                credibility_history = credibility_history ||
                    jsonb_build_object(
                        'event', 'streak_bonus',
                        'amount', 5,
                        'timestamp', NOW(),
                        'streak_count', user_record.consecutive_approved_tasks + 1,
                        'new_score', LEAST(100, credibility_score + 5)
                    )
            WHERE id = NEW.user_id;
        END IF;

    ELSIF NEW.status = 'rejected' THEN
        -- Find most recent downvote
        SELECT (elem->>'timestamp')::TIMESTAMP WITH TIME ZONE
        INTO last_downvote_date
        FROM jsonb_array_elements(user_record.credibility_history) AS elem
        WHERE elem->>'event' = 'downvote'
        ORDER BY (elem->>'timestamp')::TIMESTAMP WITH TIME ZONE DESC
        LIMIT 1;

        -- Calculate penalty (base -10, +5 if within 7 days of last downvote)
        IF last_downvote_date IS NOT NULL THEN
            days_since_last_downvote := EXTRACT(DAY FROM NOW() - last_downvote_date);
            penalty_amount := CASE
                WHEN days_since_last_downvote <= 7 THEN -15
                ELSE -10
            END;
        ELSE
            penalty_amount := -10;
        END IF;

        -- Apply penalty and reset streak
        UPDATE users
        SET
            credibility_score = GREATEST(0, user_record.credibility_score + penalty_amount),
            consecutive_approved_tasks = 0,
            credibility_history = user_record.credibility_history ||
                jsonb_build_object(
                    'event', 'downvote',
                    'amount', penalty_amount,
                    'timestamp', NOW(),
                    'task_id', NEW.task_id,
                    'reviewer_id', NEW.reviewer_id,
                    'notes', NEW.notes,
                    'new_score', GREATEST(0, user_record.credibility_score + penalty_amount)
                )
        WHERE id = NEW.user_id;

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update credibility when task verification status changes
CREATE TRIGGER trigger_update_credibility_on_verification
AFTER UPDATE ON task_verifications
FOR EACH ROW
EXECUTE FUNCTION update_credibility_on_verification();

-- Function to apply time-based decay to old downvotes (run periodically)
CREATE OR REPLACE FUNCTION apply_credibility_decay()
RETURNS void AS $$
DECLARE
    user_rec RECORD;
    history_elem JSONB;
    new_history JSONB;
    downvote_date TIMESTAMP WITH TIME ZONE;
    days_old INTEGER;
    recovery_amount INTEGER;
BEGIN
    -- Iterate through all users
    FOR user_rec IN SELECT id, credibility_score, credibility_history FROM users LOOP
        new_history := '[]'::jsonb;
        recovery_amount := 0;

        -- Process each history element
        FOR history_elem IN SELECT * FROM jsonb_array_elements(user_rec.credibility_history) LOOP
            IF history_elem->>'event' = 'downvote' THEN
                downvote_date := (history_elem->>'timestamp')::TIMESTAMP WITH TIME ZONE;
                days_old := EXTRACT(DAY FROM NOW() - downvote_date);

                -- Full removal after 60 days
                IF days_old >= 60 THEN
                    recovery_amount := recovery_amount + ABS((history_elem->>'amount')::INTEGER);
                    CONTINUE; -- Don't add to new history
                -- 50% weight reduction after 30 days
                ELSIF days_old >= 30 AND (history_elem->>'decayed') IS NULL THEN
                    recovery_amount := recovery_amount + (ABS((history_elem->>'amount')::INTEGER) / 2);
                    history_elem := history_elem || jsonb_build_object('decayed', true, 'decay_date', NOW());
                END IF;
            END IF;

            new_history := new_history || history_elem;
        END LOOP;

        -- Update user if there was any recovery
        IF recovery_amount > 0 THEN
            UPDATE users
            SET
                credibility_score = LEAST(100, credibility_score + recovery_amount),
                credibility_history = new_history ||
                    jsonb_build_object(
                        'event', 'time_decay_recovery',
                        'amount', recovery_amount,
                        'timestamp', NOW(),
                        'new_score', LEAST(100, credibility_score + recovery_amount)
                    )
            WHERE id = user_rec.id;
        ELSIF new_history != user_rec.credibility_history THEN
            -- Update history even if no score change (to mark decayed items)
            UPDATE users
            SET credibility_history = new_history
            WHERE id = user_rec.id;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Comments for documentation
COMMENT ON FUNCTION calculate_xp_to_minutes IS 'Converts XP to screen time minutes based on credibility score. Formula: XP × (0.3 + (credibility/100) × 0.9) × tier_multiplier × redemption_bonus';
COMMENT ON FUNCTION get_conversion_rate_tier IS 'Returns tier information (name, multiplier, color, description) for a given credibility score';
COMMENT ON FUNCTION update_credibility_on_verification IS 'Trigger function that updates user credibility score when task verification status changes';
COMMENT ON FUNCTION apply_credibility_decay IS 'Applies time-based decay to downvotes: 50% reduction after 30 days, full removal after 60 days. Run periodically via cron job.';