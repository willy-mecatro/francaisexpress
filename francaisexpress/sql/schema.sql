-- ============================================================
-- FrançaisExpress — Supabase Schema Completo
-- ============================================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================
-- USERS (estende auth.users do Supabase)
-- ============================================================
CREATE TABLE public.profiles (
  id              UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name       TEXT NOT NULL,
  avatar_url      TEXT,
  native_language TEXT DEFAULT 'pt-BR',
  current_level   TEXT DEFAULT 'A1' CHECK (current_level IN ('A1','A2','B1','B2')),
  xp_total        INTEGER DEFAULT 0,
  xp_this_week    INTEGER DEFAULT 0,
  streak_current  INTEGER DEFAULT 0,
  streak_best     INTEGER DEFAULT 0,
  streak_last_date DATE,
  subscription    TEXT DEFAULT 'free' CHECK (subscription IN ('free','premium','business')),
  subscription_until TIMESTAMPTZ,
  stripe_customer_id TEXT,
  onboarding_done BOOLEAN DEFAULT false,
  preferences     JSONB DEFAULT '{"notifications":true,"dark_mode":false,"daily_goal":10}'::JSONB,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- MODULES (Níveis A1, A2, B1, B2)
-- ============================================================
CREATE TABLE public.modules (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  level           TEXT NOT NULL CHECK (level IN ('A1','A2','B1','B2')),
  title           TEXT NOT NULL,
  title_pt        TEXT NOT NULL,
  description     TEXT,
  description_pt  TEXT,
  icon            TEXT DEFAULT '📚',
  order_index     INTEGER NOT NULL,
  is_premium      BOOLEAN DEFAULT false,
  is_active       BOOLEAN DEFAULT true,
  lessons_count   INTEGER DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- LESSONS
-- ============================================================
CREATE TABLE public.lessons (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  module_id       UUID REFERENCES public.modules(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  title_pt        TEXT NOT NULL,
  description_pt  TEXT,
  lesson_type     TEXT CHECK (lesson_type IN ('vocabulary','dialogue','grammar','pronunciation','listening','quiz')),
  level           TEXT NOT NULL CHECK (level IN ('A1','A2','B1','B2')),
  order_index     INTEGER NOT NULL,
  icon            TEXT DEFAULT '📖',
  xp_reward       INTEGER DEFAULT 10,
  duration_minutes INTEGER DEFAULT 10,
  audio_url       TEXT,
  is_premium      BOOLEAN DEFAULT false,
  is_active       BOOLEAN DEFAULT true,
  content         JSONB NOT NULL DEFAULT '{}',
  -- content structure:
  -- { vocabulary: [{fr, pt, audio_url, example_fr, example_pt}],
  --   dialogue: [{speaker, text_fr, text_pt, audio_url}],
  --   grammar_rule: {title_pt, explanation_pt, examples: [{fr, pt}]},
  --   cultural_note: {text_pt} }
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- EXERCISES
-- ============================================================
CREATE TABLE public.exercises (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  lesson_id       UUID REFERENCES public.lessons(id) ON DELETE CASCADE,
  exercise_type   TEXT NOT NULL CHECK (exercise_type IN (
    'multiple_choice','fill_blank','drag_drop',
    'audio_listen','audio_repeat','translation',
    'matching','true_false','sentence_order'
  )),
  question        TEXT NOT NULL,
  question_pt     TEXT,
  options         JSONB,  -- [{text, is_correct, feedback_pt}]
  correct_answer  TEXT,
  hint_pt         TEXT,
  audio_url       TEXT,
  image_url       TEXT,
  xp_reward       INTEGER DEFAULT 5,
  order_index     INTEGER NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- USER PROGRESS
-- ============================================================
CREATE TABLE public.user_progress (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id         UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  lesson_id       UUID REFERENCES public.lessons(id) ON DELETE CASCADE,
  status          TEXT DEFAULT 'not_started' CHECK (status IN ('not_started','in_progress','completed')),
  score_percent   INTEGER DEFAULT 0,
  xp_earned       INTEGER DEFAULT 0,
  attempts        INTEGER DEFAULT 0,
  time_spent_sec  INTEGER DEFAULT 0,
  completed_at    TIMESTAMPTZ,
  last_accessed_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, lesson_id)
);

-- ============================================================
-- EXERCISE ATTEMPTS
-- ============================================================
CREATE TABLE public.exercise_attempts (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id         UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  exercise_id     UUID REFERENCES public.exercises(id) ON DELETE CASCADE,
  user_answer     TEXT,
  is_correct      BOOLEAN,
  time_taken_ms   INTEGER,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- AI CHAT SESSIONS
-- ============================================================
CREATE TABLE public.chat_sessions (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id         UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  title           TEXT DEFAULT 'Nova conversa',
  message_count   INTEGER DEFAULT 0,
  tokens_used     INTEGER DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.chat_messages (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  session_id      UUID REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
  role            TEXT NOT NULL CHECK (role IN ('user','assistant','system')),
  content         TEXT NOT NULL,
  corrections     JSONB,  -- [{original, corrected, explanation_pt, rule}]
  tokens          INTEGER DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- PRONUNCIATION SCORES
-- ============================================================
CREATE TABLE public.pronunciation_scores (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id         UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  lesson_id       UUID REFERENCES public.lessons(id),
  target_text     TEXT NOT NULL,
  user_audio_url  TEXT,
  score           NUMERIC(5,2),  -- 0 a 100
  phoneme_scores  JSONB,  -- [{phoneme, score, correct_ipa, user_ipa}]
  feedback_pt     TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ACHIEVEMENTS / BADGES
-- ============================================================
CREATE TABLE public.achievements (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  slug            TEXT UNIQUE NOT NULL,
  title_pt        TEXT NOT NULL,
  description_pt  TEXT,
  icon            TEXT DEFAULT '🏅',
  category        TEXT CHECK (category IN ('streak','lessons','pronunciation','chat','special')),
  condition_type  TEXT,  -- 'streak_days', 'lessons_completed', 'xp_total', etc.
  condition_value INTEGER,
  xp_bonus        INTEGER DEFAULT 0,
  is_rare         BOOLEAN DEFAULT false
);

CREATE TABLE public.user_achievements (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id         UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  achievement_id  UUID REFERENCES public.achievements(id),
  earned_at       TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);

-- ============================================================
-- SUBSCRIPTIONS (Stripe)
-- ============================================================
CREATE TABLE public.subscriptions (
  id                  UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id             UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  stripe_sub_id       TEXT UNIQUE,
  stripe_price_id     TEXT,
  plan                TEXT CHECK (plan IN ('free','premium','business')),
  status              TEXT CHECK (status IN ('active','canceled','past_due','trialing')),
  current_period_start TIMESTAMPTZ,
  current_period_end  TIMESTAMPTZ,
  cancel_at_period_end BOOLEAN DEFAULT false,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- BLOG POSTS
-- ============================================================
CREATE TABLE public.blog_posts (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  slug            TEXT UNIQUE NOT NULL,
  title           TEXT NOT NULL,
  excerpt         TEXT,
  content         TEXT NOT NULL,  -- Markdown
  cover_image_url TEXT,
  category        TEXT CHECK (category IN (
    'aprender-frances','frances-quebec','tef-tcf',
    'gramatica','pronuncia','erros-frequentes','dicas'
  )),
  tags            TEXT[] DEFAULT '{}',
  author_id       UUID REFERENCES public.profiles(id),
  is_published    BOOLEAN DEFAULT false,
  seo_title       TEXT,
  seo_description TEXT,
  reading_time_min INTEGER DEFAULT 5,
  views           INTEGER DEFAULT 0,
  published_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

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
-- INDEXES
-- ============================================================
CREATE INDEX idx_lessons_module ON public.lessons(module_id);
CREATE INDEX idx_lessons_level ON public.lessons(level);
CREATE INDEX idx_exercises_lesson ON public.exercises(lesson_id);
CREATE INDEX idx_progress_user ON public.user_progress(user_id);
CREATE INDEX idx_progress_lesson ON public.user_progress(lesson_id);
CREATE INDEX idx_chat_sessions_user ON public.chat_sessions(user_id);
CREATE INDEX idx_chat_msgs_session ON public.chat_messages(session_id);
CREATE INDEX idx_pronunciation_user ON public.pronunciation_scores(user_id);
CREATE INDEX idx_achievements_user ON public.user_achievements(user_id);
CREATE INDEX idx_blog_slug ON public.blog_posts(slug);
CREATE INDEX idx_blog_category ON public.blog_posts(category);
CREATE INDEX idx_blog_published ON public.blog_posts(is_published, published_at DESC);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pronunciation_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_attempts ENABLE ROW LEVEL SECURITY;

-- Users can only see/edit their own data
CREATE POLICY "profiles_own" ON public.profiles FOR ALL USING (auth.uid() = id);
CREATE POLICY "progress_own" ON public.user_progress FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "chat_sessions_own" ON public.chat_sessions FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "chat_messages_own" ON public.chat_messages FOR ALL
  USING (session_id IN (SELECT id FROM public.chat_sessions WHERE user_id = auth.uid()));
CREATE POLICY "pronunciation_own" ON public.pronunciation_scores FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "achievements_own" ON public.user_achievements FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "attempts_own" ON public.exercise_attempts FOR ALL USING (auth.uid() = user_id);

-- Public read for lessons, modules, exercises, achievements, blog
CREATE POLICY "lessons_public_read" ON public.lessons FOR SELECT USING (is_active = true);
CREATE POLICY "modules_public_read" ON public.modules FOR SELECT USING (is_active = true);
CREATE POLICY "exercises_public_read" ON public.exercises FOR SELECT USING (true);
CREATE POLICY "achievements_public_read" ON public.achievements FOR SELECT USING (true);
CREATE POLICY "blog_public_read" ON public.blog_posts FOR SELECT USING (is_published = true);

-- ============================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================

-- Auto-create profile after signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Update XP and streak
CREATE OR REPLACE FUNCTION public.award_xp(p_user_id UUID, p_xp INTEGER)
RETURNS VOID AS $$
BEGIN
  UPDATE public.profiles
  SET
    xp_total = xp_total + p_xp,
    xp_this_week = xp_this_week + p_xp,
    updated_at = NOW()
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update streak on daily activity
CREATE OR REPLACE FUNCTION public.update_streak(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  v_last_date DATE;
  v_today DATE := CURRENT_DATE;
  v_current INTEGER;
BEGIN
  SELECT streak_last_date, streak_current INTO v_last_date, v_current
  FROM public.profiles WHERE id = p_user_id;

  IF v_last_date = v_today THEN
    RETURN; -- Already updated today
  ELSIF v_last_date = v_today - 1 THEN
    UPDATE public.profiles
    SET streak_current = streak_current + 1,
        streak_best = GREATEST(streak_best, streak_current + 1),
        streak_last_date = v_today
    WHERE id = p_user_id;
  ELSE
    UPDATE public.profiles
    SET streak_current = 1,
        streak_last_date = v_today
    WHERE id = p_user_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Reset weekly XP (run via cron)
CREATE OR REPLACE FUNCTION public.reset_weekly_xp()
RETURNS VOID AS $$
BEGIN
  UPDATE public.profiles SET xp_this_week = 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- SEED DATA — ACHIEVEMENTS
-- ============================================================
INSERT INTO public.achievements (slug, title_pt, description_pt, icon, category, condition_type, condition_value, xp_bonus) VALUES
('first_lesson', 'Primeira Lição!', 'Completou sua primeira lição de francês', '🎓', 'lessons', 'lessons_completed', 1, 50),
('streak_7', 'Semana Perfeita', '7 dias seguidos estudando', '🔥', 'streak', 'streak_days', 7, 100),
('streak_30', 'Mês Dedicado', '30 dias de streak', '🏆', 'streak', 'streak_days', 30, 300),
('streak_100', 'Centurião', '100 dias de streak consecutivos!', '👑', 'streak', 'streak_days', 100, 1000),
('xp_1000', 'Mil XP!', 'Acumulou 1.000 pontos de experiência', '⚡', 'lessons', 'xp_total', 1000, 100),
('pronunciation_90', 'Fonética Perfeita', 'Score de pronúncia acima de 90%', '🎙️', 'pronunciation', 'pronunciation_score', 90, 150),
('chat_100', 'Conversador Ativo', '100 mensagens trocadas com a Prof. Claire', '💬', 'chat', 'chat_messages', 100, 200),
('level_a2', 'Niveau A2!', 'Completou todos os módulos A1', '📊', 'lessons', 'level_completed', 1, 500),
('level_b1', 'Niveau B1!', 'Completou todos os módulos A2', '📊', 'lessons', 'level_completed', 2, 800),
('tef_ready', 'Pronto para o TEF', 'Completou o módulo de preparação TEF', '🇨🇦', 'special', 'module_completed', 1, 1000);

-- ============================================================
-- SEED DATA — MODULES A1
-- ============================================================
INSERT INTO public.modules (level, title, title_pt, description, description_pt, icon, order_index) VALUES
('A1', 'Les Salutations', 'Saudações', 'Greetings and basic expressions', 'Saudações e expressões básicas do cotidiano', '👋', 1),
('A1', 'La Famille', 'Família', 'Family members and relationships', 'Membros da família e relacionamentos', '👨‍👩‍👧‍👦', 2),
('A1', 'Les Couleurs et les Nombres', 'Cores e Números', 'Colors, numbers and basic counting', 'Cores, números e contagem básica', '🎨', 3),
('A1', 'La Maison', 'A Casa', 'Parts of the house and furniture', 'Cômodos da casa e móveis', '🏠', 4),
('A1', 'La Nourriture', 'Comida', 'Food, drinks and ordering', 'Alimentos, bebidas e como pedir', '🍽️', 5),
('A1', 'Les Transports', 'Transportes', 'Transportation and directions', 'Meios de transporte e direções', '🚌', 6),
('A1', 'Le Shopping', 'Compras', 'Shopping, prices and money', 'Fazer compras, preços e dinheiro', '🛒', 7),
('A1', 'Le Corps Humain', 'Corpo Humano', 'Body parts and health basics', 'Partes do corpo e saúde básica', '🧍', 8),
('A1', 'Les Animaux', 'Animais', 'Animals and nature', 'Animais e natureza', '🐾', 9),
('A1', 'La Météo', 'Tempo e Clima', 'Weather and seasons', 'Clima e estações do ano', '🌤️', 10);

-- ============================================================
-- SEED DATA — 20 LESSONS A1 (Module 1 example)
-- ============================================================
WITH m AS (SELECT id FROM public.modules WHERE level='A1' AND order_index=1 LIMIT 1)
INSERT INTO public.lessons (module_id, title, title_pt, lesson_type, level, order_index, xp_reward, content) VALUES
(
  (SELECT id FROM m),
  'Bonjour et Au Revoir',
  'Olá e Tchau',
  'vocabulary',
  'A1',
  1,
  15,
  '{
    "vocabulary": [
      {"fr":"Bonjour","pt":"Bom dia / Olá","example_fr":"Bonjour, je m'\''appelle Marie.","example_pt":"Bom dia, meu nome é Marie."},
      {"fr":"Bonsoir","pt":"Boa tarde / Boa noite","example_fr":"Bonsoir, comment ça va?","example_pt":"Boa noite, como vai?"},
      {"fr":"Au revoir","pt":"Tchau / Até logo","example_fr":"Au revoir, à demain!","example_pt":"Tchau, até amanhã!"},
      {"fr":"Merci","pt":"Obrigado(a)","example_fr":"Merci beaucoup!","example_pt":"Muito obrigado!"},
      {"fr":"S'\''il vous plaît","pt":"Por favor (formal)","example_fr":"Une baguette, s'\''il vous plaît.","example_pt":"Uma baguete, por favor."},
      {"fr":"Excusez-moi","pt":"Com licença / Desculpe","example_fr":"Excusez-moi, où est la gare?","example_pt":"Com licença, onde fica a estação?"}
    ],
    "cultural_note": {"text_pt": "Na França, é muito importante cumprimentar ao entrar em lojas, restaurantes e elevadores. Dizer '\''Bonjour'\'' ao chegar é considerado educação básica!"}
  }'
),
(
  (SELECT id FROM m),
  'Se Présenter',
  'Se Apresentar',
  'dialogue',
  'A1',
  2,
  20,
  '{
    "dialogue": [
      {"speaker":"A","text_fr":"Bonjour! Je m'\''appelle Pierre. Et vous?","text_pt":"Olá! Meu nome é Pierre. E você?"},
      {"speaker":"B","text_fr":"Bonjour Pierre! Je m'\''appelle Ana. Je suis brésilienne.","text_pt":"Olá Pierre! Meu nome é Ana. Sou brasileira."},
      {"speaker":"A","text_fr":"Enchantée Ana! Vous habitez à Paris?","text_pt":"Prazer Ana! Você mora em Paris?"},
      {"speaker":"B","text_fr":"Non, j'\''habite à São Paulo. Je suis en vacances!","text_pt":"Não, moro em São Paulo. Estou de férias!"},
      {"speaker":"A","text_fr":"Super! Bienvenue à Paris!","text_pt":"Ótimo! Bem-vinda a Paris!"}
    ],
    "grammar_rule": {
      "title_pt": "Verbos ser/estar e morar",
      "explanation_pt": "Être (ser/estar): je suis, tu es, il/elle est. Habiter (morar): j'\''habite, tu habites, il/elle habite.",
      "examples": [
        {"fr":"Je suis étudiant.","pt":"Eu sou estudante."},
        {"fr":"Elle est française.","pt":"Ela é francesa."},
        {"fr":"Nous habitons au Brésil.","pt":"Nós moramos no Brasil."}
      ]
    }
  }'
);

COMMENT ON TABLE public.profiles IS 'Perfis de usuários da plataforma FrançaisExpress';
COMMENT ON TABLE public.lessons IS 'Lições organizadas por módulo e nível (A1-B2)';
COMMENT ON TABLE public.exercises IS 'Exercícios interativos vinculados às lições';
COMMENT ON TABLE public.user_progress IS 'Progresso do usuário em cada lição';
COMMENT ON TABLE public.chat_sessions IS 'Sessões de chat com a Prof. Claire (IA)';
COMMENT ON TABLE public.pronunciation_scores IS 'Scores de pronúncia analisados por IA';
COMMENT ON TABLE public.achievements IS 'Sistema de badges e conquistas';
