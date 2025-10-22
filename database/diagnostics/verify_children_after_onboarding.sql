-- ============================================
-- VERIFY CHILDREN AFTER ONBOARDING
-- Run this to check if children are properly saved
-- ============================================

\echo '=========================================='
\echo 'CHILDREN VERIFICATION AFTER ONBOARDING'
\echo '=========================================='
\echo ''

-- 1. Show all households with their invite codes
\echo '1️⃣ All Households:'
\echo ''
SELECT
    id,
    name as household_name,
    invite_code,
    created_at,
    (SELECT COUNT(*) FROM profiles WHERE household_id = households.id) as total_members,
    (SELECT COUNT(*) FROM profiles WHERE household_id = households.id AND role = 'parent') as parents,
    (SELECT COUNT(*) FROM profiles WHERE household_id = households.id AND role = 'child') as children
FROM households
ORDER BY created_at DESC;

\echo ''
\echo '2️⃣ All Profiles (Parents and Children):'
\echo ''
SELECT
    p.id,
    p.full_name,
    p.role,
    p.age,
    p.household_id,
    h.name as household_name,
    h.invite_code,
    p.created_at,
    CASE
        WHEN p.household_id IS NULL THEN '❌ NO HOUSEHOLD'
        ELSE '✅ IN HOUSEHOLD'
    END as household_status
FROM profiles p
LEFT JOIN households h ON p.household_id = h.id
ORDER BY h.name, p.role, p.full_name;

\echo ''
\echo '3️⃣ Child Profiles Only:'
\echo ''
SELECT
    p.id,
    p.full_name as child_name,
    p.age,
    h.name as household_name,
    h.invite_code,
    p.created_at as profile_created,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM household_members hm
            WHERE hm.user_id = p.id AND hm.household_id = p.household_id
        ) THEN '✅ In household_members'
        ELSE '❌ Missing from household_members'
    END as membership_status
FROM profiles p
JOIN households h ON p.household_id = h.id
WHERE p.role = 'child'
ORDER BY h.name, p.full_name;

\echo ''
\echo '4️⃣ Household Membership Data:'
\echo ''
SELECT
    h.name as household_name,
    h.invite_code,
    p.full_name as member_name,
    p.role,
    p.age,
    hm.joined_at
FROM household_members hm
JOIN profiles p ON hm.user_id = p.id
JOIN households h ON hm.household_id = h.id
ORDER BY h.name, p.role DESC, p.full_name;

\echo ''
\echo '5️⃣ Check for Data Integrity Issues:'
\echo ''

-- Children missing from household_members
SELECT
    'Children missing from household_members' as issue_type,
    COUNT(*) as count
FROM profiles p
WHERE p.role = 'child'
  AND p.household_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM household_members hm
    WHERE hm.user_id = p.id AND hm.household_id = p.household_id
  );

-- Children with NULL household_id
SELECT
    'Children with NULL household_id' as issue_type,
    COUNT(*) as count
FROM profiles
WHERE role = 'child' AND household_id IS NULL;

-- Household members not in profiles
SELECT
    'Household members not in profiles' as issue_type,
    COUNT(*) as count
FROM household_members hm
WHERE NOT EXISTS (
    SELECT 1 FROM profiles p WHERE p.id = hm.user_id
);

\echo ''
\echo '6️⃣ Parent-Children Relationships:'
\echo ''
SELECT
    parent.full_name as parent_name,
    parent.email as parent_email,
    h.name as household_name,
    h.invite_code,
    COUNT(child.id) as number_of_children,
    STRING_AGG(child.full_name || ' (age ' || COALESCE(child.age::text, 'N/A') || ')', ', ') as children
FROM profiles parent
JOIN households h ON parent.household_id = h.id
LEFT JOIN profiles child ON child.household_id = parent.household_id AND child.role = 'child'
WHERE parent.role = 'parent'
GROUP BY parent.id, parent.full_name, parent.email, h.name, h.invite_code
ORDER BY parent.created_at DESC;

\echo ''
\echo '7️⃣ Most Recent Onboarding Activity:'
\echo ''
SELECT
    'Most recent household created' as activity,
    name as household_name,
    invite_code,
    created_at
FROM households
ORDER BY created_at DESC
LIMIT 1;

SELECT
    'Most recent profile created' as activity,
    full_name as name,
    role,
    age,
    created_at
FROM profiles
ORDER BY created_at DESC
LIMIT 5;

\echo ''
\echo '=========================================='
\echo 'VERIFICATION COMPLETE'
\echo '=========================================='
\echo ''
\echo 'WHAT TO CHECK:'
\echo '  1. Do children have household_id set?'
\echo '  2. Are children in household_members table?'
\echo '  3. Do parents see their children in the same household?'
\echo '  4. Are there any data integrity issues?'
\echo ''
\echo 'If children are missing household_id, run:'
\echo '  database/fix_data_integrity.sql'
\echo ''
