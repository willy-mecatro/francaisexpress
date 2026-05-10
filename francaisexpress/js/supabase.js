// ============================================================
// FrançaisExpress — Supabase Client
// Fichier: js/supabase.js
// À inclure dans toutes les pages AVANT tout autre script
//
// CONFIGURATION: remplacer les deux valeurs ci-dessous
// par celles trouvées dans:
//   Supabase Dashboard → Settings → API
// ============================================================

const SUPABASE_URL  = 'https://hswdkvuuwoqvcjfhvhyb.supabase.co'
const SUPABASE_ANON = 'sb_publishable_z7p21rI4XJajkmkm3fMETg_3HUCi4P9'

// ── Client Supabase (chargé via CDN) ─────────────────────────
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON)

// ============================================================
// AUTH
// ============================================================

/** Inscription email + mot de passe */
export async function signUp(email, password, fullName) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { full_name: fullName } }
  })
  if (error) throw error
  return data
}

/** Connexion email + mot de passe */
export async function signIn(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password })
  if (error) throw error
  return data
}

/** Connexion Google OAuth */
export async function signInWithGoogle() {
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: { redirectTo: window.location.origin + '/pages/dashboard.html' }
  })
  if (error) throw error
  return data
}

/** Déconnexion */
export async function signOut() {
  await supabase.auth.signOut()
  window.location.href = '../index.html'
}

/** Utilisateur connecté actuellement */
export async function getCurrentUser() {
  const { data: { user } } = await supabase.auth.getUser()
  return user
}

/** Écouter les changements d'état de connexion */
export function onAuthChange(callback) {
  return supabase.auth.onAuthStateChange((_event, session) => {
    callback(session?.user ?? null)
  })
}

/** Rediriger vers login si non connecté */
export async function requireAuth() {
  const user = await getCurrentUser()
  if (!user) {
    window.location.href = '../index.html'
    return null
  }
  return user
}

// ============================================================
// PROFIL UTILISATEUR
// ============================================================

/** Lire le profil complet */
export async function getProfile(userId) {
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .single()
  if (error) throw error
  return data
}

/** Mettre à jour le profil */
export async function updateProfile(userId, updates) {
  const { data, error } = await supabase
    .from('profiles')
    .update({ ...updates, updated_at: new Date().toISOString() })
    .eq('id', userId)
    .select()
    .single()
  if (error) throw error
  return data
}

/** Sauvegarder préférences onboarding */
export async function saveOnboarding(userId, { goal, level, dailyGoalMin }) {
  return updateProfile(userId, {
    goal,
    current_level: level,
    daily_goal_min: dailyGoalMin,
    onboarding_done: true
  })
}

// ============================================================
// MODULES ET LEÇONS
// ============================================================

/** Lire tous les modules d'un niveau */
export async function getModules(level = null) {
  let query = supabase
    .from('modules')
    .select('*')
    .eq('is_active', true)
    .order('order_index')

  if (level) query = query.eq('level', level)

  const { data, error } = await query
  if (error) throw error
  return data
}

/** Lire les leçons d'un module */
export async function getLessons(moduleId) {
  const { data, error } = await supabase
    .from('lessons')
    .select('*')
    .eq('module_id', moduleId)
    .eq('is_active', true)
    .order('order_index')
  if (error) throw error
  return data
}

/** Lire une leçon avec ses exercices */
export async function getLessonWithExercises(lessonId) {
  const [lessonRes, exercisesRes] = await Promise.all([
    supabase.from('lessons').select('*').eq('id', lessonId).single(),
    supabase.from('exercises').select('*').eq('lesson_id', lessonId).order('order_index')
  ])
  if (lessonRes.error) throw lessonRes.error
  return { lesson: lessonRes.data, exercises: exercisesRes.data || [] }
}

// ============================================================
// PROGRESSION
// ============================================================

/** Lire la progression d'un utilisateur (toutes les leçons) */
export async function getUserProgress(userId) {
  const { data, error } = await supabase
    .from('user_progress')
    .select('*, lessons(title_pt, icon, level)')
    .eq('user_id', userId)
  if (error) throw error
  return data
}

/** Démarrer ou mettre à jour la progression d'une leçon */
export async function upsertProgress(userId, lessonId, updates) {
  const { data, error } = await supabase
    .from('user_progress')
    .upsert({
      user_id: userId,
      lesson_id: lessonId,
      last_accessed_at: new Date().toISOString(),
      ...updates
    }, { onConflict: 'user_id,lesson_id' })
    .select()
    .single()
  if (error) throw error
  return data
}

/** Compléter une leçon et attribuer XP */
export async function completeLesson(userId, lessonId, scorePercent, timeSpentSec) {
  const { data: lesson } = await supabase
    .from('lessons')
    .select('xp_reward')
    .eq('id', lessonId)
    .single()

  const xp = Math.round((lesson?.xp_reward || 10) * (scorePercent / 100))

  await Promise.all([
    upsertProgress(userId, lessonId, {
      status: 'completed',
      score_percent: scorePercent,
      xp_earned: xp,
      time_spent_sec: timeSpentSec,
      completed_at: new Date().toISOString()
    }),
    supabase.rpc('award_xp', { p_user_id: userId, p_xp: xp }),
    supabase.rpc('update_streak', { p_user_id: userId })
  ])

  return { xp }
}

