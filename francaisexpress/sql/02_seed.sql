-- ============================================================
-- FrançaisExpress — SEED DATA
-- Exécuter APRÈS 01_schema.sql
-- ============================================================

-- ============================================================
-- ACHIEVEMENTS (10 badges)
-- ============================================================
INSERT INTO public.achievements
  (slug, title_pt, description_pt, icon, category, condition_type, condition_value, xp_bonus, is_rare)
VALUES
  ('first_lesson',     'Primeira Lição!',      'Completou sua primeira lição de francês',        '🎓', 'lessons',       'lessons_completed',   1,   50,  false),
  ('streak_7',         'Semana Perfeita',       '7 dias seguidos estudando',                      '🔥', 'streak',        'streak_days',         7,   100, false),
  ('streak_30',        'Mês Dedicado',          '30 dias de streak consecutivos',                 '🏅', 'streak',        'streak_days',         30,  300, false),
  ('streak_100',       'Centurião',             '100 dias de streak — incrível!',                 '👑', 'streak',        'streak_days',         100, 1000,true),
  ('xp_1000',          'Mil XP!',               'Acumulou 1.000 pontos de experiência',           '⚡', 'lessons',       'xp_total',            1000,100, false),
  ('xp_10000',         'Dez Mil XP!',           'Acumulou 10.000 pontos — mestre!',               '💎', 'lessons',       'xp_total',            10000,500,true),
  ('pronunciation_90', 'Fonética Perfeita',     'Score de pronúncia acima de 90%',                '🎤', 'pronunciation', 'pronunciation_score', 90,  150, false),
  ('chat_50',          'Conversador',           '50 mensagens trocadas com a Prof. Claire',       '💬', 'chat',          'chat_messages',       50,  100, false),
  ('level_a2',         'Niveau A2!',            'Completou todos os módulos A1 — parabéns!',      '📊', 'lessons',       'level_completed',     1,   500, false),
  ('tef_ready',        'Pronto para o TEF',     'Completou o módulo de preparação TEF/TCF',       '🇨🇦', 'special',       'module_completed',    1,   1000,true)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================
-- MODULES A1 (10 modules)
-- ============================================================
INSERT INTO public.modules
  (level, title, title_pt, description_pt, icon, order_index, is_premium)
VALUES
  ('A1', 'Les Salutations',          'Saudações',          'Cumprimentos e expressões do dia a dia',         '👋', 1,  false),
  ('A1', 'La Famille',               'Família',            'Membros da família e relacionamentos',           '👨‍👩‍👧', 2,  false),
  ('A1', 'Les Couleurs et Nombres',  'Cores e Números',    'Cores, números e contagem básica',              '🎨', 3,  false),
  ('A1', 'La Maison',                'A Casa',             'Cômodos da casa e móveis',                      '🏠', 4,  false),
  ('A1', 'La Nourriture',            'Comida',             'Alimentos, bebidas e como pedir no restaurante','🍽️', 5,  false),
  ('A1', 'Les Transports',           'Transportes',        'Meios de transporte e direções',                '🚌', 6,  false),
  ('A1', 'Le Shopping',              'Compras',            'Fazer compras, preços e dinheiro',              '🛒', 7,  false),
  ('A1', 'Le Corps et la Santé',     'Corpo e Saúde',      'Partes do corpo, ir ao médico',                 '🏥', 8,  false),
  ('A1', 'Les Animaux',              'Animais',            'Animais domésticos e selvagens',                '🐾', 9,  false),
  ('A1', 'La Météo et les Saisons',  'Clima e Estações',   'Tempo, clima e estações do ano',                '🌤️', 10, false)
ON CONFLICT DO NOTHING;

-- ============================================================
-- MODULES A2 (premium)
-- ============================================================
INSERT INTO public.modules
  (level, title, title_pt, description_pt, icon, order_index, is_premium)
VALUES
  ('A2', 'Au Travail',               'No Trabalho',        'Vocabulário profissional e escritório',          '💼', 1,  true),
  ('A2', 'Les Loisirs',              'Lazer',              'Hobbies, esportes e atividades de fim de semana','🎭', 2,  true),
  ('A2', 'Voyager en France',        'Viajar na França',   'Hotéis, aeroportos e turismo',                  '✈️', 3,  true),
  ('A2', 'La Ville',                 'A Cidade',           'Orientação, lojas e serviços urbanos',           '🏙️', 4,  true),
  ('A2', 'Les Relations Sociales',   'Relações Sociais',   'Amigos, convites e vida social',                '🤝', 5,  true)
ON CONFLICT DO NOTHING;

-- ============================================================
-- MODULES B1 (premium)
-- ============================================================
INSERT INTO public.modules
  (level, title, title_pt, description_pt, icon, order_index, is_premium)
VALUES
  ('B1', 'Le Monde Professionnel',   'Mundo Profissional', 'Reuniões, emails e apresentações em francês',   '📊', 1,  true),
  ('B1', 'Actualités et Médias',     'Notícias e Mídia',   'Ler jornais e discutir eventos atuais',         '📰', 2,  true),
  ('B1', 'Préparation TEF/TCF',      'Prep. TEF/TCF',      'Simulados e estratégias para o exame',          '📋', 3,  true),
  ('B1', 'Français du Québec',       'Francês do Québec',  'Sotaque, expressões e cultura québécoise',      '🍁', 4,  true)
