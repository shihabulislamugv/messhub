# MessHub (মেসহাব) 🏠🇧🇩
> **"Everything about your mess, in one place."**  
> *আপনার মেসের সব হিসাব, এক নিমিষে।*

MessHub is a production-quality Android application built specifically for university students, bachelors, shared-flat, and mess residents in Bangladesh. It simplifies room rent (*Basha Vara*), utilities (*Electricity, Pani, Bua, Gas, Wi-Fi*), daily bazar purchases, meal tracking, meal rate calculation, and end-of-month settlements.

---

## 🌟 Key Highlights

- **Basha Vara Custom Split Rule**: Enforces Bangladesh mess conventions where room rent **MUST ONLY** support custom split (equal split is strictly disallowed). Custom member shares must match the exact total bill.
- **Strict Expense Segregation**: Utility and housing bills are mathematically isolated from the Meal Rate. Meal rate is calculated exclusively as `Total Food & Bazar / Total Meals`.
- **Itemized Bazar System**: Tracks item name, quantity, unit (`kg`, `pcs`, `litre`, `gm`, `pack`), price, and purchaser with real-time auto-summing.
- **Daily Meal Matrix**: Convenient daily tracking of Breakfast, Lunch, and Dinner per roommate with live meal rate metrics.
- **Smart Debt Minimization Settlement**: Calculates net balances and generates the minimal set of payment transfers between roommates.
- **Dual Language**: Seamless runtime switching between **English** and **বাংলা** (Bengali).
- **Bangladeshi Currency**: Native Bangladeshi Taka (`৳`) formatting with proper digit grouping (e.g. `৳15,000`, `৳612.50`).
- **Production Supabase Integration**: Multi-tenant Row-Level Security (RLS) PostgreSQL schema with offline-first resilient cache fallback.
- **Verified Android Release**: Tested and verified release APK (`51.9 MB`) and Google Play App Bundle AAB (`42.3 MB`).

---

## 📱 Screens & Workflows

1. **Authentication & Profile**: Email/password registration, login, profile with name, email, phone, and password reset.
2. **Mess Onboarding**: Create a new mess (generates 6-character invite code) or join an existing mess via invite code.
3. **Dashboard (হোম)**:
   - Greeting & active cycle indicator.
   - Total Mess Expense, My Share, My Paid.
   - Dynamic net status badge: *"You Should Receive ৳X"* (Green), *"You Need to Pay ৳X"* (Red/Amber), or *"Settled"* (Grey).
   - Monthly Bills, Bazar & Food, and Other Expenses breakdown.
   - Quick Action bar (Add Expense, Record Meal, Add Bill) and recent activity stream.
4. **Bills (বিল সমূহ)**:
   - Basha Vara, Electricity, Pani, Bua, Gas, Internet, Other Bill.
   - Custom vs Equal split indicator.
   - Detailed breakdown bottom sheet showing each member's exact share.
5. **Expenses & Bazar (খরচ ও বাজার)**:
   - Tab 1: Categorized expense history with category chips (`Bazar`, `Food`, `Cleaning`, `Repair`, `Transport`, `Other`).
   - Tab 2: Itemized Bazar registry with dynamic item rows and unit pricing.
6. **Meals (মিল হিসাব)**:
   - Date picker and daily member meal toggles (Breakfast, Lunch, Dinner).
   - Live Meal Rate card: `Total Food / Total Meals`.
   - Member-wise cumulative meal counts for the monthly cycle.
7. **Settlements (হিসাব নিষ্পত্তি)**:
   - Summary of who owes whom.
   - Optimal peer-to-peer payment recommendations.
   - Record payment transactions (Sender, Receiver, Amount, Date, Note).
   - Admin action to close monthly cycle and start a new month while preserving historical data.
8. **Reports & Analytics (রিপোর্ট)**:
   - Visual distribution progress bars for bills vs food vs other expenses.
   - Highest expense category indicator.
   - Member-by-member contribution, share, and balance table.
9. **Settings & Preferences**:
   - English / বাংলা language toggle with instant reactivity.
   - Mess configuration, Privacy Policy, Terms of Service, and Logout.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: Flutter 3.35+ (Dart 3.9+)
- **Architecture**: Clean Layered Architecture (`data`, `domain`, `presentation`, `core`)
- **State Management**: `Provider` with decoupled reactive view models
- **Backend**: Supabase Cloud (PostgreSQL 15+, GoTrue Auth, Row Level Security)
- **Design System**: Modern 2026 Material 3 minimal design, Google Fonts (`Inter`), semantic financial palettes
- **Localization**: Native JSON-free compile-safe translations supporting English & Bengali

