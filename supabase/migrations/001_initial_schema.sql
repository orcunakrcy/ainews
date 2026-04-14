-- ============================================
-- AI News Aggregation Platform - Initial Schema
-- ============================================

-- Sources: RSS feeds to monitor
CREATE TABLE sources (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  rss_url TEXT NOT NULL UNIQUE,
  category TEXT NOT NULL DEFAULT 'general',
  active BOOLEAN NOT NULL DEFAULT true,
  last_fetched_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Articles: the core content
CREATE TABLE articles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  content TEXT NOT NULL,
  summary TEXT NOT NULL,
  twitter_text TEXT,
  category TEXT NOT NULL DEFAULT 'general',
  tags TEXT[] DEFAULT '{}',
  source_url TEXT NOT NULL,
  source_name TEXT NOT NULL,
  source_title TEXT NOT NULL,
  featured_image TEXT,
  meta_description TEXT,
  relevance_score INTEGER DEFAULT 5,
  status TEXT NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'published', 'rejected')),
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  content_hash TEXT
);

CREATE INDEX idx_articles_status_published ON articles(status, published_at DESC);
CREATE INDEX idx_articles_category ON articles(category);
CREATE INDEX idx_articles_slug ON articles(slug);
CREATE INDEX idx_articles_content_hash ON articles(content_hash);
CREATE INDEX idx_articles_source_url ON articles(source_url);

-- Subscribers: newsletter email list
CREATE TABLE subscribers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  confirm_token TEXT,
  confirmed BOOLEAN NOT NULL DEFAULT false,
  confirmed_at TIMESTAMPTZ,
  unsubscribe_token TEXT NOT NULL DEFAULT encode(gen_random_bytes(32), 'hex'),
  unsubscribed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_subscribers_email ON subscribers(email);

-- Newsletters: sent digest records
CREATE TABLE newsletters (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  subject TEXT NOT NULL,
  content_html TEXT NOT NULL,
  article_ids UUID[] DEFAULT '{}',
  recipient_count INTEGER DEFAULT 0,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Tweets: track posted tweets
CREATE TABLE tweets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
  tweet_text TEXT NOT NULL,
  tweet_id TEXT,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'posted', 'failed')),
  error_message TEXT,
  posted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_tweets_article ON tweets(article_id);
CREATE INDEX idx_tweets_status ON tweets(status);

-- ============================================
-- Row Level Security
-- ============================================

ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscribers ENABLE ROW LEVEL SECURITY;
ALTER TABLE newsletters ENABLE ROW LEVEL SECURITY;
ALTER TABLE tweets ENABLE ROW LEVEL SECURITY;
ALTER TABLE sources ENABLE ROW LEVEL SECURITY;

-- Public read for published articles (anon key)
CREATE POLICY "Public can read published articles"
  ON articles FOR SELECT
  USING (status = 'published');

-- Service role full access
CREATE POLICY "Service role full access articles"
  ON articles FOR ALL
  USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access sources"
  ON sources FOR ALL
  USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access subscribers"
  ON subscribers FOR ALL
  USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access newsletters"
  ON newsletters FOR ALL
  USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access tweets"
  ON tweets FOR ALL
  USING (auth.role() = 'service_role');

-- Allow anon to subscribe
CREATE POLICY "Anon can subscribe"
  ON subscribers FOR INSERT
  WITH CHECK (true);

-- ============================================
-- Seed RSS Sources
-- ============================================

INSERT INTO sources (name, rss_url, category) VALUES
  ('TechCrunch AI', 'https://techcrunch.com/category/artificial-intelligence/feed/', 'general'),
  ('The Verge AI', 'https://www.theverge.com/rss/ai-artificial-intelligence/index.xml', 'general'),
  ('MIT Tech Review AI', 'https://www.technologyreview.com/topic/artificial-intelligence/feed', 'research'),
  ('OpenAI Blog', 'https://openai.com/blog/rss.xml', 'llms'),
  ('Anthropic Blog', 'https://www.anthropic.com/rss.xml', 'llms'),
  ('Google AI Blog', 'https://blog.google/technology/ai/rss/', 'general'),
  ('Ars Technica', 'https://feeds.arstechnica.com/arstechnica/features', 'general'),
  ('Import AI Newsletter', 'https://importai.substack.com/feed', 'research'),
  ('The Batch (DeepLearning.AI)', 'https://www.deeplearning.ai/the-batch/feed/', 'research'),
  ('Hacker News AI', 'https://hnrss.org/newest?q=AI+OR+LLM+OR+%22artificial+intelligence%22&points=50', 'general'),
  ('VentureBeat AI', 'https://venturebeat.com/category/ai/feed/', 'general'),
  ('Hugging Face Blog', 'https://huggingface.co/blog/feed.xml', 'llms');
