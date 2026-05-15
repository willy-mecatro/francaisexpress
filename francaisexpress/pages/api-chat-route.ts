// app/api/ai/chat/route.ts
// FrançaisExpress — Prof. Claire Chat API
// Next.js 14 App Router + OpenAI GPT-4o + Supabase

import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'
import OpenAI from 'openai'
import { z } from 'zod'

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY })

// ============================================================
// Request validation schema
// ============================================================
const RequestSchema = z.object({
  message: z.string().min(1).max(2000),
  sessionId: z.string().uuid().optional(),
  conversationHistory: z.array(z.object({
    role: z.enum(['user', 'assistant']),
    content: z.string()
  })).max(50).default([])
})

// ============================================================
// System prompt — Prof. Claire
// ============================================================
function buildSystemPrompt(userLevel: string, userName: string): string {
  return `Tu es Claire, professeure de français IA spécialisée pour les brésiliens.

PROFIL UTILISATEUR:
- Nom: ${userName}
- Niveau actuel: ${userLevel}
- Langue maternelle: Portugais brésilien

TES RÈGLES ABSOLUES:
1. Réponds TOUJOURS principalement en français, adapté au niveau ${userLevel}
2. Corrige les erreurs grammaticales/orthographiques GENTIMENT et EN PORTUGAIS BRÉSILIEN
3. Explique les règles gramaticales en portugais pour que l'utilisateur comprenne
4. Sois encourageante, positive et patiente — c'est difficile d'apprendre!
5. Si l'utilisateur écrit en portugais, réponds en français avec traduction
6. Adapte ton vocabulaire au niveau:
   - A1: phrases très simples, mots courants uniquement
   - A2: phrases plus complexes, connecteurs basiques
   - B1: variété de structures, expressions idiomatiques simples
   - B2: complexité complète, nuances, littérature

FORMAT DE CORRECTION (JSON inline dans ta réponse):
Quand tu corriges, inclus TOUJOURS ce bloc JSON à la fin:
<correction>{"original":"[texte original]","corrected":"[texte corrigé]","rule_pt":"[regra em português]","encouragement_pt":"[palavra de encorajamento]"}</correction>

PERSONALIDADE:
- Nome: Claire Dubois (française de Lyon, 35 ans)
- Enthousiaste pour la culture brésilienne
- Utilise des emojis avec modération 😊
- Connait la cuisine brésilienne, le carnaval, le football
- Adapte les exemples à la réalité brésilienne (café da manhã, metrô, etc.)

EXEMPLES D'INTERACTIONS:
User: "Je veux mangé une pizza"
Claire: [Corrige 'mangé' → 'manger', explique l'infinitif em português]

User: "Posso pedir para você falar mais devagar?"  
Claire: "Bien sûr! Je vais parler plus lentement 😊 [Tradução: Claro! Vou falar mais devagar]"

NE FAIS JAMAIS:
- Donner la réponse aux exercices directement sans expliquer
- Être condescendant ou frustré
- Utiliser un vocabulaire trop avancé pour le niveau
- Oublier d'expliquer les corrections en portugais`
}

// ============================================================
// Rate limiting check
// ============================================================
async function checkRateLimit(userId: string, isPremium: boolean): Promise<boolean> {
  // In production: use Upstash Redis
  // For free users: 10 messages/day
  // For premium: unlimited
  return true // Simplified for demo
}

// ============================================================
// Extract corrections from AI response
// ============================================================
function extractCorrections(text: string): {cleanText: string, corrections: object[]} {
  const corrections: object[] = []
  let cleanText = text

  const correctionRegex = /<correction>(.*?)<\/correction>/gs
  let match

  while ((match = correctionRegex.exec(text)) !== null) {
    try {
      const correction = JSON.parse(match[1])
      corrections.push(correction)
      cleanText = cleanText.replace(match[0], '')
    } catch (e) {
      // Invalid JSON, skip
    }
  }

  return { cleanText: cleanText.trim(), corrections }
}

