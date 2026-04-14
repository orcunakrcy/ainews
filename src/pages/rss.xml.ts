import rss from "@astrojs/rss";
import type { APIContext } from "astro";
import { supabase, type Article } from "../lib/supabase";

export async function GET(context: APIContext) {
  const { data: articles } = await supabase
    .from("articles")
    .select("*")
    .eq("status", "published")
    .order("published_at", { ascending: false })
    .limit(50);

  const typedArticles = (articles || []) as Article[];

  return rss({
    title: "AI News",
    description: "The latest artificial intelligence news, curated and summarized daily.",
    site: context.site!.toString(),
    items: typedArticles.map((article) => ({
      title: article.title,
      pubDate: new Date(article.published_at || article.created_at),
      description: article.summary,
      link: `/blog/${article.slug}`,
      categories: [article.category, ...article.tags],
    })),
  });
}
