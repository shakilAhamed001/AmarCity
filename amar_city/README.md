# 🏙️ AmarCity — Smart Municipality Complaint Management Platform

A Flutter-based smart city platform where citizens can report municipal issues, officers manage and resolve complaints, and admins oversee the entire system.

---

## 📱 Features

| Role | Features |
|------|----------|
| **Citizen** | Submit complaints, track status, upvote community issues, receive SMS/in-app notifications, rate resolved complaints, pick location on map |
| **Officer** | View assigned complaints, update status, upload after-photos, chat with citizen |
| **Admin** | Assign officers, view all complaints, department reports, export PDF, manage users |
| **System** | Auto-escalation after 48hrs, SMS fallback alerts, dark/light mode, Bangla/English language |

---

## 🛠️ Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Supabase (PostgreSQL + Auth + Storage + Edge Functions + Realtime)
- **Maps:** flutter_map (OpenStreetMap)
- **SMS:** SSL Wireless BD / Twilio (via Supabase Edge Function)
- **PDF:** pdf + printing packages

---

## 🚀 Getting Started

### 1. Clone & Install
```bash
git clone <repo-url>
cd amar_city
flutter pub get
```

### 2. Supabase Setup
- Create a project at [supabase.com](https://supabase.com)
- Copy your `Project URL` and `anon key`
- Update `lib/services/supabase_service.dart`:
```dart
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

### 3. Run SQL (Supabase Dashboard → SQL Editor)
Run all SQL from the **[Database Setup](#-database-setup-sql)** section below.

### 4. Run the App
```bash
flutter run
```

---

## 🗄️ Database Setup (SQL)

Run these SQL statements in order in **Supabase Dashboard → SQL Editor**.

---

### 1. Profiles Table

```sql
-- profiles table — stores all user info (Citizen, Officer, Admin)
CREATE TABLE IF NOT EXISTS public.profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email         TEXT,
  full_name     TEXT,
  role          TEXT NOT NULL DEFAULT 'Citizen', -- 'Citizen' | 'Officer' | 'Admin'
  department    TEXT,
  phone         TEXT,
  avatar_url    TEXT,
  house_number  TEXT,
  street_name   TEXT,
  ward_number   TEXT,
  city          TEXT,
  state         TEXT,
  postal_code   TEXT,
  country       TEXT DEFAULT 'Bangladesh',
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- RLS enable
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Anyone can read profiles
CREATE POLICY "profiles_read_all" ON public.profiles
  FOR SELECT USING (true);

-- User can update own profile
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- System can insert (via trigger)
CREATE POLICY "profiles_insert_trigger" ON public.profiles
  FOR INSERT WITH CHECK (true);
```

---

### 2. Auto-create Profile on Signup (Trigger)

```sql
-- Function: new user signup হলে automatically profiles table এ insert হবে
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, full_name, phone)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'role', 'Citizen'),
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'phone'
  )
  ON CONFLICT (id) DO UPDATE
    SET email     = EXCLUDED.email,
        full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
        role      = COALESCE(EXCLUDED.role, profiles.role);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: auth.users এ INSERT হলে function call হবে
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Existing users এর email sync করা
UPDATE profiles p
SET email = u.email
FROM auth.users u
WHERE p.id = u.id AND p.email IS NULL;
```

---

### 3. Complaints Table

```sql
-- complaints table — citizen দের submit করা সব অভিযোগ
CREATE TABLE IF NOT EXISTS public.complaints (
  id                   BIGSERIAL PRIMARY KEY,
  citizen_id           UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title                TEXT NOT NULL,
  description          TEXT,
  category             TEXT NOT NULL, -- 'ROAD'|'LIGHTING'|'GARBAGE'|'DRAINAGE'|'WATER'|'ELECTRICITY'
  location             TEXT,
  latitude             DOUBLE PRECISION,
  longitude            DOUBLE PRECISION,
  status               TEXT NOT NULL DEFAULT 'New', -- 'New'|'In progress'|'Resolved'|'Escalated'
  assigned_department  TEXT,
  assigned_officer_id  UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  image_urls           TEXT[],
  after_image_url      TEXT,
  last_escalated_at    TIMESTAMPTZ,
  created_at           TIMESTAMPTZ DEFAULT NOW(),
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_complaints_citizen_id    ON public.complaints(citizen_id);
CREATE INDEX IF NOT EXISTS idx_complaints_status        ON public.complaints(status);
CREATE INDEX IF NOT EXISTS idx_complaints_department    ON public.complaints(assigned_department);
CREATE INDEX IF NOT EXISTS idx_complaints_officer_id    ON public.complaints(assigned_officer_id);

-- RLS enable
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;

-- Citizen: নিজের complaints সব কাজ করতে পারবে
CREATE POLICY "citizen_manage_own_complaints" ON public.complaints
  FOR ALL USING (citizen_id = auth.uid())
  WITH CHECK (citizen_id = auth.uid());

-- Officer: assigned complaints পড়তে ও update করতে পারবে
CREATE POLICY "officer_read_assigned" ON public.complaints
  FOR SELECT USING (assigned_officer_id = auth.uid());

CREATE POLICY "officer_update_assigned" ON public.complaints
  FOR UPDATE USING (assigned_officer_id = auth.uid());

-- Admin: সব complaints পড়তে ও update করতে পারবে
CREATE POLICY "admin_all_complaints" ON public.complaints
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'Admin'
    )
  );