// ============================================================
// POST handler
// ============================================================
export async function POST(request: Request) {
  try {
    // 1. Authenticate user
    const supabase = createRouteHandlerClient({ cookies })
    const { data: { session } } = await supabase.auth.getSession()

    if (!session) {
      return NextResponse.json({ error: 'Não autenticado' }, { status: 401 })
    }

    // 2. Get user profile
    const { data: profile } = await supabase
      .from('profiles')
      .select('full_name, current_level, subscription')
      .eq('id', session.user.id)
      .single()

    if (!profile) {
      return NextResponse.json({ error: 'Perfil não encontrado' }, { status: 404 })
    }

    // 3. Validate request
    const body = await request.json()
    const parsed = RequestSchema.safeParse(body)

    if (!parsed.success) {
      return NextResponse.json(
        { error: 'Dados inválidos', details: parsed.error.issues },
        { status: 400 }
      )
    }

    const { message, sessionId, conversationHistory } = parsed.data
    const isPremium = profile.subscription !== 'free'

    // 4. Rate limiting
    const allowed = await checkRateLimit(session.user.id, isPremium)
    if (!allowed) {
      return NextResponse.json(
        { error: 'Limite diário atingido. Faça upgrade para Premium!' },
        { status: 429 }
      )
    }

    // 5. Build messages for OpenAI
    const systemMessage = {
      role: 'system' as const,
      content: buildSystemPrompt(profile.current_level, profile.full_name)
    }

    const messages = [
      systemMessage,
      ...conversationHistory.map(msg => ({
        role: msg.role as 'user' | 'assistant',
        content: msg.content
      })),
      { role: 'user' as const, content: message }
    ]

    // 6. Call OpenAI
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o',
      messages,
      max_tokens: 800,
      temperature: 0.75,
      stream: false
    })

    const rawResponse = completion.choices[0]?.message?.content || ''
    const tokensUsed = completion.usage?.total_tokens || 0

    // 7. Extract corrections from response
    const { cleanText, corrections } = extractCorrections(rawResponse)

    // 8. Save to database
    let activeSessionId = sessionId

    if (!activeSessionId) {
      // Create new session
      const { data: newSession } = await supabase
        .from('chat_sessions')
        .insert({
          user_id: session.user.id,
          title: message.substring(0, 50)
        })
        .select('id')
        .single()

      activeSessionId = newSession?.id
    }

    if (activeSessionId) {
      // Save user message
      await supabase.from('chat_messages').insert({
        session_id: activeSessionId,
        role: 'user',
        content: message,
        tokens: 0
      })

      // Save AI response
      await supabase.from('chat_messages').insert({
        session_id: activeSessionId,
        role: 'assistant',
        content: cleanText,
        corrections: corrections.length > 0 ? corrections : null,
        tokens: tokensUsed
      })

      // Update session
      await supabase.from('chat_sessions').update({
        message_count: (conversationHistory.length + 2),
        tokens_used: tokensUsed,
        updated_at: new Date().toISOString()
      }).eq('id', activeSessionId)
    }

    // 9. Award XP for chat activity (every 5 messages)
    if (conversationHistory.length > 0 && conversationHistory.length % 5 === 0) {
      await supabase.rpc('award_xp', {
        p_user_id: session.user.id,
        p_xp: 5
      })
    }

    // 10. Return response
    return NextResponse.json({
      message: cleanText,
      corrections,
      sessionId: activeSessionId,
      tokensUsed
    })

  } catch (error) {
    console.error('Chat API error:', error)
    return NextResponse.json(
      { error: 'Erro interno. Tente novamente.' },
      { status: 500 }
    )
  }
}

