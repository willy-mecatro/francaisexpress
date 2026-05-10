-- ============================================================
-- FrançaisExpress — SUPABASE SCHEMA COMPLET
-- Version: 1.0
-- Instructions: Coller ce fichier entier dans
--   Supabase Dashboard > SQL Editor > New Query > Run
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================
-- 1. PROFILES (étend auth.users)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id                  UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name           TEXT NOT NULL DEFAULT '',
  avatar_url          TEXT,
  native_language     TEXT DEFAULT 'pt-BR',
  current_level       TEXT DEFAULT 'A1' CHECK (current_level IN ('A1','A2','B1','B2')),
  goal                TEXT DEFAULT 'imigrar' CHECK (goal IN ('imigrar','trabalho','viagem','estudo','cultura')),
  daily_goal_min      INTEGER DEFAULT 15,
  xp_total            INTEGER DEFAULT 0,
  xp_this_week        INTEGER DEFAULT 0,
  streak_current      INTEGER DEFAULT 0,
  streak_best         INTEGER DEFAULT 0,
  streak_last_date    DATE,
  subscription        TEXT DEFAULT 'free' CHECK (subscription IN ('free','premium','business')),
  subscription_until  TIMESTAMPTZ,
  stripe_customer_id  TEXT,
  onboarding_done     BOOLEAN DEFAULT false,
  preferences         JSONB DEFAULT '{
    "notifications": true,
    "audio_autoplay": true,
    "audio_speed": 1,
    "show_ipa": true,
    "dialect": "standard",
    "dark_mode": false
  }'::JSONB,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 2. MODULES (A1, A2, B1, B2)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.modules (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  level           TEXT NOT NULL CHECK (level IN ('A1','A2','B1','B2')),
  title           TEXT NOT NULL,
  title_pt        TEXT NOT NULL,
  description_pt  TEXT,
  icon            TEXT DEFAULT '📚',
  order_index     INTEGER NOT NULL,
  is_premium      BOOLEAN DEFAULT false,
  is_active       BOOLEAN DEFAULT true,
  lessons_count   INTEGER DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 3. LESSONS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.lessons (
  id               UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  module_id        UUID REFERENCES public.modules(id) ON DELETE CASCADE,
  title            TEXT NOT NULL,
  title_pt         TEXT NOT NULL,
  description_pt   TEXT,
  lesson_type      TEXT CHECK (lesson_type IN (
    'vocabulary','dialogue','grammar',
    'pronunciation','listening','quiz'
  )),
  level            TEXT NOT NULL CHECK (level IN ('A1','A2','B1','B2')),
  order_index      INTEGER NOT NULL,
  icon             TEXT DEFAULT '📖',
  xp_reward        INTEGER DEFAULT 10,
  duration_minutes INTEGER DEFAULT 10,
  is_premium       BOOLEAN DEFAULT false,
  is_active        BOOLEAN DEFAULT true,
  content          JSONB NOT NULL DEFAULT '{}',
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 4. EXERCISES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.exercises (
  id             UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  lesson_id      UUID REFERENCES public.lessons(id) ON DELETE CASCADE,
  exercise_type  TEXT NOT NULL CHECK (exercise_type IN (
    'multiple_choice','fill_blank','drag_drop',
    'audio_listen','audio_repeat','translation',
    'matching','true_false','sentence_order'
  )),
  question       TEXT NOT NULL,
  question_pt    TEXT,
  options        JSONB,
  correct_answer TEXT,
  hint_pt        TEXT,
  audio_url      TEXT,
  xp_reward      INTEGER DEFAULT 5,
  order_index    INTEGER NOT NULL,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 5. USER_PROGRESS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_progress (
  id               UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id          UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  lesson_id        UUID REFERENCES public.lessons(id) ON DELETE CASCADE,
  status           TEXT DEFAULT 'not_started' CHECK (
    status IN ('not_started','in_progress','completed')
  ),
  score_percent    INTEGER DEFAULT 0,
  xp_earned        INTEGER DEFAULT 0,
  attempts         INTEGER DEFAULT 0,
  time_spent_sec   INTEGER DEFAULT 0,
  completed_at     TIMESTAMPTZ,
  last_accessed_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, lesson_id)
);

-- ============================================================
-- 6. EXERCISE_ATTEMPTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.exercise_attempts (
  id           UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id      UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  exercise_id  UUID REFERENCES public.exercises(id) ON DELETE CASCADE,
  user_answer  TEXT,
  is_correct   BOOLEAN,
  time_taken_ms INTEGER,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 7. CHAT_SESSIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.chat_sessions (
  id            UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id       UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  title         TEXT DEFAULT 'Nova conversa',
  message_count INTEGER DEFAULT 0,
  tokens_used   INTEGER DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 8. CHAT_MESSAGES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.chat_messages (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  session_id  UUID REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
  role        TEXT NOT NULL CHECK (role IN ('user','assistant','system')),
  content     TEXT NOT NULL,
  corrections JSONB,
  tokens      INTEGER DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 9. PRONUNCIATION_SCORES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.pronunciation_scores (
  id             UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id        UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  lesson_id      UUID REFERENCES public.lessons(id),
  target_text    TEXT NOT NULL,
  user_audio_url TEXT,
  score          NUMERIC(5,2),
  phoneme_scores JSONB,
  feedback_pt    TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 10. ACHIEVEMENTS (badges disponibles)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.achievements (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  slug            TEXT UNIQUE NOT NULL,
  title_pt        TEXT NOT NULL,
  description_pt  TEXT,
  icon            TEXT DEFAULT '🏅',
  category        TEXT CHECK (category IN (
    'streak','lessons','pronunciation','chat','special'
  )),
  condition_type  TEXT,
  condition_value INTEGER,
  xp_bonus        INTEGER DEFAULT 0,
  is_rare         BOOLEAN DEFAULT false
);

-- ============================================================
-- 11. USER_ACHIEVEMENTS (badges gagnés)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.user_achievements (
  id             UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id        UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  achievement_id UUID REFERENCES public.achievements(id),
  earned_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);

-- ============================================================
-- 12. SUBSCRIPTIONS (Stripe)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id                   UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id              UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  stripe_sub_id        TEXT UNIQUE,
  stripe_price_id      TEXT,
  plan                 TEXT CHECK (plan IN ('free','premium','business')),
  status               TEXT CHECK (status IN (
    'active','canceled','past_due','trialing'
  )),
  current_period_start TIMESTAMPTZ,
  current_period_end   TIMESTAMPTZ,
  cancel_at_period_end BOOLEAN DEFAULT false,
  created_at           TIMESTAMPTZ DEFAULT NOW(),
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 13. BLOG_POSTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.blog_posts (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  slug            TEXT UNIQUE NOT NULL,
  title           TEXT NOT NULL,
  excerpt         TEXT,
  content         TEXT NOT NULL,
  cover_image_url TEXT,
  category        TEXT CHECK (category IN (
    'pronuncia','gramatica','imigracao',
    'vocabulario','tef-tcf','dicas'
  )),
  tags            TEXT[] DEFAULT '{}',
  author_id       UUID REFERENCES public.profiles(id),
  is_published    BOOLEAN DEFAULT false,
  reading_time_min INTEGER DEFAULT 5,
  views           INTEGER DEFAULT 0,
  published_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- INDEXES (performance)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_lessons_module    ON public.lessons(module_id);
CREATE INDEX IF NOT EXISTS idx_lessons_level     ON public.lessons(level);
CREATE INDEX IF NOT EXISTS idx_exercises_lesson  ON public.exercises(lesson_id);
CREATE INDEX IF NOT EXISTS idx_progress_user     ON public.user_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_progress_lesson   ON public.user_progress(lesson_id);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_user ON public.chat_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_msgs_session ON public.chat_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_pronun_user       ON public.pronunciation_scores(user_id);
CREATE INDEX IF NOT EXISTS idx_achiev_user       ON public.user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_blog_published    ON public.blog_posts(is_published, published_at DESC);

-- ============================================================
-- LEADERBOARD VIEW
-- ============================================================
CREATE OR REPLACE VIEW public.leaderboard_weekly AS
SELECT
  p.id,
  p.full_name,
  p.avatar_url,
  p.current_level,
  p.xp_this_week,
  p.streak_current,
  ROW_NUMBER() OVER (ORDER BY p.xp_this_week DESC) AS rank
FROM public.profiles p
WHERE p.xp_this_week > 0
ORDER BY p.xp_this_week DESC
LIMIT 100;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE public.profiles           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_progress      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_attempts  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_sessions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pronunciation_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions      ENABLE ROW LEVEL SECURITY;

-- Chaque user ne voit que ses propres données
CREATE POLICY "profiles_own"      ON public.profiles           FOR ALL USING (auth.uid() = id);
CREATE POLICY "progress_own"      ON public.user_progress      FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "attempts_own"      ON public.exercise_attempts  FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "chat_sess_own"     ON public.chat_sessions      FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "chat_msgs_own"     ON public.chat_messages      FOR ALL
  USING (session_id IN (SELECT id FROM public.chat_sessions WHERE user_id = auth.uid()));
CREATE POLICY "pronun_own"        ON public.pronunciation_scores FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "achiev_own"        ON public.user_achievements  FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "subs_own"          ON public.subscriptions      FOR ALL USING (auth.uid() = user_id);

-- Lecture publique (sans connexion) pour le contenu pédagogique
ALTER TABLE public.modules      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lessons      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blog_posts   ENABLE ROW LEVEL SECURITY;

CREATE POLICY "modules_read"    ON public.modules      FOR SELECT USING (is_active = true);
CREATE POLICY "lessons_read"    ON public.lessons      FOR SELECT USING (is_active = true);
CREATE POLICY "exercises_read"  ON public.exercises    FOR SELECT USING (true);
CREATE POLICY "achiev_read"     ON public.achievements FOR SELECT USING (true);
CREATE POLICY "blog_read"       ON public.blog_posts   FOR SELECT USING (is_published = true);

-- ============================================================
-- FONCTION: auto-créer profil après inscription
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- FONCTION: award_xp (ajouter XP à un utilisateur)
-- ============================================================
CREATE OR REPLACE FUNCTION public.award_xp(p_user_id UUID, p_xp INTEGER)
RETURNS VOID AS $$
BEGIN
  UPDATE public.profiles
  SET
    xp_total     = xp_total + p_xp,
    xp_this_week = xp_this_week + p_xp,
    updated_at   = NOW()
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- FONCTION: update_streak (mettre à jour la séquence)
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_streak(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  v_last_date DATE;
  v_today     DATE := CURRENT_DATE;
BEGIN
  SELECT streak_last_date INTO v_last_date
  FROM public.profiles WHERE id = p_user_id;

  IF v_last_date = v_today THEN
    RETURN;
  ELSIF v_last_date = v_today - INTERVAL '1 day' THEN
    UPDATE public.profiles SET
      streak_current = streak_current + 1,
      streak_best    = GREATEST(streak_best, streak_current + 1),
      streak_last_date = v_today
    WHERE id = p_user_id;
  ELSE
    UPDATE public.profiles SET
      streak_current   = 1,
      streak_last_date = v_today
    WHERE id = p_user_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- FONCTION: reset_weekly_xp (à exécuter chaque lundi via cron)
-- Activer dans: Supabase > Database > Extensions > pg_cron
-- SELECT cron.schedule('reset-xp', '0 0 * * 1', 'SELECT public.reset_weekly_xp()');
-- ============================================================
CREATE OR REPLACE FUNCTION public.reset_weekly_xp()
RETURNS VOID AS $$
BEGIN
  UPDATE public.profiles SET xp_this_week = 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
