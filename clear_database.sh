#!/bin/bash

# Envive Database Clear Script
# This script clears all user data from Supabase tables to allow fresh signups
# USE WITH CAUTION - This deletes ALL data!

echo "🗑️  Envive Database Clear Script"
echo "================================"
echo ""
echo "⚠️  WARNING: This will DELETE ALL data from the following tables:"
echo "   - profiles"
echo "   - households"
echo "   - household_members"
echo "   - auth.users (via Supabase auth API)"
echo ""
echo "This allows you to reuse the same email addresses for new signups."
echo ""

# Supabase credentials
SUPABASE_URL="https://vevcxsjcqwlmmlchfymn.supabase.co"
SUPABASE_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZldmN4c2pjcXdsbW1sY2hmeW1uIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NjUxMzc3MywiZXhwIjoyMDcyMDg5NzczfQ.UeZMY3hWwTIye54tticcDY45w_FVpmx9e-qpYFsEdPI"

# Function to delete from a table
delete_table() {
    local table=$1
    echo "🗑️  Clearing table: $table..."

    response=$(curl -s -X DELETE \
        "${SUPABASE_URL}/rest/v1/${table}?id=neq.00000000-0000-0000-0000-000000000000" \
        -H "apikey: ${SUPABASE_SERVICE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal")

    if [ $? -eq 0 ]; then
        echo "   ✅ Cleared $table"
    else
        echo "   ❌ Error clearing $table: $response"
    fi
}

# Function to delete all auth users
delete_auth_users() {
    echo "🗑️  Deleting all authentication users..."

    # First, get all users
    users=$(curl -s -X GET \
        "${SUPABASE_URL}/auth/v1/admin/users" \
        -H "apikey: ${SUPABASE_SERVICE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}")

    # Extract user IDs and delete each one
    user_ids=$(echo "$users" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)

    count=0
    for user_id in $user_ids; do
        curl -s -X DELETE \
            "${SUPABASE_URL}/auth/v1/admin/users/${user_id}" \
            -H "apikey: ${SUPABASE_SERVICE_KEY}" \
            -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}" > /dev/null

        ((count++))
    done

    echo "   ✅ Deleted $count auth user(s)"
}

# Confirm before proceeding
read -p "Are you sure you want to delete ALL data? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Operation cancelled"
    exit 1
fi

echo ""
echo "🚀 Starting database clear..."
echo ""

# Clear tables in order (respecting foreign key dependencies)
# Delete in reverse dependency order
delete_table "household_members"
delete_table "profiles"
delete_table "households"

# Delete auth users last (this will cascade to profiles if trigger is set up)
delete_auth_users

echo ""
echo "✅ Database clear complete!"
echo ""
echo "📧 You can now reuse the same email addresses for new signups."
echo ""