ON CONFLICT DO NOTHING;

-- ============================================================
-- LESSONS (Módulo 1 — Les Salutations — 5 lições)
-- ============================================================
DO $$
DECLARE
  v_module_id UUID;
BEGIN
  SELECT id INTO v_module_id FROM public.modules
  WHERE level = 'A1' AND order_index = 1 LIMIT 1;

  IF v_module_id IS NULL THEN RETURN; END IF;

  INSERT INTO public.lessons
    (module_id, title, title_pt, lesson_type, level, order_index, xp_reward, duration_minutes, content)
  VALUES
  (
    v_module_id,
    'Bonjour et Au Revoir',
    'Olá e Tchau',
    'vocabulary', 'A1', 1, 15, 8,
    '{
      "vocabulary": [
        {"fr":"Bonjour","pt":"Bom dia / Olá","example_fr":"Bonjour, comment vous appelez-vous?","example_pt":"Bom dia, qual é o seu nome?"},
        {"fr":"Bonsoir","pt":"Boa noite","example_fr":"Bonsoir madame!","example_pt":"Boa noite senhora!"},
        {"fr":"Au revoir","pt":"Tchau / Até logo","example_fr":"Au revoir, à bientôt!","example_pt":"Tchau, até logo!"},
        {"fr":"Salut","pt":"Oi (informal)","example_fr":"Salut! Ça va?","example_pt":"Oi! Tudo bem?"},
        {"fr":"Merci","pt":"Obrigado(a)","example_fr":"Merci beaucoup!","example_pt":"Muito obrigado!"},
        {"fr":"De rien","pt":"De nada","example_fr":"Merci! — De rien!","example_pt":"Obrigado! — De nada!"},
        {"fr":"S il vous plaît","pt":"Por favor (formal)","example_fr":"L addition, s il vous plaît.","example_pt":"A conta, por favor."},
        {"fr":"Excusez-moi","pt":"Com licença / Desculpe","example_fr":"Excusez-moi, où est la gare?","example_pt":"Com licença, onde fica a estação?"}
      ],
      "cultural_note": {"text_pt": "Na França, dizer Bonjour ao entrar em qualquer estabelecimento é considerado educação básica. Entrar sem cumprimentar é visto como grosseria!"}
    }'::JSONB
  ),
  (
    v_module_id,
    'Se Présenter',
    'Se Apresentar',
    'dialogue', 'A1', 2, 20, 12,
    '{
      "dialogue": [
        {"speaker":"A","text_fr":"Bonjour! Je m appelle Pierre. Et vous?","text_pt":"Olá! Meu nome é Pierre. E você?"},
        {"speaker":"B","text_fr":"Bonjour Pierre! Je m appelle Ana. Je suis brésilienne.","text_pt":"Olá Pierre! Meu nome é Ana. Sou brasileira."},
        {"speaker":"A","text_fr":"Enchantée Ana! Vous habitez à Paris?","text_pt":"Prazer Ana! Você mora em Paris?"},
        {"speaker":"B","text_fr":"Non, j habite à São Paulo. Je suis en vacances!","text_pt":"Não, moro em São Paulo. Estou de férias!"},
        {"speaker":"A","text_fr":"Super! Bienvenue à Paris!","text_pt":"Ótimo! Bem-vinda a Paris!"}
      ],
      "grammar_rule": {
        "title_pt": "Verbo être (ser/estar) — Presente",
        "explanation_pt": "O verbo être é o mais importante do francês. Aprenda sua conjugação no presente:",
        "examples": [
          {"fr":"Je suis étudiant(e).","pt":"Eu sou estudante."},
          {"fr":"Tu es français(e)?","pt":"Você é francês(a)?"},
          {"fr":"Il/Elle est à Paris.","pt":"Ele/Ela está em Paris."},
          {"fr":"Nous sommes brésiliens.","pt":"Nós somos brasileiros."}
        ]
      }
    }'::JSONB
  ),
  (
    v_module_id,
    'Les Présentations Formelles',
    'Apresentações Formais',
    'grammar', 'A1', 3, 15, 10,
    '{
      "grammar_rule": {
        "title_pt": "Pronomes pessoais e verbo avoir (ter)",
        "explanation_pt": "Em francês, os pronomes pessoais são sempre obrigatórios antes do verbo — ao contrário do português!",
        "examples": [
          {"fr":"J ai vingt-cinq ans.","pt":"Eu tenho vinte e cinco anos."},
          {"fr":"Il a un appartement à Lyon.","pt":"Ele tem um apartamento em Lyon."},
          {"fr":"Nous avons un chien.","pt":"Nós temos um cachorro."},
          {"fr":"Vous avez des enfants?","pt":"Você tem filhos?"}
        ]
      },
      "vocabulary": [
        {"fr":"un homme","pt":"um homem"},
        {"fr":"une femme","pt":"uma mulher"},
        {"fr":"un étudiant","pt":"um estudante"},
        {"fr":"un professeur","pt":"um professor"},
        {"fr":"un médecin","pt":"um médico"},
        {"fr":"un ingénieur","pt":"um engenheiro"}
      ]
    }'::JSONB
  ),
  (
    v_module_id,
    'Les Nationalités',
    'Nacionalidades',
    'vocabulary', 'A1', 4, 15, 8,
    '{
      "vocabulary": [
        {"fr":"brésilien / brésilienne","pt":"brasileiro / brasileira"},
        {"fr":"français / française","pt":"francês / francesa"},
        {"fr":"canadien / canadienne","pt":"canadense"},
        {"fr":"américain / américaine","pt":"americano / americana"},
        {"fr":"portugais / portugaise","pt":"português / portuguesa"},
        {"fr":"espagnol / espagnole","pt":"espanhol / espanhola"},
        {"fr":"italien / italienne","pt":"italiano / italiana"},
        {"fr":"québécois / québécoise","pt":"quebequense"}
      ],
      "cultural_note": {"text_pt": "Em francês, as nacionalidades concordam em gênero: um homem é français, uma mulher é française. Note que no francês escrito, as nacionalidades não têm maiúscula!"}
    }'::JSONB
  ),
  (
    v_module_id,
    'Quiz — Saudações',
    'Quiz — Saudações',
    'quiz', 'A1', 5, 25, 10,
    '{
      "quiz": {
        "description_pt": "Teste tudo que você aprendeu sobre saudações e apresentações!",
        "pass_score": 70
      }
    }'::JSONB
  )
  ON CONFLICT DO NOTHING;

  -- Update lessons count
  UPDATE public.modules SET lessons_count = 5 WHERE id = v_module_id;
