import type { APIRoute } from "astro";
import { supabase } from "../../lib/supabase";

export const POST: APIRoute = async ({ request }) => {
  try {
    const { email } = await request.json();

    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return new Response(JSON.stringify({ error: "Valid email is required." }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Generate confirm token
    const confirmToken = crypto.randomUUID();

    const { error } = await supabase.from("subscribers").insert({
      email: email.toLowerCase().trim(),
      confirm_token: confirmToken,
    });

    if (error) {
      if (error.code === "23505") {
        return new Response(
          JSON.stringify({ error: "This email is already subscribed." }),
          { status: 409, headers: { "Content-Type": "application/json" } }
        );
      }
      throw error;
    }

    // TODO: Send confirmation email via Resend (handled by n8n or add here later)

    return new Response(
      JSON.stringify({
        message: "Check your inbox to confirm your subscription!",
      }),
      { status: 201, headers: { "Content-Type": "application/json" } }
    );
  } catch {
    return new Response(
      JSON.stringify({ error: "Something went wrong. Please try again." }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
};
