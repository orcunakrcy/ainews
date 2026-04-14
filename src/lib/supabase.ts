import { createClient } from "@supabase/supabase-js";

const supabaseUrl = import.meta.env.SUPABASE_URL;
const supabaseAnonKey = import.meta.env.SUPABASE_ANON_KEY;

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Types
export interface Article {
  id: string;
  title: string;
  slug: string;
  content: string;
  summary: string;
  twitter_text: string | null;
  category: string;
  tags: string[];
  source_url: string;
  source_name: string;
  featured_image: string | null;
  meta_description: string | null;
  relevance_score: number;
  status: "draft" | "published" | "rejected";
  published_at: string | null;
  created_at: string;
}

export interface Subscriber {
  id: string;
  email: string;
  confirm_token: string | null;
  confirmed: boolean;
  unsubscribe_token: string;
  created_at: string;
}

export { CATEGORIES } from "./constants";
