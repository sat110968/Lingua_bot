-- Usage: Run this script in the Supabase SQL Editor to set up your curriculum tables.

-- 1. Create the Vocabulary Table for the Global Curriculum List
CREATE TABLE IF NOT EXISTS vocabulary_words (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_identifier text NOT NULL DEFAULT 'global_english_hindi', -- e.g., 'global_english_hindi'
  word text NOT NULL,
  native_meaning text NOT NULL, 
  example_sentence text,
  learning_language text NOT NULL, 
  created_at timestamp with time zone DEFAULT now(),
  UNIQUE(course_identifier, word) -- Prevent inserting duplicate words into the same global dump
);

-- Index for fast lookup by course
CREATE INDEX idx_vocab_course ON vocabulary_words (course_identifier, learning_language);

-- 2. Insert Base Sample Data 
INSERT INTO vocabulary_words (course_identifier, word, native_meaning, example_sentence, learning_language)
VALUES 
  ('global_english_hindi', 'Hello', 'नमस्ते / Hello', 'Hello, how are you?', 'English'),
  ('global_english_hindi', 'I', 'मैं / I', 'I am happy.', 'English'),
  ('global_english_hindi', 'You', 'तुम / You', 'You are my friend.', 'English'),
  ('global_english_hindi', 'Good', 'अच्छा / Good', 'This is a good book.', 'English'),
  ('global_english_hindi', 'Yes', 'हाँ / Yes', 'Yes, I like it.', 'English')
ON CONFLICT DO NOTHING;
