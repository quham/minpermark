// GoalScroll - Proof Verification Edge Function
// Deploy: supabase functions deploy verify

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface GoalInfo {
  title: string
  micro_habit: string
  trigger_type: string
  trigger_value: string
}

interface ProofItem {
  type: string  // 'camera' | 'screenshot' | 'reflection' | 'friendVouch'
  image_base64?: string
  text?: string
}

interface VerifyRequest {
  goal: GoalInfo
  proof_items: ProofItem[]
}

interface VerifyResponse {
  status: 'passed' | 'failed' | 'uncertain'
  confidence?: number
  reason?: string
}

serve(async (req) => {
  console.log(`Received ${req.method} request to verify`)
  
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      console.error('Missing Authorization header')
      return new Response(
        JSON.stringify({ error: 'No authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    console.log(`Creating admin client with URL: ${supabaseUrl}`)

    // Use SERVICE_ROLE_KEY to verify the token
    const adminClient = createClient(
      supabaseUrl ?? '',
      serviceRoleKey ?? ''
    )

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await adminClient.auth.getUser(token)

    if (authError || !user) {
      console.error('Auth verification failed:', authError?.message || 'User not found')
      return new Response(
        JSON.stringify({ 
          error: 'Unauthorized', 
          details: authError?.message || 'User not found',
          diagnostics: {
            hasUrl: !!supabaseUrl,
            hasServiceKey: !!serviceRoleKey,
            headerPrefix: authHeader.substring(0, 20)
          }
        }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`Authenticated user: ${user.id}`)

    // Parse request
    const { goal, proof_items }: VerifyRequest = await req.json()

    // Validate input
    if (!goal || !proof_items || proof_items.length === 0) {
      return new Response(
        JSON.stringify({ status: 'failed', reason: 'Proof is required for verification' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get Gemini API key
    const geminiApiKey = Deno.env.get('GEMINI_API_KEY')
    if (!geminiApiKey) {
      console.error('GEMINI_API_KEY not configured')
      // Fail open - accept proof if we can't verify
      return new Response(
        JSON.stringify({ status: 'passed', confidence: 0.5, reason: 'Verification service unavailable' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Build proof descriptions for the prompt
    const proofDescriptions = proof_items.map(p => {
      switch (p.type) {
        case 'reflection':
          return `Text reflection: "${p.text || 'No text provided'}"`
        case 'camera':
          return 'Photo proof submitted'
        case 'screenshot':
          return 'Screenshot proof submitted'
        case 'friendVouch':
          return 'Friend vouch submitted'
        default:
          return `${p.type} proof`
      }
    }).join(', ')

    // Build trigger description
    const triggerDescription = goal.trigger_type === 'time'
      ? `At ${goal.trigger_value}`
      : goal.trigger_type === 'after'
        ? `After ${goal.trigger_value}`
        : `When at ${goal.trigger_value}`

    // Build multimodal content for Gemini
    const parts: Array<{ text: string } | { inline_data: { mime_type: string; data: string } }> = []

    const textPrompt = `You are a habit verification assistant. Your job is to verify if the submitted proof clearly shows that the user completed their micro-habit.

Goal: ${goal.title}
Micro-habit: ${goal.micro_habit}
Trigger: ${triggerDescription}
Proof types submitted: ${proofDescriptions}

Instructions:
- Do not allow very ambiguous proofs.
- The proof must demonstrate the habit was completed.
- If a reflection is provided, it must be specific and detailed.

Respond ONLY with a JSON object in this exact format (no markdown, no explanation):
{"status": "passed", "confidence": 0.85, "reason": "Photo clearly shows the completed habit."}

Status must be one of: "passed", "failed", or "uncertain"
Confidence should be a number between 0.0 and 1.0
Reason should be a brief explanation (max 50 words)`

    parts.push({ text: textPrompt })

    // Add images if present
    for (const proof of proof_items) {
      if (proof.image_base64) {
        parts.push({
          inline_data: {
            mime_type: 'image/jpeg',
            data: proof.image_base64
          }
        })
      }
    }

    // Call Gemini API
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=${geminiApiKey}`
    console.log(`Calling Gemini at URL: ${geminiUrl.substring(0, 60)}...`)

    const geminiResponse = await fetch(
      geminiUrl,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts }],
          generationConfig: {
            maxOutputTokens: 2048,
          }
        })
      }
    )
    const geminiResponseClone = geminiResponse.clone()
    const geminiBodyText = await geminiResponseClone.text()
    let geminiBody
    try {
      geminiBody = JSON.parse(geminiBodyText)
    } catch {
      geminiBody = geminiBodyText
    }

    console.log('Gemini Full Response:', JSON.stringify({
      status: geminiResponse.status,
      statusText: geminiResponse.statusText,
      headers: Object.fromEntries(geminiResponse.headers.entries()),
      body: geminiBody
    }, null, 2))

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text()
      console.error(`Gemini API error: ${geminiResponse.status} - ${errorText}`)
      // Fail open on API errors
      return new Response(
        JSON.stringify({ status: 'passed', confidence: 0.5, reason: 'Verification service temporarily unavailable - proof accepted' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const geminiData = await geminiResponse.json()
    const responseText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text || ''

    // Parse JSON from response
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      if (jsonMatch) {
        const result = JSON.parse(jsonMatch[0]) as VerifyResponse

        // Convert uncertain to passed (as per existing app logic)
        if (result.status === 'uncertain') {
          result.status = 'passed'
          result.reason = result.reason || 'Proof accepted with some uncertainty'
        }

        // Validate status
        if (!['passed', 'failed'].includes(result.status)) {
          result.status = 'passed'
        }

        // Ensure confidence is in valid range
        if (typeof result.confidence !== 'number' || result.confidence < 0 || result.confidence > 1) {
          result.confidence = 0.7
        }

        return new Response(
          JSON.stringify(result),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    } catch (parseError) {
      console.error('Failed to parse Gemini response:', parseError)
    }

    // Default to passed if parsing fails
    return new Response(
      JSON.stringify({ status: 'passed', confidence: 0.7, reason: 'Proof accepted' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    // Fail open on any error
    return new Response(
      JSON.stringify({ status: 'passed', confidence: 0.5, reason: 'Network error - proof accepted' }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