// ============================================================
// GET — Fetch chat history
// ============================================================
export async function GET(request: Request) {
  try {
    const supabase = createRouteHandlerClient({ cookies })
    const { data: { session } } = await supabase.auth.getSession()

    if (!session) {
      return NextResponse.json({ error: 'Não autenticado' }, { status: 401 })
    }

    const { searchParams } = new URL(request.url)
    const sessionId = searchParams.get('sessionId')

    if (sessionId) {
      // Get specific session messages
      const { data: messages } = await supabase
        .from('chat_messages')
        .select('*')
        .eq('session_id', sessionId)
        .order('created_at', { ascending: true })

      return NextResponse.json({ messages })
    } else {
      // Get user's sessions list
      const { data: sessions } = await supabase
        .from('chat_sessions')
        .select('id, title, message_count, created_at, updated_at')
        .eq('user_id', session.user.id)
        .order('updated_at', { ascending: false })
        .limit(20)

      return NextResponse.json({ sessions })
    }
  } catch (error) {
    return NextResponse.json({ error: 'Erro interno' }, { status: 500 })
  }
}

// ============================================================
// Pronunciation Analysis Route (separate file in production)
// app/api/ai/pronunciation/route.ts
// ============================================================
export async function PUT(request: Request) {
  // This would be in a separate file: /api/ai/pronunciation/route.ts
  try {
    const supabase = createRouteHandlerClient({ cookies })
    const { data: { session } } = await supabase.auth.getSession()

    if (!session) {
      return NextResponse.json({ error: 'Não autenticado' }, { status: 401 })
    }

    const formData = await request.formData()
    const audioFile = formData.get('audio') as File
    const targetText = formData.get('targetText') as string
    const lessonId = formData.get('lessonId') as string

    if (!audioFile || !targetText) {
      return NextResponse.json({ error: 'Audio e texto alvo são obrigatórios' }, { status: 400 })
    }

    // 1. Transcribe user audio with Whisper
    const transcription = await openai.audio.transcriptions.create({
      file: audioFile,
      model: 'whisper-1',
      language: 'fr',
      response_format: 'text'
    })

    // 2. Analyze pronunciation with GPT-4o
    const analysisPrompt = `
Texto alvo em francês: "${targetText}"
Transcrição do usuário (falante nativo do português brasileiro): "${transcription}"

Analise a pronúncia e retorne JSON com este formato exato:
{
  "score": [0-100],
  "transcribed": "[o que foi transcrito]",
  "phoneme_issues": [
    {"phoneme": "[fonema]", "issue_pt": "[problema em português]", "tip_pt": "[dica em português]"}
  ],
  "feedback_pt": "[feedback geral encorajador em português, máx 2 frases]",
  "is_correct": [true/false]
}

Considere que falantes brasileiros têm dificuldade com: vogais nasais, o R uvular, o U fechado, liaisons.
`

    const analysis = await openai.chat.completions.create({
      model: 'gpt-4o',
      messages: [{ role: 'user', content: analysisPrompt }],
      response_format: { type: 'json_object' },
      max_tokens: 500
    })

    const result = JSON.parse(analysis.choices[0]?.message?.content || '{}')

    // 3. Save score to database
    const { data: savedScore } = await supabase
      .from('pronunciation_scores')
      .insert({
        user_id: session.user.id,
        lesson_id: lessonId || null,
        target_text: targetText,
        score: result.score,
        phoneme_scores: result.phoneme_issues,
        feedback_pt: result.feedback_pt
      })
      .select('id')
      .single()

    // 4. Award XP for practice
    if (result.score >= 90) {
      await supabase.rpc('award_xp', { p_user_id: session.user.id, p_xp: 15 })
    } else if (result.score >= 70) {
      await supabase.rpc('award_xp', { p_user_id: session.user.id, p_xp: 8 })
    } else {
      await supabase.rpc('award_xp', { p_user_id: session.user.id, p_xp: 3 })
    }

    return NextResponse.json({
      score: result.score,
      transcribed: result.transcribed,
      phonemeIssues: result.phoneme_issues,
      feedbackPt: result.feedback_pt,
      isCorrect: result.is_correct,
      scoreId: savedScore?.id
    })

  } catch (error) {
    console.error('Pronunciation API error:', error)
    return NextResponse.json({ error: 'Erro na análise de pronúncia' }, { status: 500 })
  }
}
