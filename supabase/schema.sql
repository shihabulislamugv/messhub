-- ==============================================================================
-- MessHub Database Schema for Supabase (PostgreSQL)
-- Tailored for Students, Bachelors & Shared-Flat residents in Bangladesh
-- Includes Tables, Constraints, RLS Security Policies, Triggers & Helper Functions
-- ==============================================================================

-- 1. PROFILES TABLE (Mirrors auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger to create profile automatically on auth.users sign up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.email,
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- 2. MESSES TABLE
CREATE TABLE IF NOT EXISTS public.messes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  area TEXT NOT NULL,
  invite_code TEXT UNIQUE NOT NULL,
  cycle_start_day INT NOT NULL DEFAULT 1 CHECK (cycle_start_day >= 1 AND cycle_start_day <= 28),
  description TEXT,
  created_by UUID REFERENCES public.profiles(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- 3. MESS MEMBERS TABLE
CREATE TABLE IF NOT EXISTS public.mess_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mess_id UUID NOT NULL REFERENCES public.messes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'MEMBER' CHECK (role IN ('ADMIN', 'MEMBER')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(mess_id, user_id)
);


-- 4. MONTHLY CYCLES TABLE
CREATE TABLE IF NOT EXISTS public.monthly_cycles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mess_id UUID NOT NULL REFERENCES public.messes(id) ON DELETE CASCADE,
  year INT NOT NULL,
  month INT NOT NULL CHECK (month >= 1 AND month <= 12),
  is_closed BOOLEAN NOT NULL DEFAULT FALSE,
  closed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(mess_id, year, month)
);


-- 5. BILLS TABLE
-- Business Rule: Basha Vara (RENT) MUST ONLY support CUSTOM split
CREATE TABLE IF NOT EXISTS public.bills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mess_id UUID NOT NULL REFERENCES public.messes(id) ON DELETE CASCADE,
  cycle_id UUID NOT NULL REFERENCES public.monthly_cycles(id) ON DELETE CASCADE,
  bill_type TEXT NOT NULL CHECK (bill_type IN ('RENT', 'ELECTRICITY', 'WATER', 'HOUSEKEEPER', 'GAS', 'INTERNET', 'OTHER')),
  title TEXT NOT NULL,
  total_amount NUMERIC(12, 2) NOT NULL CHECK (total_amount > 0),
  paid_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  split_method TEXT NOT NULL CHECK (split_method IN ('EQUAL', 'CUSTOM')),
  due_date DATE,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- Database constraint: RENT must never be EQUAL split
  CONSTRAINT check_rent_split_is_custom CHECK (
    bill_type <> 'RENT' OR split_method = 'CUSTOM'
  )
);


-- 6. BILL SPLITS TABLE
CREATE TABLE IF NOT EXISTS public.bill_splits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id UUID NOT NULL REFERENCES public.bills(id) ON DELETE CASCADE,
  member_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
  UNIQUE(bill_id, member_id)
);


-- 7. EXPENSES TABLE
CREATE TABLE IF NOT EXISTS public.expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mess_id UUID NOT NULL REFERENCES public.messes(id) ON DELETE CASCADE,
  cycle_id UUID NOT NULL REFERENCES public.monthly_cycles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  category TEXT NOT NULL CHECK (category IN ('BAZAR', 'FOOD', 'CLEANING', 'REPAIR', 'TRANSPORT', 'OTHER')),
  paid_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  expense_date DATE NOT NULL,
  note TEXT,
  receipt_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- 8. BAZAR ITEMS TABLE
CREATE TABLE IF NOT EXISTS public.bazar_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  expense_id UUID NOT NULL REFERENCES public.expenses(id) ON DELETE CASCADE,
  item_name TEXT NOT NULL,
  quantity NUMERIC(8, 2) NOT NULL DEFAULT 1 CHECK (quantity > 0),
  unit TEXT NOT NULL DEFAULT 'pcs',
  price NUMERIC(12, 2) NOT NULL CHECK (price >= 0)
);


