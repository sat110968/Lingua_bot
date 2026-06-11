// Script to automatically pump 100s of words from Gemini into your Supabase database.
// To run this: open your terminal and type: dart bin/seed_database.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print('Loading environment variables...');
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('❌ Error: .env file not found.');
    return;
  }
  
  String geminiKey = '';
  String supabaseUrl = '';
  String supabaseKey = '';

  for (String line in envFile.readAsLinesSync()) {
    if (line.startsWith('GEMINI_API_KEY=')) {
      geminiKey = line.split('=')[1].trim();
      // Remove any trailing quotes
      geminiKey = geminiKey.replaceAll('"', '').replaceAll("'", "");
    }
    if (line.startsWith('SUPABASE_URL=')) {
      supabaseUrl = line.split('=')[1].trim();
      supabaseUrl = supabaseUrl.replaceAll('"', '').replaceAll("'", "");
    }
    if (line.startsWith('SUPABASE_ANON_KEY=')) {
      supabaseKey = line.split('=')[1].trim();
      supabaseKey = supabaseKey.replaceAll('"', '').replaceAll("'", "");
    }
  }

  if (geminiKey.isEmpty || supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    print('❌ Missing keys in .env. Ensure GEMINI_API_KEY, SUPABASE_URL, and SUPABASE_ANON_KEY are set.');
    return;
  }

  print('✅ Keys configured. Starting global curriculum seed...');

  // We loop 10 times, generating 50 words each time to get your 500+ global word dump!
  // Note: We'll start with just 1 loop to test it. You can change this to 10 once you're ready!
  int loops = 1; 

  for (int i = 0; i < loops; i++) {
    print('-----------------------------------------');
    print('🔄 Request ${i + 1} of $loops: Asking Gemini for 50 words...');
    
    // 1. Call Gemini
    final String geminiUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$geminiKey';
    
    final prompt = """
      Generate 50 extremely common, beginner-level English vocabulary words that are essential for daily fluency.
      Do not repeat words you'd typically give (try to randomize slightly).
      Provide the English word, its Hindi translation, and a simple English example sentence.
      Return exactly 50 words in a strictly valid JSON array of objects with keys: 'word', 'native_meaning', 'example_sentence'.
      DO NOT format the response as markdown blocks (no ```json). Output raw JSON.
    """;

    final geminiRes = await http.post(
      Uri.parse(geminiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {'role': 'user', 'parts': [{'text': prompt}]}
        ],
        "generationConfig": {
           "temperature": 0.8
        }
      })
    );

    if (geminiRes.statusCode != 200) {
      print('❌ Gemini API Error: ${geminiRes.statusCode}');
      print(geminiRes.body);
      continue;
    }

    try {
      final decodedGemini = jsonDecode(geminiRes.body);
      var textData = decodedGemini['candidates'][0]['content']['parts'][0]['text'];
      textData = textData.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final List<dynamic> wordsList = jsonDecode(textData);
      print('✅ Received ${wordsList.length} words from Gemini. Preparing to insert into Supabase...');

      // 2. Format the JSON structure for Supabase Table injection
      for (var row in wordsList) {
        row['learning_language'] = 'English';
        row['course_identifier'] = 'global_english_hindi';
      }

      // 3. Fire to Supabase via raw REST API
      final String supabaseApiUrl = '$supabaseUrl/rest/v1/vocabulary_words';
      final supabaseRes = await http.post(
        Uri.parse(supabaseApiUrl),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal, resolution=ignore-duplicates'
        },
        body: jsonEncode(wordsList)
      );

      if (supabaseRes.statusCode == 201 || supabaseRes.statusCode == 204) {
        print('🎉 Successfully stored 50 words in the database!');
      } else {
        print('❌ Supabase Upload Error: ${supabaseRes.statusCode}');
        print(supabaseRes.body);
      }

    } catch (e) {
      print('❌ Error parsing or uploading: $e');
    }
  }
}
