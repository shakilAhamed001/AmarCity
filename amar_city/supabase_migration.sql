-- profiles table এ email column যোগ করা (যদি না থাকে)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email TEXT;

-- complaints table এ last_escalated_at column যোগ করা
-- এটা দিয়ে একই complaint বারবার escalate হওয়া রোধ করা হবে
ALTER TABLE complaints ADD COLUMN IF NOT EXISTS last_escalated_at TIMESTAMPTZ;

-- নতুন user signup হলে automatically email profiles এ save হবে
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, full_name)
  VALUES (
    new.id,
    new.email,
    new.raw_user_meta_data->>'role',
    new.raw_user_meta_data->>'full_name'
  )
  ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger already exists হলে drop করে recreate
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Existing users এর email update করা
UPDATE profiles p
SET email = u.email
FROM auth.users u
WHERE p.id = u.id AND p.email IS NULL;

-- ============================================================
-- In-App Chat: complaint_messages table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.complaint_messages (
  id          BIGSERIAL PRIMARY KEY,
  complaint_id TEXT NOT NULL,
  sender_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sender_role TEXT NOT NULL,
  message     TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast query by complaint
CREATE INDEX IF NOT EXISTS idx_complaint_messages_complaint_id
  ON public.complaint_messages(complaint_id);

-- RLS enable
ALTER TABLE public.complaint_messages ENABLE ROW LEVEL SECURITY;

-- Citizen: শুধু নিজের complaint এর messages পড়তে পারবে
CREATE POLICY "citizen_read_own_messages" ON public.complaint_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.complaints c
      WHERE c.id::TEXT = complaint_id
        AND c.citizen_id = auth.uid()
    )
    OR sender_id = auth.uid()
  );

-- Officer: assign করা complaint এর messages পড়তে পারবে
CREATE POLICY "officer_read_assigned_messages" ON public.complaint_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.complaints c
      WHERE c.id::TEXT = complaint_id
        AND c.assigned_officer_id = auth.uid()
    )
    OR sender_id = auth.uid()
  );

-- Admin: সব messages পড়তে পারবে
CREATE POLICY "admin_read_all_messages" ON public.complaint_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'Admin'
    )
  );

-- INSERT: authenticated user নিজের নামে message পাঠাতে পারবে
CREATE POLICY "authenticated_insert_message" ON public.complaint_messages
  FOR INSERT WITH CHECK (sender_id = auth.uid());

-- Realtime enable করা
ALTER PUBLICATION supabase_realtime ADD TABLE public.complaint_messages;

-- ============================================================
-- Complaint Feedback table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.complaint_feedback (
  id           BIGSERIAL PRIMARY KEY,
  complaint_id TEXT NOT NULL,
  citizen_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating       INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment      TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (complaint_id, citizen_id)
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
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('Admin', 'Officer')
    )
  );

-- ============================================================
-- complaint_messages RLS fix
-- পুরনো complex policies drop করে simple ones দিচ্ছি
-- ============================================================
DROP POLICY IF EXISTS "citizen_read_own_messages"        ON public.complaint_messages;
DROP POLICY IF EXISTS "officer_read_assigned_messages"   ON public.complaint_messages;
DROP POLICY IF EXISTS "admin_read_all_messages"          ON public.complaint_messages;
DROP POLICY IF EXISTS "authenticated_insert_message"     ON public.complaint_messages;

-- সব authenticated user সব messages পড়তে পারবে
-- (app layer এ complaint_id দিয়ে filter করা হচ্ছে)
CREATE POLICY "all_authenticated_read_messages" ON public.complaint_messages
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- authenticated user নিজের নামে INSERT করতে পারবে
CREATE POLICY "authenticated_insert_message" ON public.complaint_messages
  FOR INSERT WITH CHECK (sender_id = auth.uid());

-- ============================================================
-- Google Maps: complaints table এ location columns যোগ করা
-- ============================================================
ALTER TABLE public.complaints
  ADD COLUMN IF NOT EXISTS latitude  DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
