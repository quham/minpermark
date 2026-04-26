// GoalScroll - Microhabit Suggestions Edge Function
// Deploy: supabase functions deploy suggestions

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface SuggestionsRequest {
  goal_title: string
}

interface SuggestionsResponse {
  suggestions: string[]
}

serve(async (req) => {
  console.log(`Received ${req.method} request to suggestions`)
  
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

    // Use SERVICE_ROLE_KEY to verify the token - this is more robust in Edge Functions
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
    const { goal_title }: SuggestionsRequest = await req.json()

    if (!goal_title || goal_title.trim().length < 3) {
      return new Response(
        JSON.stringify({ error: 'Invalid goal title', suggestions: getDefaultSuggestions('') }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get Gemini API key from secrets
    const geminiApiKey = Deno.env.get('GEMINI_API_KEY')
    if (!geminiApiKey) {
      console.error('GEMINI_API_KEY not configured')
      return new Response(
        JSON.stringify({ suggestions: getDefaultSuggestions(goal_title) }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Build prompt for Gemini
    const prompt = `You are a micro-habit coach helping someone build better habits. Given the goal "${goal_title}", suggest 6 specific, tiny micro-habits that:
- Take less than 2 minutes to complete
- Are so easy they're almost impossible to fail
- Create a foundation for building bigger habits
- Are actionable and specific (not vague)

Return ONLY a JSON array of 6 strings, no explanation or markdown. Example format: ["Do 1 pushup", "Read 1 page", "Write 1 sentence"]`

    // Call Gemini API
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=${geminiApiKey}`
    console.log(`Calling Gemini at URL: ${geminiUrl}`)

    const geminiResponse = await fetch(
      geminiUrl,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
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
      return new Response(
        JSON.stringify({ suggestions: getDefaultSuggestions(goal_title) }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const geminiData = await geminiResponse.json()
    const responseText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text || '[]'

    // Parse the JSON array from the response
    let suggestions: string[]
    try {
      const jsonMatch = responseText.match(/\[[\s\S]*\]/)
      suggestions = jsonMatch ? JSON.parse(jsonMatch[0]) : getDefaultSuggestions(goal_title)

      // Validate it's an array of strings
      if (!Array.isArray(suggestions) || suggestions.length === 0) {
        suggestions = getDefaultSuggestions(goal_title)
      }
    } catch {
      suggestions = getDefaultSuggestions(goal_title)
    }

    const response: SuggestionsResponse = { suggestions }

    return new Response(
      JSON.stringify(response),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', suggestions: getDefaultSuggestions('') }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

function getDefaultSuggestions(goal: string): string[] {
  const lowercased = goal.toLowerCase()

  if (lowercased.includes('health') || lowercased.includes('fit') || lowercased.includes('exercise') || lowercased.includes('gym')) {
    return [
      "Do 5 pushups",
      "Walk for 5 minutes",
      "Drink a glass of water",
      "Stretch for 2 minutes",
      "Take the stairs once",
      "Do 10 jumping jacks"
    ]
  }

  if (lowercased.includes('spanish') || lowercased.includes('language') || lowercased.includes('learn') || lowercased.includes('study')) {
    return [
      "Learn 1 new word",
      "Practice for 5 minutes",
      "Listen to 1 podcast minute",
      "Read 1 sentence aloud",
      "Write 3 vocabulary words",
      "Watch 1 minute of content"
    ]
  }

  if (lowercased.includes('read') || lowercased.includes('book')) {
    return [
      "Read 1 page",
      "Read for 5 minutes",
      "Read 1 paragraph",
      "Open my book",
      "Highlight 1 quote",
      "Read before bed for 2 minutes"
    ]
  }

  if (lowercased.includes('meditat') || lowercased.includes('mindful') || lowercased.includes('calm')) {
    return [
      "Take 3 deep breaths",
      "Meditate for 1 minute",
      "Close eyes and breathe for 30 seconds",
      "Notice 5 things around you",
      "Do a body scan for 1 minute",
      "Practice gratitude for 1 thing"
    ]
  }

  if (lowercased.includes('write') || lowercased.includes('journal')) {
    return [
      "Write 1 sentence",
      "Journal for 2 minutes",
      "Write 3 bullet points",
      "Open my journal/doc",
      "Free write for 1 minute",
      "Write one thing I'm grateful for"
    ]
  }

  // Generic defaults
  return [
    "Do it for just 2 minutes",
    "Take the first small step",
    "Start and stop if needed",
    "Do the bare minimum version",
    "Just show up and begin",
    "Commit to only 1 minute"
  ]
}