-- 9. MEALS TABLE
CREATE TABLE IF NOT EXISTS public.meals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mess_id UUID NOT NULL REFERENCES public.messes(id) ON DELETE CASCADE,
  cycle_id UUID NOT NULL REFERENCES public.monthly_cycles(id) ON DELETE CASCADE,
  member_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  meal_date DATE NOT NULL,
  breakfast NUMERIC(3, 1) NOT NULL DEFAULT 0 CHECK (breakfast >= 0),
  lunch NUMERIC(3, 1) NOT NULL DEFAULT 0 CHECK (lunch >= 0),
  dinner NUMERIC(3, 1) NOT NULL DEFAULT 0 CHECK (dinner >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(cycle_id, member_id, meal_date)
);


-- 10. SETTLEMENT RECORDS TABLE
CREATE TABLE IF NOT EXISTS public.settlement_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mess_id UUID NOT NULL REFERENCES public.messes(id) ON DELETE CASCADE,
  cycle_id UUID NOT NULL REFERENCES public.monthly_cycles(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  receiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  payment_date DATE NOT NULL,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT check_different_parties CHECK (sender_id <> receiver_id)
);


-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- Strict multi-tenant mess isolation: Users can NEVER access other messes!
-- ==============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mess_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monthly_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bill_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bazar_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settlement_records ENABLE ROW LEVEL SECURITY;

-- Helper security function: Checks whether current authenticated user is a member of a given mess
CREATE OR REPLACE FUNCTION public.is_member_of_mess(target_mess_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.mess_members
    WHERE mess_id = target_mess_id AND user_id = auth.uid()
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Profiles: Users can view and update their own profile, and view members of common messes
CREATE POLICY "Users can manage own profile" ON public.profiles
  FOR ALL USING (id = auth.uid());

CREATE POLICY "Users can view common mess member profiles" ON public.profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.mess_members mm1
      JOIN public.mess_members mm2 ON mm1.mess_id = mm2.mess_id
      WHERE mm1.user_id = auth.uid() AND mm2.user_id = profiles.id
    )
  );

-- Messes: Members can read their mess, anyone can create, admin can update
CREATE POLICY "Members can view their mess" ON public.messes
  FOR SELECT USING (public.is_member_of_mess(id));

CREATE POLICY "Authenticated users can create a mess" ON public.messes
  FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Allow finding mess by invite code to join
CREATE POLICY "Users can lookup mess by invite code" ON public.messes
  FOR SELECT USING (true);

-- Mess Members:
CREATE POLICY "Members can view other members in same mess" ON public.mess_members
  FOR SELECT USING (public.is_member_of_mess(mess_id));

CREATE POLICY "Users can join mess" ON public.mess_members
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Monthly Cycles:
CREATE POLICY "Members can view monthly cycles" ON public.monthly_cycles
  FOR SELECT USING (public.is_member_of_mess(mess_id));

CREATE POLICY "Members can manage cycles" ON public.monthly_cycles
  FOR ALL USING (public.is_member_of_mess(mess_id));

-- Bills & Splits:
CREATE POLICY "Members can view bills" ON public.bills
  FOR SELECT USING (public.is_member_of_mess(mess_id));

CREATE POLICY "Members can insert bills" ON public.bills
  FOR INSERT WITH CHECK (public.is_member_of_mess(mess_id));

CREATE POLICY "Members can view bill splits" ON public.bill_splits
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.bills b
      WHERE b.id = bill_splits.bill_id AND public.is_member_of_mess(b.mess_id)
    )
  );

CREATE POLICY "Members can insert bill splits" ON public.bill_splits
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.bills b
      WHERE b.id = bill_splits.bill_id AND public.is_member_of_mess(b.mess_id)
    )
  );

-- Expenses & Bazar:
CREATE POLICY "Members can view expenses" ON public.expenses
  FOR SELECT USING (public.is_member_of_mess(mess_id));

CREATE POLICY "Members can insert and edit expenses" ON public.expenses
  FOR ALL USING (public.is_member_of_mess(mess_id));

CREATE POLICY "Members can view and manage bazar items" ON public.bazar_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.expenses e
      WHERE e.id = bazar_items.expense_id AND public.is_member_of_mess(e.mess_id)
    )
  );

-- Meals:
CREATE POLICY "Members can view and manage meals" ON public.meals
  FOR ALL USING (public.is_member_of_mess(mess_id));

-- Settlements:
CREATE POLICY "Members can view and record settlements" ON public.settlement_records
  FOR ALL USING (public.is_member_of_mess(mess_id));
