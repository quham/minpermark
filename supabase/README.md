# GoalScroll Supabase Backend

This folder contains the Supabase configuration for GoalScroll's backend.

## Setup Instructions

### 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Note your project URL and anon key (Settings > API)

### 2. Run Database Migrations

1. Go to SQL Editor in Supabase dashboard
2. Copy and paste contents of `migrations/001_initial_schema.sql`
3. Run the SQL

This creates:
- `profiles` table (extends auth.users)
- `goals` table (synced goals)
- `user_stats` table (user statistics)
- Row Level Security policies
- Auto-create profile trigger on signup

### 3. Configure Authentication

#### Email Authentication
- Already enabled by default

#### Apple Sign In
1. Go to Authentication > Providers > Apple
2. Enable Apple provider
3. Add your Apple Service ID and other required credentials
4. Configure your Apple Developer account with Supabase redirect URL

### 4. Deploy Edge Functions

```bash
# Install Supabase CLI if not already installed
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Set the Gemini API key secret
supabase secrets set GEMINI_API_KEY=your_gemini_api_key

# Deploy functions
supabase functions deploy suggestions
supabase functions deploy verify
```

### 5. Update iOS App

Update `GoalScroll/Utilities/Constants.swift`:

```swift
enum Supabase {
    static let url = "https://YOUR_PROJECT.supabase.co"
    static let anonKey = "YOUR_ANON_KEY"
}
```

## Edge Functions

### `/suggestions`
- **Method:** POST
- **Auth:** Required (Bearer token)
- **Body:** `{ "goal_title": "Learn Spanish" }`
- **Response:** `{ "suggestions": ["Learn 1 word", ...] }`

### `/verify`
- **Method:** POST
- **Auth:** Required (Bearer token)
- **Body:**
```json
{
  "goal": {
    "title": "Exercise daily",
    "micro_habit": "Do 5 pushups",
    "trigger_type": "time",
    "trigger_value": "7:00 AM"
  },
  "proof_items": [
    {
      "type": "camera",
      "image_base64": "..."
    }
  ]
}
```
- **Response:** `{ "status": "passed", "confidence": 0.9, "reason": "..." }`

## Database Schema

### profiles
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key (references auth.users) |
| display_name | TEXT | User's display name |
| created_at | TIMESTAMPTZ | Creation timestamp |
| updated_at | TIMESTAMPTZ | Last update timestamp |

### goals
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | Owner (references auth.users) |
| title | TEXT | Goal title |
| micro_habit | TEXT | Micro habit action |
| trigger_type | TEXT | 'time', 'after', 'location' |
| trigger_value | TEXT | Trigger details |
| proof_methods | TEXT[] | Array of proof methods |
| importance | INTEGER | 1-10 priority |
| why | TEXT | Motivation reason |
| is_archived | BOOLEAN | Soft delete flag |
| daily_minutes_reward | INTEGER | Minutes earned |
| last_completed_at | TIMESTAMPTZ | Last completion |
| local_id | UUID | SwiftData ID for sync |
| sync_version | INTEGER | Conflict resolution |

### user_stats
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | Owner (references auth.users) |
| today_minutes_earned | INTEGER | Minutes earned today |
| lifetime_minutes_earned | INTEGER | Total minutes |
| current_streak_days | INTEGER | Current streak |
| longest_streak_days | INTEGER | Best streak |
| daily_minutes_target | INTEGER | Daily goal |
| anchor_goal_id | UUID | Primary goal reference |

## Local Development

```bash
# Start local Supabase
supabase start

# Run functions locally
supabase functions serve

# View logs
supabase functions logs suggestions
supabase functions logs verify
```
