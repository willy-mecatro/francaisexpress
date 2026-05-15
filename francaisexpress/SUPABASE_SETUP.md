# ⚡ FrançaisExpress — Connexion Supabase en 5 étapes

## Étape 1 — Créer le projet Supabase
1. Aller sur **https://supabase.com** → Sign up (gratuit)
2. Cliquer **"New project"**
3. Choisir un nom : `francaisexpress`
4. Choisir une région : **South America (São Paulo)** pour les utilisateurs brésiliens
5. Créer un mot de passe fort pour la base de données
6. Attendre ~2 minutes que le projet se configure

---

## Étape 2 — Créer les 13 tables

1. Dans le dashboard Supabase → **SQL Editor** → **New query**
2. Copier-coller le contenu de **`sql/01_schema.sql`**
3. Cliquer **Run** (ou Ctrl+Enter)
4. Attendre le message `Success. No rows returned`

Ensuite faire pareil avec **`sql/02_seed.sql`** pour les données initiales.

---

## Étape 3 — Activer Google OAuth (optionnel)

1. Supabase → **Authentication** → **Providers** → **Google**
2. Activer le toggle
3. Aller sur **console.cloud.google.com** → Créer des credentials OAuth 2.0
4. Copier le Client ID et Client Secret dans Supabase
5. Ajouter l'URL de callback : `https://VOTRE_ID.supabase.co/auth/v1/callback`

---

## Étape 4 — Récupérer vos clés API

1. Supabase → **Settings** → **API**
2. Copier :
   - **Project URL** → `https://xxxx.supabase.co`
   - **anon public** → clé longue commençant par `eyJ...`

3. Ouvrir **`js/supabase.js`** et remplacer :
```js
const SUPABASE_URL  = 'https://VOTRE_PROJECT_ID.supabase.co'
const SUPABASE_ANON = 'VOTRE_ANON_KEY'
```

---

## Étape 5 — Ajouter le client dans vos pages

Ajouter cette ligne dans le `<head>` de chaque page HTML qui utilise Supabase :

```html
<script type="module">
  import { supabase, getCurrentUser, getProfile } from '../js/supabase.js'

  // Exemple : charger le profil au chargement de la page
  const user = await getCurrentUser()
  if (user) {
    const profile = await getProfile(user.id)
    document.getElementById('user-name').textContent = profile.full_name
    document.getElementById('user-xp').textContent = profile.xp_total
  }
</script>
```

---

## Tables créées

| # | Table | Description |
|---|---|---|
| 1 | `profiles` | Profil utilisateur (XP, streak, niveau, plan) |
| 2 | `modules` | Modules de cours (A1 à B2) |
| 3 | `lessons` | Leçons dans chaque module |
| 4 | `exercises` | Exercices interactifs |
| 5 | `user_progress` | Progression par leçon |
| 6 | `exercise_attempts` | Historique des tentatives |
| 7 | `chat_sessions` | Sessions avec Prof. Claire |
| 8 | `chat_messages` | Messages de chaque session |
| 9 | `pronunciation_scores` | Scores du labo de prononciation |
| 10 | `achievements` | Définition des badges |
| 11 | `user_achievements` | Badges débloqués |
| 12 | `subscriptions` | Abonnements Stripe |
| 13 | `blog_posts` | Articles du blog |

+ 1 view : `leaderboard_weekly`
+ 3 fonctions : `award_xp`, `update_streak`, `reset_weekly_xp`

---

## Fonctions disponibles dans `js/supabase.js`

### Auth
- `signUp(email, password, fullName)`
- `signIn(email, password)`
- `signInWithGoogle()`
- `signOut()`
- `getCurrentUser()`
- `requireAuth()` — redirige vers login si non connecté

### Profil
- `getProfile(userId)`
- `updateProfile(userId, updates)`
- `saveOnboarding(userId, { goal, level, dailyGoalMin })`

### Leçons
- `getModules(level?)`
- `getLessons(moduleId)`
- `getLessonWithExercises(lessonId)`

### Progression
- `getUserProgress(userId)`
- `upsertProgress(userId, lessonId, updates)`
- `completeLesson(userId, lessonId, scorePercent, timeSpentSec)`
- `saveExerciseAttempt(...)`

### Chat IA
- `createChatSession(userId, title?)`
- `getChatSessions(userId)`
- `getChatMessages(sessionId)`
- `saveChatMessage(sessionId, role, content, corrections?)`

### Prononciation
- `savePronunciationScore(...)`
- `getPronunciationHistory(userId)`

### Achievements
- `getUserAchievements(userId)`
- `getAllAchievements()`
- `unlockAchievement(userId, slug)`

### Leaderboard
- `getLeaderboard()`

### Blog
- `getBlogPosts(category?, limit?)`
- `getBlogPost(slug)`