/** Enregistrer une tentative d'exercice */
export async function saveExerciseAttempt(userId, exerciseId, userAnswer, isCorrect, timeTakenMs) {
  const { error } = await supabase
    .from('exercise_attempts')
    .insert({ user_id: userId, exercise_id: exerciseId, user_answer: userAnswer, is_correct: isCorrect, time_taken_ms: timeTakenMs })
  if (error) throw error
}

// ============================================================
// CHAT IA
// ============================================================

/** Créer une nouvelle session de chat */
export async function createChatSession(userId, title = 'Nova conversa') {
  const { data, error } = await supabase
    .from('chat_sessions')
    .insert({ user_id: userId, title })
    .select()
    .single()
  if (error) throw error
  return data
}

/** Lire les sessions de chat d'un utilisateur */
export async function getChatSessions(userId) {
  const { data, error } = await supabase
    .from('chat_sessions')
    .select('*')
    .eq('user_id', userId)
    .order('updated_at', { ascending: false })
    .limit(20)
  if (error) throw error
  return data
}

/** Lire les messages d'une session */
export async function getChatMessages(sessionId) {
  const { data, error } = await supabase
    .from('chat_messages')
    .select('*')
    .eq('session_id', sessionId)
    .order('created_at')
  if (error) throw error
  return data
}

/** Sauvegarder un message */
export async function saveChatMessage(sessionId, role, content, corrections = null) {
  const { data, error } = await supabase
    .from('chat_messages')
    .insert({ session_id: sessionId, role, content, corrections })
    .select()
    .single()
  if (error) throw error

  // Mettre à jour le compteur de messages
  await supabase
    .from('chat_sessions')
    .update({ message_count: supabase.rpc('increment'), updated_at: new Date().toISOString() })
    .eq('id', sessionId)

  return data
}

// ============================================================
// PRONONCIATION
// ============================================================

/** Sauvegarder un score de prononciation */
export async function savePronunciationScore(userId, targetText, score, phonemeScores, feedbackPt, lessonId = null) {
  const { data, error } = await supabase
    .from('pronunciation_scores')
    .insert({
      user_id: userId,
      lesson_id: lessonId,
      target_text: targetText,
      score,
      phoneme_scores: phonemeScores,
      feedback_pt: feedbackPt
    })
    .select()
    .single()
  if (error) throw error

  // XP selon score
  const xp = score >= 90 ? 15 : score >= 70 ? 8 : 3
  await supabase.rpc('award_xp', { p_user_id: userId, p_xp: xp })

  return { data, xp }
}

/** Historique de prononciation */
export async function getPronunciationHistory(userId, limit = 10) {
  const { data, error } = await supabase
    .from('pronunciation_scores')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(limit)
  if (error) throw error
  return data
}

// ============================================================
// ACHIEVEMENTS
// ============================================================

/** Badges d'un utilisateur */
export async function getUserAchievements(userId) {
  const { data, error } = await supabase
    .from('user_achievements')
    .select('*, achievements(*)')
    .eq('user_id', userId)
  if (error) throw error
  return data
}

/** Tous les badges disponibles */
export async function getAllAchievements() {
  const { data, error } = await supabase
    .from('achievements')
    .select('*')
    .order('xp_bonus')
  if (error) throw error
  return data
}

/** Débloquer un badge */
export async function unlockAchievement(userId, achievementSlug) {
  const { data: achievement } = await supabase
    .from('achievements')
    .select('id, xp_bonus, title_pt')
    .eq('slug', achievementSlug)
    .single()

  if (!achievement) return null

  const { error } = await supabase
    .from('user_achievements')
    .insert({ user_id: userId, achievement_id: achievement.id })

  if (!error && achievement.xp_bonus > 0) {
    await supabase.rpc('award_xp', { p_user_id: userId, p_xp: achievement.xp_bonus })
  }

  return achievement
}

// ============================================================
// LEADERBOARD
// ============================================================

/** Classement hebdomadaire (top 20) */
export async function getLeaderboard() {
  const { data, error } = await supabase
    .from('leaderboard_weekly')
    .select('*')
    .limit(20)
  if (error) throw error
  return data
}

// ============================================================
// BLOG
// ============================================================

/** Articles publiés */
export async function getBlogPosts(category = null, limit = 10) {
  let query = supabase
    .from('blog_posts')
    .select('id, slug, title, excerpt, category, reading_time_min, views, published_at')
    .eq('is_published', true)
    .order('published_at', { ascending: false })
    .limit(limit)

  if (category) query = query.eq('category', category)

  const { data, error } = await query
  if (error) throw error
  return data
}

/** Un article par slug */
export async function getBlogPost(slug) {
  const { data, error } = await supabase
    .from('blog_posts')
    .select('*')
    .eq('slug', slug)
    .eq('is_published', true)
    .single()
  if (error) throw error

  // Incrémenter les vues
  await supabase.from('blog_posts').update({ views: data.views + 1 }).eq('id', data.id)

  return data
}