-- Community feed: authenticated users সব non-resolved complaints পড়তে পারবে
CREATE POLICY "authenticated_read_complaints" ON public.complaints
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- Auto-update updated_at on change
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER complaints_updated_at
  BEFORE UPDATE ON public.complaints
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

---

### 4. Complaint Status History Table

```sql
-- complaint_status_history — প্রতিটি status change এর timeline record
CREATE TABLE IF NOT EXISTS public.complaint_status_history (
  id           BIGSERIAL PRIMARY KEY,
  complaint_id TEXT NOT NULL,
  status       TEXT NOT NULL,
  comment      TEXT,
  updated_by   TEXT NOT NULL, -- officer UUID or 'system' (auto-escalation)
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_status_history_complaint_id
  ON public.complaint_status_history(complaint_id);

ALTER TABLE public.complaint_status_history ENABLE ROW LEVEL SECURITY;

-- Authenticated users সব history পড়তে পারবে
CREATE POLICY "authenticated_read_history" ON public.complaint_status_history
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- Authenticated users insert করতে পারবে
CREATE POLICY "authenticated_insert_history" ON public.complaint_status_history
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
```

---

### 5. Notifications Table

```sql
-- notifications — in-app notification system
CREATE TABLE IF NOT EXISTS public.notifications (
  id           BIGSERIAL PRIMARY KEY,
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title        TEXT NOT NULL,
  body         TEXT NOT NULL,
  type         TEXT NOT NULL, -- 'assignment'|'status_update'|'escalation'|'feedback'
  complaint_id TEXT,
  is_read      BOOLEAN DEFAULT FALSE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id
  ON public.notifications(user_id);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- User: নিজের notifications পড়তে ও update করতে পারবে
CREATE POLICY "user_manage_own_notifications" ON public.notifications
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- System/Officer/Admin: যেকোনো user কে notification পাঠাতে পারবে
CREATE POLICY "authenticated_insert_notification" ON public.notifications
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
```

---

### 6. Complaint Upvotes Table

```sql
-- complaint_upvotes — community feed এ "আমিও ভুক্তভোগী" feature
CREATE TABLE IF NOT EXISTS public.complaint_upvotes (
  id           BIGSERIAL PRIMARY KEY,
  complaint_id TEXT NOT NULL,
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (complaint_id, user_id) -- একজন user একটি complaint এ একবারই upvote করতে পারবে
);

CREATE INDEX IF NOT EXISTS idx_upvotes_complaint_id
  ON public.complaint_upvotes(complaint_id);

ALTER TABLE public.complaint_upvotes ENABLE ROW LEVEL SECURITY;

-- Authenticated users সব upvotes পড়তে পারবে
CREATE POLICY "authenticated_read_upvotes" ON public.complaint_upvotes
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- User: নিজের upvote insert ও delete করতে পারবে
CREATE POLICY "user_manage_own_upvotes" ON public.complaint_upvotes
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
```

---

### 7. Complaint Messages Table (In-App Chat)

```sql
-- complaint_messages — citizen ও officer এর মধ্যে real-time chat
CREATE TABLE IF NOT EXISTS public.complaint_messages (
  id           BIGSERIAL PRIMARY KEY,
  complaint_id TEXT NOT NULL,
  sender_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sender_role  TEXT NOT NULL, -- 'Citizen'|'Officer'|'Admin'
  message      TEXT NOT NULL,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_complaint_messages_complaint_id
  ON public.complaint_messages(complaint_id);

ALTER TABLE public.complaint_messages ENABLE ROW LEVEL SECURITY;

-- Authenticated users সব messages পড়তে পারবে (app layer এ filter হয়)
CREATE POLICY "all_authenticated_read_messages" ON public.complaint_messages
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- Authenticated user নিজের নামে message পাঠাতে পারবে
CREATE POLICY "authenticated_insert_message" ON public.complaint_messages
  FOR INSERT WITH CHECK (sender_id = auth.uid());

-- Realtime enable করা — live chat এর জন্য
ALTER PUBLICATION supabase_realtime ADD TABLE public.complaint_messages;
```

---

### 8. Complaint Feedback Table

