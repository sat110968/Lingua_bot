-- Usage: Run this script in the Supabase SQL Editor to set up your database.

-- 1. Enable pgvector for semantic search caching
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Create the AI responses cache table
CREATE TABLE IF NOT EXISTS ai_responses_cache (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_query text NOT NULL,
  ai_response text NOT NULL,
  learning_language text NOT NULL,
  native_language text NOT NULL,
  practice_mode text NOT NULL,
  -- Note: Gemini embeddings typically output 768 dimensions for text-embedding-004
  embedding vector(768), 
  created_at timestamp with time zone DEFAULT now()
);

-- 3. Create an index for faster similarity searches uses HNSW (Hierarchical Navigable Small World)
CREATE INDEX ON ai_responses_cache USING hnsw (embedding vector_ip_ops);

-- 4. Create a function to perform the semantic search
-- This function can be called via Supabase RPC from Flutter
CREATE OR REPLACE FUNCTION match_cached_responses (
  query_embedding vector(768),
  match_threshold float,
  match_count int,
  p_learning_language text,
  p_native_language text,
  p_practice_mode text
)
RETURNS TABLE (
  id uuid,
  user_query text,
  ai_response text,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    ai_responses_cache.id,
    ai_responses_cache.user_query,
    ai_responses_cache.ai_response,
    1 - (ai_responses_cache.embedding <=> query_embedding) AS similarity
  FROM ai_responses_cache
  WHERE 
    ai_responses_cache.learning_language = p_learning_language
    AND ai_responses_cache.native_language = p_native_language
    AND ai_responses_cache.practice_mode = p_practice_mode
    AND 1 - (ai_responses_cache.embedding <=> query_embedding) > match_threshold
  ORDER BY ai_responses_cache.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;