### Directory Structure
```
lib/
├── core/
│   ├── config/          # Supabase client config & environment loaders
│   ├── constants/       # AppColors, AppTheme, Typography
│   ├── localization/    # AppLocale, English & Bengali Translations
│   └── utils/           # CurrencyFormatter (৳), DateFormatter
├── data/
│   ├── models/          # UserProfile, Mess, Bill, Expense, BazarItem, MealEntry, SettlementRecord
│   ├── repositories/    # Auth, Mess, Bill, Expense, Meal, Settlement repositories
│   └── services/        # Supabase service, MockSeedService (offline fallback)
├── domain/
│   └── calculations/    # BillSplitValidator, MealRateCalculator, BalanceCalculator
└── presentation/
    ├── providers/       # AuthProvider, LocaleProvider, MessProvider
    ├── screens/         # Dashboard, Bills, Expenses, Meals, Settlements, Members, Reports, Settings, Auth
    └── widgets/         # MetricCard, StatusBadge, EmptyStateView, CustomButton, CustomTextField
```

---

## 🧮 Financial Calculation Engine

### 1. Meal Rate Formula
$$\text{Meal Rate} = \frac{\sum \text{Expenses}_{\text{bazar, food}}}{\sum \text{All Member Meals}}$$
*Non-food items (Rent, Electricity, Water, Bua, Gas, Wi-Fi, Cleaning, Repair, Transport) are strictly excluded from the meal rate.*

### 2. Member Total Share
$$\text{Share}(m) = \text{Rent}(m) + \text{Utilities}(m) + (\text{Meals}(m) \times \text{Meal Rate}) + \frac{\text{Other Expenses}}{N}$$

### 3. Net Balance & Status
$$\text{Net Balance}(m) = \text{Total Paid}(m) - \text{Total Share}(m)$$
- $\text{Net Balance} > 0.01 \implies$ **"You Should Receive ৳{amount}"**
- $\text{Net Balance} < -0.01 \implies$ **"You Need to Pay ৳{amount}"**
- $|\text{Net Balance}| \le 0.01 \implies$ **"Settled"**

---

## 🗄️ Database Schema & Supabase Setup

The complete PostgreSQL migration script with Row Level Security (RLS) is located at:
[`supabase/schema.sql`](file:///C:/Users/Shihabul%20Islam/.gemini/antigravity/scratch/messhub/supabase/schema.sql)

### Setup Steps:
1. Create a new project on [Supabase](https://supabase.com).
2. Go to the **SQL Editor** in your Supabase dashboard.
3. Paste and run the contents of [`supabase/schema.sql`](file:///C:/Users/Shihabul%20Islam/.gemini/antigravity/scratch/messhub/supabase/schema.sql).
4. In **Project Settings -> API**, copy your **Project URL** and **anon / public key**.
5. Copy `.env.example` to `.env` or set compile-time environment variables:
   ```bash
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```

---

## 🧪 Automated Testing

MessHub includes automated unit tests covering all critical business rules:
- **Test 1 — Rent Custom Split**: ৳15,000 matches sum of (4000, 3500, 3500, 4000) $\rightarrow$ Valid.
- **Test 2 — Rent Custom Split Invalid**: ৳15,000 with sum ৳14,500 $\rightarrow$ Rejected.
- **Rent Equal Split Rule**: Requesting Equal Split for Basha Vara $\rightarrow$ Strictly rejected.
- **Test 3 — Electricity Equal Split**: ৳2,400 across 4 members = ৳600 each $\rightarrow$ Valid.
- **Test 4 — Electricity Custom Split**: 800 + 500 + 600 + 500 = ৳2,400 $\rightarrow$ Valid.
- **Test 5 — Meal Rate**: ৳20,000 food expense with 400 meals = ৳50.0 $\rightarrow$ Valid.
- **Test 6 — Non-food Bills**: Rent & electricity do not affect meal rate $\rightarrow$ Valid.
- **Test 7 — Zero-Sum Balance Conservation**: Sum of all members' net balances equals 0.

### Run Tests:
```bash
flutter test
```

---

## 🚀 Building for Android

### Debug APK
```bash
flutter build apk --debug
```
*Output: `build/app/outputs/flutter-apk/app-debug.apk`*

### Release APK
```bash
flutter build apk --release
```
*Output: `build/app/outputs/flutter-apk/app-release.apk`*

### Google Play App Bundle (AAB)
```bash
flutter build appbundle --release
```
*Output: `build/app/outputs/bundle/release/app-release.aab`*

*Note: Pre-built release binaries are also archived in `release_builds/` for immediate distribution.*

---

## 🔒 Security & Privacy

- **Row Level Security**: Database rows are strictly isolated using `is_member_of_mess()` security functions so users can never read or query financial data from another mess.
- **No Hard-Coded Credentials**: Secrets are strictly kept out of version control.
- **Data Safety**: Only essential contact and accounting data is collected, fully prepared for Google Play Data Safety declaration.

---

## 🗺️ Future Roadmap

- [ ] PDF Monthly Summary statement export and WhatsApp sharing.
- [ ] Push notifications for monthly bill due dates and daily meal reminders.
- [ ] Direct bKash / Nagad payment integration links.
- [ ] Receipt OCR scanning for grocery receipts.

---

## 📄 License
This project is proprietary and built for MessHub users in Bangladesh.
