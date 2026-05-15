# FrançaisExpress — Documentação Técnica Completa

## Stack Tecnológico

### Frontend
- **Next.js 14** (App Router, SSR/SSG para SEO)
- **React 18** + TypeScript
- **TailwindCSS** + design tokens customizados
- **Framer Motion** para animações
- **Zustand** para state management
- **React Hook Form** + Zod para formulários
- **React Query** para server state

### Backend / Infrastructure
- **Supabase** (PostgreSQL + Auth + Storage + Realtime)
- **Supabase Edge Functions** (Deno) para lógica de backend
- **Stripe** para pagamentos e assinaturas
- **Upstash Redis** para rate limiting e cache

### IA & Audio
- **OpenAI GPT-4o** para Prof. Claire (chat IA)
- **OpenAI Whisper** para Speech-to-Text (pronúncia)
- **ElevenLabs** para TTS (voz da Prof. Claire)
- **Azure AI Speech** como fallback para análise fonética

### DevOps
- **Vercel** para deploy do frontend
- **GitHub Actions** para CI/CD
- **Sentry** para error tracking
- **PostHog** para analytics
- **Resend** para e-mails transacionais

---

## Estrutura de Pastas

```
francaisexpress/
├── apps/
│   └── web/                          # Next.js App
│       ├── app/
│       │   ├── (auth)/
│       │   │   ├── login/page.tsx
│       │   │   ├── register/page.tsx
│       │   │   └── forgot-password/page.tsx
│       │   ├── (dashboard)/
│       │   │   ├── dashboard/page.tsx
│       │   │   ├── courses/
│       │   │   │   ├── page.tsx          # Lista de cursos
│       │   │   │   └── [level]/page.tsx  # A1/A2/B1/B2
│       │   │   ├── lessons/
│       │   │   │   └── [lessonId]/page.tsx
│       │   │   ├── ai-chat/page.tsx
│       │   │   ├── pronunciation/page.tsx
│       │   │   ├── achievements/page.tsx
│       │   │   ├── leaderboard/page.tsx
│       │   │   ├── profile/page.tsx
│       │   │   └── settings/page.tsx
│       │   ├── (marketing)/
│       │   │   ├── page.tsx              # Landing page
│       │   │   ├── pricing/page.tsx
│       │   │   └── about/page.tsx
│       │   ├── blog/
│       │   │   ├── page.tsx              # Lista de artigos
│       │   │   └── [slug]/page.tsx       # Artigo individual
│       │   ├── admin/
│       │   │   ├── page.tsx
│       │   │   ├── users/page.tsx
│       │   │   ├── lessons/page.tsx
│       │   │   └── analytics/page.tsx
│       │   ├── api/
│       │   │   ├── ai/chat/route.ts
│       │   │   ├── ai/pronunciation/route.ts
│       │   │   ├── stripe/webhook/route.ts
│       │   │   ├── stripe/checkout/route.ts
│       │   │   └── stripe/portal/route.ts
│       │   ├── layout.tsx
│       │   └── globals.css
│       ├── components/
│       │   ├── ui/                       # Atomic components
│       │   │   ├── Button.tsx
│       │   │   ├── Input.tsx
│       │   │   ├── Modal.tsx
│       │   │   ├── Badge.tsx
│       │   │   ├── Progress.tsx
│       │   │   └── Avatar.tsx
│       │   ├── layout/
│       │   │   ├── Navbar.tsx
│       │   │   ├── Sidebar.tsx
│       │   │   └── Footer.tsx
│       │   ├── dashboard/
│       │   │   ├── WelcomeCard.tsx
│       │   │   ├── StatsGrid.tsx
│       │   │   ├── LessonCard.tsx
│       │   │   └── StreakDisplay.tsx
│       │   ├── lessons/
│       │   │   ├── ExerciseMultipleChoice.tsx
│       │   │   ├── ExerciseFillBlank.tsx
│       │   │   ├── ExerciseDragDrop.tsx
│       │   │   ├── ExerciseAudio.tsx
│       │   │   ├── VocabularyCard.tsx
│       │   │   └── DialoguePlayer.tsx
│       │   ├── ai/
│       │   │   ├── ChatWindow.tsx
│       │   │   ├── ChatMessage.tsx
│       │   │   └── CorrectionBubble.tsx
│       │   └── pronunciation/
│       │       ├── RecordButton.tsx
│       │       ├── PhonemeScore.tsx
│       │       └── WaveformDisplay.tsx
│       ├── lib/
│       │   ├── supabase/
│       │   │   ├── client.ts
│       │   │   ├── server.ts
│       │   │   └── middleware.ts
│       │   ├── openai.ts
│       │   ├── elevenlabs.ts
│       │   ├── stripe.ts
│       │   └── utils.ts
│       ├── hooks/
│       │   ├── useAuth.ts
│       │   ├── useProgress.ts
│       │   ├── useStreak.ts
│       │   ├── useXP.ts
│       │   └── useChat.ts
│       ├── stores/
│       │   ├── authStore.ts
│       │   ├── lessonStore.ts
│       │   └── gamificationStore.ts
│       ├── types/
│       │   ├── database.types.ts  # Auto-gerado do Supabase
│       │   ├── lesson.types.ts
│       │   └── user.types.ts
│       ├── middleware.ts           # Auth middleware
│       ├── next.config.js
│       ├── tailwind.config.ts
│       └── package.json
└── sql/
    └── schema.sql
```

---

## API Routes Principais