END;
$$;

-- ============================================================
-- EXERCISES (lição 1 — Bonjour et Au Revoir)
-- ============================================================
DO $$
DECLARE
  v_lesson_id UUID;
BEGIN
  SELECT id INTO v_lesson_id FROM public.lessons
  WHERE title = 'Bonjour et Au Revoir' LIMIT 1;

  IF v_lesson_id IS NULL THEN RETURN; END IF;

  INSERT INTO public.exercises
    (lesson_id, exercise_type, question, question_pt, options, correct_answer, hint_pt, xp_reward, order_index)
  VALUES
  (
    v_lesson_id,
    'multiple_choice',
    'Comment dit-on "Bom dia" en français?',
    'Como se diz "Bom dia" em francês?',
    '[
      {"text":"Bonsoir","is_correct":false,"feedback_pt":"Bonsoir significa boa noite, não bom dia!"},
      {"text":"Bonjour","is_correct":true,"feedback_pt":"Perfeito! Bonjour = bom dia / olá"},
      {"text":"Au revoir","is_correct":false,"feedback_pt":"Au revoir significa tchau / até logo"},
      {"text":"Salut","is_correct":false,"feedback_pt":"Salut é informal, significa oi"}
    ]'::JSONB,
    'Bonjour', 'É a saudação mais comum do francês', 5, 1
  ),
  (
    v_lesson_id,
    'fill_blank',
    'Complétez: "_____ beaucoup!" (Muito obrigado)',
    'Complete: "_____ beaucoup!" (Muito obrigado)',
    NULL,
    'Merci',
    'Começa com M', 5, 2
  ),
  (
    v_lesson_id,
    'multiple_choice',
    'Quelle expression utilise-t-on pour dire "au revoir" de manière formelle?',
    'Qual expressão usamos para se despedir formalmente?',
    '[
      {"text":"Salut!","is_correct":false,"feedback_pt":"Salut é informal"},
      {"text":"Ciao!","is_correct":false,"feedback_pt":"Ciao é italiano!"},
      {"text":"Au revoir!","is_correct":true,"feedback_pt":"Exato! Au revoir é a despedida formal"},
      {"text":"À plus!","is_correct":false,"feedback_pt":"À plus! é muito informal — significa até mais!"}
    ]'::JSONB,
    'Au revoir!', NULL, 5, 3
  ),
  (
    v_lesson_id,
    'translation',
    'Traduisez en français: "Com licença, onde fica o banheiro?"',
    'Traduza para o francês: "Com licença, onde fica o banheiro?"',
    NULL,
    'Excusez-moi, où sont les toilettes?',
    'Use excusez-moi + où + sont + les toilettes', 10, 4
  ),
  (
    v_lesson_id,
    'true_false',
    '"Salut" est une salutation formelle en français.',
    '"Salut" é uma saudação formal em francês.',
    '[
      {"text":"Vrai (Verdadeiro)","is_correct":false,"feedback_pt":"Falso! Salut é INFORMAL. Use Bonjour no contexto formal"},
      {"text":"Faux (Falso)","is_correct":true,"feedback_pt":"Correto! Salut é informal — use Bonjour com desconhecidos e em contextos profissionais"}
    ]'::JSONB,
    'Faux', NULL, 5, 5
  )
  ON CONFLICT DO NOTHING;
END;
$$;
