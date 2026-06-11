-- ============================================================================
-- LinguaBot Initial Database Schema
-- ============================================================================
-- This migration creates all necessary tables with proper constraints,
-- indexes, and Row-Level Security (RLS) policies for production use.
-- ============================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";

-- ============================================================================
-- 1. USERS TABLE - User profile and metadata
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT auth.uid(),
  email TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL DEFAULT '',
  profile_image_url TEXT,
  native_language TEXT,
  learning_language TEXT,
  timezone TEXT DEFAULT 'UTC',
  preferred_theme TEXT DEFAULT 'system',

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login_at TIMESTAMP WITH TIME ZONE,

  -- Constraints
  CONSTRAINT email_not_empty CHECK (email != ''),
  CONSTRAINT display_name_not_empty CHECK (display_name != '')
);

-- Create indexes for users table
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_created_at ON public.users(created_at);
CREATE INDEX idx_users_learning_language ON public.users(learning_language);

-- Enable RLS on users table
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view their own data
CREATE POLICY "users_select_own" ON public.users
  FOR SELECT
  USING (auth.uid() = id);

-- RLS Policy: Users can update their own data
CREATE POLICY "users_update_own" ON public.users
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ============================================================================
-- 2. VOCABULARY_WORDS TABLE - Global vocabulary database
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.vocabulary_words (
  id BIGSERIAL PRIMARY KEY,
  word TEXT NOT NULL,
  native_meaning TEXT NOT NULL,
  example_sentence TEXT,
  learning_language TEXT NOT NULL,
  native_language TEXT,
  course_identifier TEXT NOT NULL,
  difficulty_level SMALLINT DEFAULT 1 CHECK (difficulty_level >= 1 AND difficulty_level <= 5),
  pronunciation TEXT,
  part_of_speech TEXT,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Constraints
  UNIQUE(word, learning_language, course_identifier),
  CONSTRAINT word_not_empty CHECK (word != ''),
  CONSTRAINT meaning_not_empty CHECK (native_meaning != '')
);

-- Create indexes for vocabulary_words table
CREATE INDEX idx_vocab_language ON public.vocabulary_words(learning_language);
CREATE INDEX idx_vocab_course ON public.vocabulary_words(course_identifier);
CREATE INDEX idx_vocab_difficulty ON public.vocabulary_words(difficulty_level);
CREATE INDEX idx_vocab_word ON public.vocabulary_words(word);

-- ============================================================================
-- 3. USER_PROGRESS TABLE - Track user's learning progress
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.user_progress (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  learning_language TEXT NOT NULL,
  day_number SMALLINT DEFAULT 1 CHECK (day_number >= 1),
  week_number SMALLINT DEFAULT 1 CHECK (week_number >= 1),
  words_completed BIGINT DEFAULT 0 CHECK (words_completed >= 0),
  current_streak SMALLINT DEFAULT 0 CHECK (current_streak >= 0),
  best_streak SMALLINT DEFAULT 0 CHECK (best_streak >= 0),
  total_words_learned BIGINT DEFAULT 0 CHECK (total_words_learned >= 0),
  total_sessions BIGINT DEFAULT 0 CHECK (total_sessions >= 0),
  average_accuracy NUMERIC(5, 2) DEFAULT 0.00 CHECK (average_accuracy >= 0 AND average_accuracy <= 100),

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Constraints
  UNIQUE(user_id, learning_language)
);

-- Create indexes for user_progress table
CREATE INDEX idx_progress_user_language ON public.user_progress(user_id, learning_language);
CREATE INDEX idx_progress_updated ON public.user_progress(updated_at);
CREATE INDEX idx_progress_streak ON public.user_progress(current_streak);

-- Enable RLS on user_progress table
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view their own progress
CREATE POLICY "progress_select_own" ON public.user_progress
  FOR SELECT
  USING (auth.uid() = user_id);

-- RLS Policy: Users can update their own progress
CREATE POLICY "progress_update_own" ON public.user_progress
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 4. AI_RESPONSES_CACHE TABLE - Cache frequently asked responses
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.ai_responses_cache (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  user_query TEXT NOT NULL,
  ai_response TEXT NOT NULL,
  learning_language TEXT NOT NULL,
  native_language TEXT,
  practice_mode TEXT,
  embedding vector(768),
  similarity FLOAT,
  tokens_used SMALLINT,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '30 days'),

  -- Constraints
  CONSTRAINT query_not_empty CHECK (user_query != ''),
  CONSTRAINT response_not_empty CHECK (ai_response != '')
);

-- Create indexes for ai_responses_cache table
CREATE INDEX idx_cache_language ON public.ai_responses_cache(learning_language);
CREATE INDEX idx_cache_expires ON public.ai_responses_cache(expires_at);
CREATE INDEX idx_cache_user ON public.ai_responses_cache(user_id);
CREATE INDEX idx_cache_embedding ON public.ai_responses_cache USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- Enable RLS on ai_responses_cache table
ALTER TABLE public.ai_responses_cache ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view their own cached responses
CREATE POLICY "cache_select_own" ON public.ai_responses_cache
  FOR SELECT
  USING (auth.uid() = user_id OR user_id IS NULL);

-- ============================================================================
-- 5. CHAT_HISTORY TABLE - Detailed conversation history
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.chat_history (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  learning_language TEXT NOT NULL,
  native_language TEXT,
  practice_mode TEXT,
  message_role TEXT NOT NULL CHECK (message_role IN ('user', 'assistant')),
  message_content TEXT NOT NULL,
  audio_path TEXT,
  tokens_used SMALLINT,
  processing_time_ms SMALLINT,
  is_error BOOLEAN DEFAULT FALSE,
  error_code TEXT,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Constraints
  CONSTRAINT content_not_empty CHECK (message_content != ''),
  CONSTRAINT valid_role CHECK (message_role IN ('user', 'assistant'))
);