### POST /api/ai/chat
```typescript
// Chat com Prof. Claire
// Body: { message, sessionId, userLevel }
// Headers: Authorization Bearer token

const systemPrompt = `Tu es Claire, professeure de français IA pour brésiliens.
Niveau de l'utilisateur: ${userLevel}
Règles:
1. Toujours corriger les erreurs grammaticales gentiment
2. Expliquer les corrections en portugais brésilien
3. Adapter le vocabulaire au niveau
4. Répondre principalement en français
5. Être encourageante et positive
Format de correction: {"original":"...", "corrected":"...", "explanation_pt":"..."}`;
```

### POST /api/ai/pronunciation
```typescript
// Análise de pronúncia
// Body: FormData com audioBlob + targetText
// Retorna: { score, phonemeScores, feedbackPt }
```

### POST /api/stripe/checkout
```typescript
// Criar sessão de pagamento
// Body: { priceId, successUrl, cancelUrl }
// Retorna: { checkoutUrl }
```

---

## Variáveis de Ambiente

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=

# OpenAI
OPENAI_API_KEY=

# ElevenLabs
ELEVENLABS_API_KEY=
ELEVENLABS_VOICE_ID=  # Claire voice

# Stripe
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=
STRIPE_PRICE_PREMIUM_MONTHLY=
STRIPE_PRICE_PREMIUM_YEARLY=
STRIPE_PRICE_BUSINESS=

# App
NEXT_PUBLIC_APP_URL=https://francaisexpress.com.br
JWT_SECRET=
```

---

## Sistema de Gamificação

### XP por Atividade
| Atividade | XP |
|-----------|-----|
| Completar exercício | +5 XP |
| Completar lição | +10-20 XP |
| Score de pronúncia >90% | +15 XP |
| Streak bônus (7 dias) | +50 XP |
| Streak bônus (30 dias) | +200 XP |
| Completar módulo | +100 XP |
| Badge especial | +50-1000 XP |

### Níveis de Usuário
| Nível | XP Necessário |
|-------|--------------|
| Novice | 0 |
| Débutant | 500 |
| Élémentaire | 1.500 |
| Intermédiaire | 5.000 |
| Avancé | 15.000 |
| Expert | 30.000 |

---

## Conteúdo A1 — 20 Lições

| # | Título FR | Título PT | Tipo |
|---|-----------|-----------|------|
| 1 | Bonjour et Au Revoir | Olá e Tchau | Vocabulário |
| 2 | Se Présenter | Se Apresentar | Diálogo |
| 3 | Les Nombres (1-100) | Os Números | Vocabulário |
| 4 | Les Couleurs | As Cores | Vocabulário |
| 5 | La Famille | A Família | Vocabulário |
| 6 | La Maison | A Casa | Vocabulário |
| 7 | Les Aliments | Os Alimentos | Vocabulário |
| 8 | Au Restaurant | No Restaurante | Diálogo |
| 9 | Les Transports | Os Transportes | Vocabulário |
| 10 | La Ville | A Cidade | Vocabulário |
| 11 | Les Jours et les Mois | Dias e Meses | Vocabulário |
| 12 | L'heure | As Horas | Gramática |
| 13 | Le Corps Humain | O Corpo Humano | Vocabulário |
| 14 | Les Vêtements | As Roupas | Vocabulário |
| 15 | Au Marché | No Mercado | Diálogo |
| 16 | Les Animaux | Os Animais | Vocabulário |
| 17 | La Météo | O Clima | Vocabulário |
| 18 | Les Loisirs | O Lazer | Vocabulário |
| 19 | À l'hôtel | No Hotel | Diálogo |
| 20 | Révision A1 | Revisão A1 | Quiz |

---

## SEO Strategy

### Páginas Indexáveis
- `/` — Landing page
- `/blog/[slug]` — Artigos otimizados
- `/courses` — Lista de cursos
- `/sitemap.xml` — Sitemap automático
- `/robots.txt`

### Schema.org
- Course schema para cada módulo
- Article schema para blog
- Organization schema
- FAQPage schema

### Keywords Target
- "aprender francês online"
- "curso francês para brasileiros"
- "TEF Canada preparação"
- "francês Quebec"
- "professora francês IA"
- "pronúncia francesa brasileiros"

---

## Segurança

1. **Autenticação**: Supabase Auth (JWT) + Google OAuth
2. **RLS**: Row Level Security em todas as tabelas sensíveis
3. **Rate Limiting**: Upstash Redis (10 req/min para IA grátis)
4. **CSRF**: Next.js built-in protection
5. **Validação**: Zod schemas em todas as API routes
6. **Sanitização**: DOMPurify para conteúdo de usuário
7. **HTTPS**: Enforced via Vercel
8. **Webhook Signature**: Stripe webhook verification
9. **Env Secrets**: Vercel Environment Variables
10. **CORS**: Configurado no next.config.js

---

## Deploy

```bash
# 1. Clone e instale
git clone https://github.com/seu-usuario/francaisexpress
cd francaisexpress && pnpm install

# 2. Configure variáveis de ambiente
cp .env.example .env.local

# 3. Configure Supabase
supabase init && supabase db push

# 4. Run dev
pnpm dev

# 5. Deploy para Vercel
vercel --prod
```

## Roadmap

### v1.0 (Launch)
- [x] Landing page
- [x] Auth (email + Google)
- [x] 20 lições A1
- [x] Chat IA (Claire)
- [x] Gamificação básica
- [x] Stripe Premium

### v1.5
- [ ] Módulos A2
- [ ] Lab de Pronúncia IA
- [ ] App mobile (React Native)
- [ ] Modo offline (PWA)

### v2.0
- [ ] Módulos B1/B2
- [ ] Francês Québec
- [ ] Simulado TEF/TCF
- [ ] Leaderboard social
- [ ] API para escolas
