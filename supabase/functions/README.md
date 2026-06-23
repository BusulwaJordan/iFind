# iFind AI Edge Functions

These deployable Supabase Edge Functions power the app's live AI features:

- `recommend-businesses`: B2C recommendations from user interactions, business categories, ratings, and popularity.
- `b2b-match`: B2B compatibility scoring from category fit and distance.

The existing Python files are kept as model/training references. Supabase Edge
Functions deploy from `index.ts`, so deploy these TypeScript functions.

## Deploy

Install and login to the Supabase CLI, then run:

```powershell
supabase functions deploy recommend-businesses --project-ref YOUR_PROJECT_REF
supabase functions deploy b2b-match --project-ref YOUR_PROJECT_REF
```

The deployed functions need the standard Supabase function environment:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

## Health Check

After deployment, call:

```powershell
$headers = @{
  "apikey" = "YOUR_SUPABASE_ANON_KEY"
  "Authorization" = "Bearer YOUR_SUPABASE_ANON_KEY"
  "Content-Type" = "application/json"
}

Invoke-RestMethod `
  -Uri "https://YOUR_PROJECT_REF.supabase.co/functions/v1/b2b-match" `
  -Method Post `
  -Headers $headers `
  -Body '{"category_a":"food","category_b":"retail","distance_km":2.5}'

Invoke-RestMethod `
  -Uri "https://YOUR_PROJECT_REF.supabase.co/functions/v1/recommend-businesses" `
  -Method Post `
  -Headers $headers `
  -Body '{"user_id":"A_REAL_USER_ID","n":5}'
```