```sql
-- complaint_feedback — resolved complaint এ citizen এর rating ও comment
CREATE TABLE IF NOT EXISTS public.complaint_feedback (
  id           BIGSERIAL PRIMARY KEY,
  complaint_id TEXT NOT NULL,
  citizen_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating       INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment      TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (complaint_id, citizen_id) -- একটি complaint এ একজন citizen একবারই feedback দিতে পারবে
);

ALTER TABLE public.complaint_feedback ENABLE ROW LEVEL SECURITY;

-- Citizen: নিজের feedback insert ও read করতে পারবে
CREATE POLICY "citizen_manage_own_feedback" ON public.complaint_feedback
  FOR ALL USING (citizen_id = auth.uid())
  WITH CHECK (citizen_id = auth.uid());

-- Admin ও Officer: সব feedback read করতে পারবে
CREATE POLICY "staff_read_all_feedback" ON public.complaint_feedback
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('Admin', 'Officer')
    )
  );
```

---

### 9. Storage Buckets

```sql
-- complaint-images bucket — before ও after photos store হবে
INSERT INTO storage.buckets (id, name, public)
VALUES ('complaint-images', 'complaint-images', true)
ON CONFLICT (id) DO NOTHING;

-- Authenticated users upload করতে পারবে
CREATE POLICY "authenticated_upload_images" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'complaint-images' AND auth.uid() IS NOT NULL
  );

-- সবাই images পড়তে পারবে (public bucket)
CREATE POLICY "public_read_images" ON storage.objects
  FOR SELECT USING (bucket_id = 'complaint-images');

-- avatars bucket — profile photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "authenticated_upload_avatars" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars' AND auth.uid() IS NOT NULL
  );

CREATE POLICY "public_read_avatars" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "user_update_own_avatar" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'avatars' AND auth.uid() IS NOT NULL
  );
```

---

### 10. Additional Columns (Migration)

```sql
-- phone column — SMS alert এর জন্য
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS phone TEXT;

-- location coordinates — map এ complaint দেখানোর জন্য
ALTER TABLE public.complaints
  ADD COLUMN IF NOT EXISTS latitude  DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- auto-escalation tracking
ALTER TABLE public.complaints
  ADD COLUMN IF NOT EXISTS last_escalated_at TIMESTAMPTZ;
```

---

### 11. Admin User Setup

```sql
-- Signup করার পরে manually Admin role দিতে হবে
-- Supabase Dashboard → Table Editor → profiles → user এর role 'Admin' করো
-- অথবা SQL দিয়ে:
UPDATE public.profiles
SET role = 'Admin'
WHERE email = 'your-admin@email.com';
```

---

## 📲 SMS Setup (SSL Wireless BD)

### 1. Deploy Edge Function
```bash
supabase functions deploy send-sms
```

### 2. Set Secrets (Supabase Dashboard → Settings → Edge Functions → Secrets)
```
SMS_PROVIDER   = ssl
SSL_SID        = <your SSL Wireless SID>
SSL_API_TOKEN  = <your SSL Wireless API Token>
SSL_CSMS_ID    = <your CSMS ID>
```

### 3. For Twilio (alternative)
```
SMS_PROVIDER        = twilio
TWILIO_ACCOUNT_SID  = ACxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN   = your_auth_token
TWILIO_FROM_NUMBER  = +1xxxxxxxxxx
```

> ⚠️ Twilio trial account শুধু verified numbers এ SMS পাঠাতে পারে।

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── services/
│   ├── supabase_service.dart          # Supabase client + AuthService
│   ├── notification_service.dart      # In-app notifications
│   ├── escalation_service.dart        # Auto-escalation (48hr)
│   ├── sms_service.dart               # SMS via Edge Function
│   ├── theme_notifier.dart            # Dark/Light mode
│   └── locale_service.dart            # Bangla/English toggle
├── screens/
│   ├── account/                       # Login, Create Account
│   ├── citizen/                       # Citizen screens
│   ├── officer/                       # Officer screens
│   ├── admin/                         # Admin screens
│   ├── complaint_tracking/            # Detail, Chat, Report
│   ├── notifications/                 # Notification screen
│   └── splash/                        # Splash screen
└── widgets/
    └── profile_avatar_widget.dart
supabase/
└── functions/
    └── send-sms/
        └── index.ts                   # SMS Edge Function
```

---

## 🔄 Auto-Escalation Logic

- App start এ `EscalationService.checkAndEscalate()` call হয়
- `New` বা `In progress` status এর complaints যেগুলো **48 ঘণ্টার বেশি** update হয়নি → `Escalated` হয়
- `last_escalated_at` দিয়ে একই complaint বারবার escalate হওয়া রোধ করা হয়
- Admin ও Citizen উভয়কে notification পাঠানো হয়

---

## 🌐 Localization

- English (`en`) ও বাংলা (`bn`) support
- `lib/l10n/` folder এ `.arb` files
- App এ toggle button দিয়ে language switch করা যায়

---

## 📦 Key Dependencies

```yaml
supabase_flutter: ^2.3.4
flutter_map: ^7.0.2
latlong2: ^0.9.1
geolocator: ^13.0.2
image_picker: ^1.0.0
pdf: ^3.10.8
printing: ^5.12.0
shared_preferences: ^2.2.3
intl: ^0.20.2
```
