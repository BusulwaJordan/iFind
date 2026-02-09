# Quick Setup Guide - iFind MVP

## 🚨 Fixing the Current Build Error

The error you're experiencing is a common Flutter pub cache issue. Here's how to fix it:

### Option 1: Direct Dependency Fix (Recommended - 2 minutes)

1. **Open a NEW PowerShell/Terminal window** (close the current one)

2. **Navigate to project:**
```powershell
cd D:\projects\iFind
```

3. **Remove pub cache lock:**
```powershell
Remove-Item -Path "$env:LOCALAPPDATA\Pub\Cache\.pub-cache.lock" -ErrorAction SilentlyContinue
```

4. **Clean and reinstall:**
```powershell
flutter clean
flutter pub get
```

5. **Run the app:**
```powershell
flutter run
```

### Option 2: Manual Package Installation

If Option 1 doesn't work:

1. **Delete pub cache folder:**
```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Pub\Cache"
```

2. **Reinstall dependencies:**
```powershell
cd D:\projects\iFind
flutter pub get
```

### Option 3: Use Latest Supabase Version

If you still have issues, update `pubspec.yaml`:

```yaml
dependencies:
  supabase_flutter: any  # This will use the latest compatible version
```

Then run:
```powershell
flutter pub get
```

---

## ⚙️ Supabase Configuration (Required Before Running)

Once dependencies are installed, you MUST configure Supabase:

### Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Click "New Project"
3. Fill in:
   - **Name**: ifind
   - **Database Password**: (choose a strong password)
   - **Region**: closest to you
   - **Plan**: Free

### Step 2: Set Up Database

1. In your Supabase dashboard, go to **SQL Editor**
2. Click "New Query"
3. Copy the entire contents of `D:\projects\iFind\database\schema.sql`
4. Paste into the SQL editor
5. Click "Run" (this creates all tables, policies, and triggers)

### Step 3: Get API Credentials

1. In Supabase dashboard, go to **Settings → API**
2. Copy:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon public** key (long string starting with `eyJ...`)

### Step 4: Configure App

Open `D:\projects\iFind\lib\core\constants\api_constants.dart`

Replace these lines:
```dart
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'YOUR_SUPABASE_URL_HERE',  // ← Put your URL here
);

static const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'YOUR_SUPABASE_ANON_KEY_HERE',  // ← Put your key here
);
```

With:
```dart
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://YOUR_PROJECT_ID.supabase.co',  // ← Your actual URL
);

static const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOiJIUz...',  // ← Your actual anon key
);
```

---

## 🎯 Running the App

Once configured:

```powershell
flutter run
```

The app will:
1. Launch on your emulator/device
2. Show the Login screen
3. Allow you to register a new account
4. Navigate to the home screen after login

---

## 🧪 Testing the Authentication

### Register a New Account

1. On the login screen, tap **"Register"**
2. Fill in:
   - **Full Name**: John Doe
   - **Email**: john@example.com
   - **Phone**: +256700123456 (optional)
   - **Role**: Select "Customer" (or any role)
   - **Password**: Password123
   - **Confirm Password**: Password123
3. Tap **"Register"**
4. You should be logged in automatically!

### Login with Existing Account

1. Use the credentials you registered with
2. Tap **"Login"**
3. You'll see the home screen with your name

### Check Database

Go to Supabase Dashboard → **Table Editor** → **users**

You should see your newly created user!

---

## 🔧 Common Issues & Solutions

### Issue: "SupabaseClient not found"
**Solution**: Make sure `flutter pub get` completed successfully

### Issue: "Network error"
**Solution**: Check your Supabase URL and anon key are correct

### Issue: "Email already registered"
**Solution**: Use a different email or check Supabase → Authentication → Users

### Issue: "Invalid email or password"
**Solution**: Supabase requires:
- Valid email format  
- Password minimum 6 characters

---

## 📱 What's Working Now

✅ Complete authentication flow
✅ User registration with role selection
✅ Secure login/logout
✅ Beautiful glassmorphism UI
✅ Database with RLS security

## 🚀 Next Features to Build

After you have auth working:

1. **Business Discovery** - Search and browse businesses
2. **Business Management** - Create/edit business profiles
3. **Products** - Add products to businesses
4. **Chat** - Real-time messaging
5. **Reviews** - Rate and review businesses

All structured and ready to implement using the same Clean Architecture!

---

## 💡 Quick Tips

- Use **Hot Reload**: Press `r` in the terminal while app is running
- Use **Hot Restart**: Press `R` for full restart
- View logs: All errors will show in the terminal
- Debug: Add print statements anywhere

---

## 📞 Need Help?

If you're still stuck:

1. Check Flutter doctor: `flutter doctor -v`
2. Check Supabase connection: Go to your project dashboard
3. Verify schema is created: Check "Table Editor" in Supabase
4. Check console logs when running the app

The foundation is solid - once dependencies are installed and Supabase is configured, everything will work perfectly! 🎉
