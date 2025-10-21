import Foundation

struct SupabaseConfig {
    static let url = "https://vevcxsjcqwlmmlchfymn.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZldmN4c2pjcXdsbW1sY2hmeW1uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1MTM3NzMsImV4cCI6MjA3MjA4OTc3M30.1y3hbSAD4Sn8j9FF7b6RlHYqhvKsTOCzCP4CVBHuo0c"

    // Service role key - KEEP SECRET! Only use server-side
    // DO NOT expose this in client code or commit to public repos
    static let serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZldmN4c2pjcXdsbW1sY2hmeW1uIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NjUxMzc3MywiZXhwIjoyMDcyMDg5NzczfQ.UeZMY3hWwTIye54tticcDY45w_FVpmx9e-qpYFsEdPI"
}