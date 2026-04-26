import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const GEMINI_KEY = Deno.env.get("GEMINI_API_KEY")!;
const MODEL = "gemini-2.5-flash";

interface MarkRequest {
  question_image_url: string;
  mark_scheme_image_url: string;
  student_image_base64: string;
}

const SYSTEM = `You are a strict GCSE/A-Level Maths examiner. Mark the student's working against the official mark scheme. Award marks per criterion. If the student scored full marks, return improvementTip as an empty string. Respond ONLY with JSON matching this exact schema:
{"totalAwarded":int,"totalPossible":int,"criteria":[{"criterionId":string,"awarded":int,"max":int,"rationale":string}],"skillsCorrect":string[],"skillsIncorrect":string[],"improvementTip":string}`;

Deno.serve(async (req) => {
  const body: MarkRequest = await req.json();
  const payload = {
    contents: [{
      parts: [
        { text: SYSTEM },
        { fileData: { fileUri: body.question_image_url, mimeType: "image/png" } },
        { fileData: { fileUri: body.mark_scheme_image_url, mimeType: "image/png" } },
        { inlineData: { data: body.student_image_base64, mimeType: "image/jpeg" } }
      ]
    }],
    generationConfig: { responseMimeType: "application/json" }
  };
  const resp = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_KEY}`,
    { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) }
  );
  const data = await resp.json();
  const text: string = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "{}";
  return new Response(text, { headers: { "Content-Type": "application/json" } });
});