-- Create indexes for chat_history table
CREATE INDEX idx_chat_user_language ON public.chat_history(user_id, learning_language);
CREATE INDEX idx_chat_created ON public.chat_history(created_at);
CREATE INDEX idx_chat_error ON public.chat_history(is_error);

-- Enable RLS on chat_history table
ALTER TABLE public.chat_history ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view their own chat history
CREATE POLICY "chat_select_own" ON public.chat_history
  FOR SELECT
  USING (auth.uid() = user_id);

-- ============================================================================
-- 6. USER_SETTINGS TABLE - User preferences and settings
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.user_settings (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,

  -- Notification settings
  notification_enabled BOOLEAN DEFAULT TRUE,
  daily_reminder_enabled BOOLEAN DEFAULT TRUE,
  daily_reminder_time TEXT DEFAULT '09:00',

  -- Learning preferences
  session_duration_minutes SMALLINT DEFAULT 30 CHECK (session_duration_minutes >= 5),
  difficulty_preference TEXT DEFAULT 'intermediate',
  focus_areas TEXT[], -- Array of focus areas

  -- Audio settings
  text_to_speech_enabled BOOLEAN DEFAULT TRUE,
  speech_to_text_enabled BOOLEAN DEFAULT TRUE,
  preferred_voice TEXT,
  speech_rate NUMERIC(3, 2) DEFAULT 1.0,

  -- Display settings
  dark_mode BOOLEAN DEFAULT FALSE,
  font_size SMALLINT DEFAULT 16,

  -- Privacy settings
  share_progress BOOLEAN DEFAULT FALSE,
  analytics_enabled BOOLEAN DEFAULT TRUE,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for user_settings table
CREATE INDEX idx_settings_user ON public.user_settings(user_id);

-- Enable RLS on user_settings table
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view their own settings
CREATE POLICY "settings_select_own" ON public.user_settings
  FOR SELECT
  USING (auth.uid() = user_id);

-- RLS Policy: Users can update their own settings
CREATE POLICY "settings_update_own" ON public.user_settings
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 7. ACTIVITY_LOGS TABLE - For analytics and debugging
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.activity_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL,
  learning_language TEXT,
  metadata JSONB,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for activity_logs table
CREATE INDEX idx_activity_user ON public.activity_logs(user_id);
CREATE INDEX idx_activity_type ON public.activity_logs(activity_type);
CREATE INDEX idx_activity_created ON public.activity_logs(created_at);

-- ============================================================================
-- 8. CREATE FUNCTION FOR AUTOMATIC TIMESTAMP UPDATES
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers for updated_at columns
CREATE TRIGGER update_users_timestamp
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vocabulary_words_timestamp
  BEFORE UPDATE ON public.vocabulary_words
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_progress_timestamp
  BEFORE UPDATE ON public.user_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_settings_timestamp
  BEFORE UPDATE ON public.user_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 9. VECTOR SEARCH FUNCTION FOR SIMILARITY MATCHING
-- ============================================================================
CREATE OR REPLACE FUNCTION match_cached_responses(
  query_embedding vector,
  match_threshold float DEFAULT 0.95,
  match_count int DEFAULT 1,
  p_learning_language text DEFAULT NULL,
  p_native_language text DEFAULT NULL,
  p_practice_mode text DEFAULT NULL
)
RETURNS TABLE (
  id bigint,
  user_query text,
  ai_response text,
  similarity float
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    cache.id,
    cache.user_query,
    cache.ai_response,
    1 - (cache.embedding <=> query_embedding) as similarity
  FROM public.ai_responses_cache cache
  WHERE
    (p_learning_language IS NULL OR cache.learning_language = p_learning_language)
    AND (p_native_language IS NULL OR cache.native_language = p_native_language)
    AND (p_practice_mode IS NULL OR cache.practice_mode = p_practice_mode)
    AND cache.expires_at > NOW()
    AND 1 - (cache.embedding <=> query_embedding) > match_threshold
  ORDER BY cache.embedding <=> query_embedding
  LIMIT match_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 10. CLEANUP FUNCTION FOR EXPIRED CACHE
-- ============================================================================
CREATE OR REPLACE FUNCTION cleanup_expired_cache()
RETURNS void AS $$
BEGIN
  DELETE FROM public.ai_responses_cache
  WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Schedule cleanup (would be done via pg_cron if available)
-- SELECT cron.schedule('cleanup-cache', '0 * * * *', 'SELECT cleanup_expired_cache()');

-- ============================================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================================
COMMENT ON TABLE public.users IS 'Stores user account information and preferences';
COMMENT ON TABLE public.vocabulary_words IS 'Global vocabulary database with translations and examples';
COMMENT ON TABLE public.user_progress IS 'Tracks each user''s learning progress and streaks';
COMMENT ON TABLE public.ai_responses_cache IS 'Caches frequently asked questions and AI responses with embeddings';
COMMENT ON TABLE public.chat_history IS 'Complete conversation history for each user';
COMMENT ON TABLE public.user_settings IS 'Individual user settings and preferences';
COMMENT ON TABLE public.activity_logs IS 'Analytics and activity tracking';

-- ============================================================================
-- INITIAL DATA SEEDING (Optional)
-- ============================================================================
-- Seed supported languages (commented out - uncomment as needed)
-- INSERT INTO public.vocabulary_words (word, native_meaning, learning_language, course_identifier, difficulty_level)
-- VALUES
--   ('hello', 'नमस्ते', 'English', 'global_english_hindi', 1),
--   ('goodbye', 'अलविदा', 'English', 'global_english_hindi', 1),
--   ('thank you', 'धन्यवाद', 'English', 'global_english_hindi', 1);
