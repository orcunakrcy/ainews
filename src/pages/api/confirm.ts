import type { APIRoute } from "astro";
import { supabase } from "../../lib/supabase";

export const GET: APIRoute = async ({ url }) => {
  const token = url.searchParams.get("token");

  if (!token) {
    return new Response(htmlPage("Invalid Link", "No confirmation token provided."), {
      status: 400,
      headers: { "Content-Type": "text/html" },
    });
  }

  const { data, error } = await supabase
    .from("subscribers")
    .update({ confirmed: true, confirmed_at: new Date().toISOString(), confirm_token: null })
    .eq("confirm_token", token)
    .select()
    .single();

  if (error || !data) {
    return new Response(
      htmlPage("Invalid or Expired Link", "This confirmation link is no longer valid."),
      { status: 404, headers: { "Content-Type": "text/html" } }
    );
  }

  return new Response(
    htmlPage("Subscription Confirmed!", "You're all set. You'll receive our weekly AI digest every Sunday."),
    { status: 200, headers: { "Content-Type": "text/html" } }
  );
};

function htmlPage(title: string, message: string): string {
  return `<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${title} | AI News</title>
<style>body{font-family:system-ui;background:#0f172a;color:#f8fafc;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0}
.card{background:#1e293b;padding:2rem;border-radius:1rem;text-align:center;max-width:400px}
a{color:#22d3ee;text-decoration:none}</style>
</head>
<body><div class="card"><h1>${title}</h1><p>${message}</p><a href="/">Back to AI News</a></div></body>
</html>`;
}
