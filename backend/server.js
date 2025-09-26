import express from "express";
import http from "http";
import { Server } from "socket.io";
import multer from "multer";
import pdfParse from "pdf-parse";
import axios from "axios";
import cors from "cors";
import { createClient } from "@supabase/supabase-js";
import "dotenv/config";
import fs from "fs";
import path from "path";
import { fileURLToPath } from 'url';
import textToSpeech from '@google-cloud/text-to-speech';
import speech from '@google-cloud/speech';

// ES Modules fix for __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// -------------------- Setup --------------------
const app = express();
const server = http.createServer(app);

// Configure CORS with specific allowed origins
const corsOptions = {
  origin: [
    'https://fundisaa.netlify.app', // Netlify deployment
    'https://flutter-application-2-1.onrender.com', // Current Render deployment
    'http://localhost:3000' // Local development
  ],
  credentials: true,
  optionsSuccessStatus: 200
};

const io = new Server(server, {
  cors: corsOptions
});

app.use(cors(corsOptions));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
app.use(express.static("public"));

// Ensure directories exist
const audioDir = path.join(__dirname, 'public', 'audio');
const generatedMediaDir = path.join(__dirname, 'public', 'generated-media');
if (!fs.existsSync(audioDir)) fs.mkdirSync(audioDir, { recursive: true });
if (!fs.existsSync(generatedMediaDir)) fs.mkdirSync(generatedMediaDir, { recursive: true });

// Supabase client
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY);

// Multer memory storage
const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
});

// Initialize Google Cloud clients (for speech-to-text and text-to-speech)
let speechClient, ttsClient;
if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  try {
    speechClient = new speech.SpeechClient();
    ttsClient = new textToSpeech.TextToSpeechClient();
  } catch (error) {
    console.warn('Google Cloud credentials not properly configured:', error.message);
  }
} else {
  console.warn('GOOGLE_APPLICATION_CREDENTIALS not set - voice features will be disabled');
}

// Supabase connection test
async function testSupabaseConnection() {
  try {
    const { data, error } = await supabase.from('files').select('*').limit(1);
    if (error) {
      console.error('❌ Supabase connection error:', error.message);
      return false;
    }
    console.log('✅ Supabase connected successfully!');
    return true;
  } catch (err) {
    console.error('❌ Supabase connection failed:', err.message);
    return false;
  }
}

// Simple chatbot helper (fallback when Hugging Face API is not available)
async function simpleChatbotResponse(message, language) {
  const responses = {
    english: {
      "hello": "Hello! How can I help you with your studies today?",
      "hi": "Hi there! What would you like to learn about?",
      "help": "I can help you with your studies, answer questions, and provide educational support.",
      "math": "Mathematics is a great subject! What specific math topic are you working on?",
      "science": "Science is fascinating! Which branch of science are you interested in?",
      "english": "English language and literature are important subjects. What do you need help with?",
      "default": "I'm here to help with your educational needs. What would you like to know?"
    },
    zulu: {
      "sawubona": "Sawubona! Ngingakusiza kanjani ngokufunda kwakho namuhla?",
      "yebo": "Yebo! Yini ongathanda ukuyifunda?",
      "usizo": "Ngingakusiza ngokufunda kwakho, ukuphendula imibuzo, nokunikeza ukwesekwa kwemfundo.",
      "izibalo": "Izibalo yisifundo esihle! Iyiphi indaba yezibalo oyisebenzayo?",
      "isayensi": "Isayensi iyathakazelisa! Iyiphi igatsha lesayensi onentshisekelo kulo?",
      "isiNgisi": "Ulimi lwesiNgisi nezincwadi kuyizifundo ezibalulekile. Yini odinga usizo ngayo?",
      "default": "Ngilapha ukusiza ngezidingo zakho zemfundo. Yini ongathanda ukuyazi?"
    }
  };

  const langResponses = responses[language] || responses.english;
  const lowerMessage = message.toLowerCase();
  
  for (const [key, response] of Object.entries(langResponses)) {
    if (lowerMessage.includes(key)) {
      return response;
    }
  }
  
  return langResponses.default;
}

// Hugging Face API integration function - FIXED
async function callHuggingFaceAPI(model, prompt, parameters = {}) {
  try {
    // Check if API key is available
    if (!process.env.HUGGING_FACE_API_KEY) {
      throw new Error("Hugging Face API key not configured");
    }

    const payload = { inputs: prompt, ...parameters };
    const response = await axios.post(
      `https://api-inference.huggingface.co/models/${model}`, // Use the model parameter correctly
      payload,
      {
        headers: {
          Authorization: `Bearer ${process.env.HUGGING_FACE_API_KEY}`,
          "Content-Type": "application/json",
        },
        timeout: 60000, // 60 second timeout for longer processes
      }
    );

    if (response.data && response.data[0] && response.data[0].generated_text) {
      return response.data[0].generated_text;
    } else if (response.data && response.data.error) {
      throw new Error(`Hugging Face API error: ${response.data.error}`);
    } else {
      // For models that return different response formats (like image generation)
      return response.data;
    }
  } catch (error) {
    console.error("Hugging Face API call failed:", error.message);
    
    // Fallback to simple chatbot for common errors
    if (error.response?.status === 503) {
      return "The AI model is currently loading. Please try again in a few moments.";
    } else if (error.code === 'ECONNABORTED') {
      return "The request took too long to process. Please try again with a shorter message.";
    } else if (error.response?.status === 401) {
      return "API authentication failed. Please check your Hugging Face API key.";
    }
    
    throw error; // Re-throw for the caller to handle
  }
}

// Alternative text-to-speech using Facebook's MMS-TTS for African languages
async function generateSpeechWithMMS(text, language = 'en') {
  try {
    // Map languages to MMS-TTS language codes
    const languageMap = {
      'en': 'eng',
      'zulu': 'zul',
      'xhosa': 'xho',
      'afrikaans': 'afr'
    };
    
    const langCode = languageMap[language] || 'eng';
    
    const result = await callHuggingFaceAPI(
      "facebook/mms-tts", 
      text,
      { 
        parameters: { 
          wait_for_model: true,
          language: langCode
        } 
      }
    );
    
    // MMS-TTS returns audio data
    const filename = `audio_${Date.now()}.wav`;
    const filepath = path.join(audioDir, filename);
    
    // Handle the audio response
    let audioBuffer;
    if (Buffer.isBuffer(result)) {
      audioBuffer = result;
    } else {
      audioBuffer = Buffer.from(result);
    }
    
    fs.writeFileSync(filepath, audioBuffer);
    return `/audio/${filename}`;
  } catch (error) {
    console.error('MMS-TTS failed, falling back to Google TTS:', error);
    
    // Fall back to Google TTS
    if (ttsClient) {
      return await generateSpeech(text, language);
    }
    
    throw new Error('All text-to-speech services failed');
  }
}

// Enhanced text-to-speech function with fallback
async function generateSpeech(text, language = 'en') {
  // Try MMS-TTS first for African languages, fall back to Google TTS
  if (['zulu', 'xhosa', 'afrikaans'].includes(language)) {
    try {
      return await generateSpeechWithMMS(text, language);
    } catch (error) {
      console.warn('MMS-TTS failed, falling back to Google TTS');
    }
  }
  
  // Use Google TTS for other languages or as fallback
  if (!ttsClient) {
    throw new Error('Text-to-speech not configured');
  }

  // Map languages to voice codes
  const voiceMap = {
    'en': { languageCode: 'en-US', name: 'en-US-Neural2-F' },
    'zulu': { languageCode: 'zu-ZA', name: 'zu-ZA-Standard-A' },
    'xhosa': { languageCode: 'xh-ZA', name: 'xh-ZA-Standard-A' },
    'afrikaans': { languageCode: 'af-ZA', name: 'af-ZA-Standard-A' }
  };

  const voiceConfig = voiceMap[language] || voiceMap['en'];

  const request = {
    input: { text },
    voice: voiceConfig,
    audioConfig: { 
      audioEncoding: 'MP3',
      speakingRate: 0.9, // Slightly slower for educational content
      pitch: 0 // Neutral pitch
    }
  };

  try {
    const [response] = await ttsClient.synthesizeSpeech(request);
    const filename = `audio_${Date.now()}.mp3`;
    const filepath = path.join(audioDir, filename);
    
    fs.writeFileSync(filepath, response.audioContent, 'binary');
    return `/audio/${filename}`;
  } catch (error) {
    console.error('Text-to-speech error:', error);
    throw new Error(`Failed to generate speech: ${error.message}`);
  }
}

// Speech-to-Text function
async function transcribeAudio(audioBuffer, language = 'en') {
  if (!speechClient) {
    throw new Error('Speech-to-text not configured');
  }

  // Map languages to recognition config
  const languageMap = {
    'en': 'en-ZA',
    'zulu': 'zu-ZA',
    'xhosa': 'xh-ZA',
    'afrikaans': 'af-ZA'
  };

  const languageCode = languageMap[language] || 'en-ZA';

  const audioBytes = audioBuffer.toString('base64');
  const request = {
    audio: { content: audioBytes },
    config: {
      encoding: 'WEBM_OPUS',
      sampleRateHertz: 48000,
      languageCode: languageCode,
      model: 'command_and_search' // Better for voice commands
    },
  };

  try {
    const [response] = await speechClient.recognize(request);
    if (!response.results || response.results.length === 0) {
      throw new Error('No speech recognized');
    }
    
    const transcription = response.results
      .map(result => result.alternatives[0].transcript)
      .join('\n');
    
    return transcription;
  } catch (error) {
    console.error('Speech recognition error:', error);
    throw new Error(`Speech recognition failed: ${error.message}`);
  }
}

// Check if media already exists for a query
async function findExistingMedia(query, mediaType, language) {
  try {
    const { data, error } = await supabase
      .from('generated_media')
      .select('*')
      .ilike('query', `%${query}%`)
      .eq('media_type', mediaType)
      .eq('language', language)
      .limit(1);
    
    if (error) throw error;
    return data.length > 0 ? data[0] : null;
  } catch (error) {
    console.error('Error searching for existing media:', error);
    return null;
  }
}

// Save generated media to database
async function saveGeneratedMedia(query, mediaType, filepath, language, description) {
  try {
    const filename = path.basename(filepath);
    const publicUrl = `/generated-media/${filename}`;
    
    const { data, error } = await supabase
      .from('generated_media')
      .insert([
        {
          query,
          media_type: mediaType,
          file_path: filepath,
          public_url: publicUrl,
          language,
          description
        }
      ])
      .select();
    
    if (error) throw error;
    return data[0];
  } catch (error) {
    console.error('Error saving generated media:', error);
    return null;
  }
}

// Generate image using Hugging Face - FIXED
async function generateImage(prompt) {
  try {
    // Using the recommended Stable Diffusion model
    const result = await callHuggingFaceAPI(
      "stabilityai/stable-diffusion-2-1", 
      prompt,
      { parameters: { wait_for_model: true } }
    );
    
    // The API returns image bytes
    const filename = `image_${Date.now()}.png`;
    const filepath = path.join(generatedMediaDir, filename);
    
    // Handle different response formats from image generation models
    let imageBuffer;
    if (Buffer.isBuffer(result)) {
      imageBuffer = result;
    } else if (typeof result === 'string' && result.startsWith('data:image/')) {
      // Handle base64 encoded image
      const base64Data = result.replace(/^data:image\/\w+;base64,/, '');
      imageBuffer = Buffer.from(base64Data, 'base64');
    } else {
      // Assume it's already in the right format for writing
      imageBuffer = Buffer.from(result);
    }
    
    fs.writeFileSync(filepath, imageBuffer);
    
    return filepath;
  } catch (error) {
    console.error('Image generation failed:', error);
    throw error;
  }
}

// Generate video using Hugging Face (text-to-video is an emerging technology)
async function generateVideo(prompt) {
  try {
    // Note: Text-to-video models are still experimental
    // This is a placeholder for when better models become available
    console.log(`Video generation requested for: ${prompt}`);
    
    // For now, we'll return a placeholder or use an alternative approach
    // You might want to use a service like RunwayML or other video generation APIs
    
    throw new Error('Video generation is not fully implemented yet. Please check back later.');
  } catch (error) {
    console.error('Video generation failed:', error);
    throw error;
  }
}

// -------------------- PDF Upload --------------------
app.post("/files/upload", upload.array("files"), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ error: "No files uploaded" });
    }

    const uploader = req.body.uploader || "Teacher";
    const fileIds = [];

    for (const file of req.files) {
      const filename = `${Date.now()}_${file.originalname.replace(/\s+/g, '_')}`;
      
      // Upload to Supabase Storage
      const { error: storageError } = await supabase.storage
        .from("files")
        .upload(filename, file.buffer, {
          contentType: file.mimetype,
          upsert: false
        });

      if (storageError) {
        console.error('Storage error:', storageError);
        throw storageError;
      }

      // Insert metadata into database
      const { data, error: dbError } = await supabase
        .from("files")
        .insert([
          {
            filename: filename,
            original_name: file.originalname,
            uploader: uploader,
            content_type: file.mimetype
          }
        ])
        .select();

      if (dbError) {
        console.error('Database error:', dbError);
        throw dbError;
      }

      fileIds.push(data[0].id);
      
      // Emit socket event for real-time update
      const moduleData = {
        id: data[0].id,
        title: file.originalname.replace(/\.[^/.]+$/, ""),
        description: `Module content from ${file.originalname}`,
        createdAt: new Date().toISOString(),
        fileIds: [data[0].id],
        uploader: uploader
      };
      
      io.emit('module:new', moduleData);
      io.emit('file:new', {
        id: data[0].id,
        filename: filename,
        original_name: file.originalname,
        uploader: uploader,
        created_at: new Date().toISOString()
      });
    }

    res.json({ success: true, fileIds });
  } catch (err) {
    console.error('Upload error:', err);
    res.status(500).json({ error: "Upload failed", details: err.message });
  }
});

// -------------------- List & Download --------------------
app.get("/files", async (req, res) => {
  try {
    const { data, error } = await supabase.from("files").select("*").order("created_at", { ascending: false });
    if (error) throw error;
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch files" });
  }
});

// -------------------- Modules (same as files for now) --------------------
app.get("/modules", async (req, res) => {
  try {
    const { data, error } = await supabase.from("files").select("*").order("created_at", { ascending: false });
    if (error) throw error;
    
    // Transform files to module format
    const modules = data.map(file => ({
      id: file.id,
      title: file.original_name.replace(/\.[^/.]+$/, ""), // Remove file extension
      description: `Module content from ${file.original_name}`,
      createdAt: file.created_at,
      fileIds: [file.id],
      uploader: file.uploader
    }));
    
    res.json(modules);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch modules" });
  }
});

// -------------------- Text Translation --------------------
app.post("/translate", async (req, res) => {
  try {
    const { text, targetLanguage = "zulu" } = req.body;
    if (!text) return res.status(400).json({ error: "Text required" });

    let translatedText;
    try {
      // Use the recommended model for African languages
      const prompt = `Translate the following English text to ${targetLanguage}: "${text}"`;
      translatedText = await callHuggingFaceAPI("facebook/m2m100_1.2B", prompt);
    } catch (err) {
      // Fallback to simple response
      translatedText = `[${targetLanguage} translation of: ${text}] - Translation service temporarily unavailable`;
    }

    res.json({ 
      success: true,
      originalText: text,
      translatedText: translatedText 
    });
  } catch (err) {
    console.error('Translation error:', err);
    res.status(500).json({ error: "Translation failed", details: err.message });
  }
});

app.get("/files/download/:filename", async (req, res) => {
  try {
    const { data, error } = await supabase.storage.from("files").createSignedUrl(req.params.filename, 60 * 5);
    if (error) throw error;
    res.json({ url: data.signedUrl });
  } catch (err) {
    res.status(500).json({ error: "Failed to generate URL" });
  }
});

// -------------------- Translate PDF --------------------
app.post("/translate-pdf/:id", async (req, res) => {
  try {
    const { data: fileData, error } = await supabase
      .from("files")
      .select("*")
      .eq("id", req.params.id)
      .single();
    
    if (error || !fileData) {
      return res.status(404).json({ error: "File not found" });
    }

    let translatedText;
    let originalText = `Content from ${fileData.original_name}`;

    if (fileData.content_type === 'application/pdf') {
      try {
        // Download file from storage
        const { data: fileBuffer, error: downloadError } = await supabase.storage
          .from("files")
          .download(fileData.filename);
        
        if (!downloadError) {
          const buffer = Buffer.from(await fileBuffer.arrayBuffer());
          const pdfData = await pdfParse(buffer);
          originalText = pdfData.text;
        }
      } catch (pdfErr) {
        console.error('PDF parsing error:', pdfErr);
      }
    }

    try {
      // Use the recommended model for African languages
      const prompt = `Translate the following text to isiZulu: "${originalText.substring(0, 1000)}"`;
      translatedText = await callHuggingFaceAPI("facebook/m2m100_1.2B", prompt);
    } catch (err) {
      // Fallback translation
      translatedText = `[isiZulu translation of ${fileData.original_name}] - Translation service temporarily unavailable. Original content: ${originalText.substring(0, 300)}...`;
    }

    // Update translation in database
    await supabase
      .from("files")
      .update({ translation: translatedText })
      .eq("id", fileData.id);

    res.json({ 
      success: true,
      originalText: originalText,
      translatedText: translatedText,
      filename: `translated_${fileData.original_name}`,
      downloadUrl: `/files/download/${fileData.filename}`
    });

  } catch (err) {
    console.error('PDF translation error:', err);
    res.status(500).json({ error: "PDF translation failed", details: err.message });
  }
});

// -------------------- Voice Processing --------------------
app.post("/speech-to-text", upload.single('audio'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: "No audio file provided" });
    }

    if (!speechClient) {
      return res.status(500).json({ error: "Speech-to-text not configured" });
    }

    const { language = 'en' } = req.body;
    const transcription = await transcribeAudio(req.file.buffer, language);
    
    res.json({ 
      success: true,
      transcription 
    });
  } catch (err) {
    console.error('Speech-to-text error:', err);
    res.status(500).json({ error: "Speech recognition failed", details: err.message });
  }
});

app.post("/text-to-speech", async (req, res) => {
  try {
    const { text, language = 'en' } = req.body;
    if (!text) return res.status(400).json({ error: "Text required" });

    const audioUrl = await generateSpeech(text, language);
    
    res.json({ 
      success: true,
      audioUrl 
    });
  } catch (err) {
    console.error('Text-to-speech error:', err);
    res.status(500).json({ error: "Speech generation failed", details: err.message });
  }
});

// -------------------- Media Generation --------------------
app.post("/generate-media", async (req, res) => {
  try {
    const { prompt, mediaType = 'image', language = 'en' } = req.body;
    if (!prompt) return res.status(400).json({ error: "Prompt required" });

    // Check if we already have media for this query
    const existingMedia = await findExistingMedia(prompt, mediaType, language);
    if (existingMedia) {
      return res.json({
        success: true,
        mediaUrl: existingMedia.public_url,
        mediaType,
        fromCache: true
      });
    }

    let filepath, description;
    
    if (mediaType === 'image') {
      // Generate image
      filepath = await generateImage(prompt);
      description = `Image generated for: ${prompt}`;
    } else if (mediaType === 'video') {
      // Generate video
      filepath = await generateVideo(prompt);
      description = `Video generated for: ${prompt}`;
    } else {
      return res.status(400).json({ error: "Unsupported media type" });
    }

    // Save to database for future reuse
    const savedMedia = await saveGeneratedMedia(
      prompt, 
      mediaType, 
      filepath, 
      language, 
      description
    );

    if (!savedMedia) {
      console.error('Failed to save media to database');
    }

    const filename = path.basename(filepath);
    const publicUrl = `/generated-media/${filename}`;
    
    res.json({ 
      success: true,
      mediaUrl: publicUrl,
      mediaType,
      fromCache: false
    });
  } catch (err) {
    console.error('Media generation error:', err);
    res.status(500).json({ error: "Media generation failed", details: err.message });
  }
});

// -------------------- Chatbot --------------------
app.post("/chat", async (req, res) => {
  try {
    const { message, language = "zulu", generateAudio = false } = req.body;
    if (!message) return res.status(400).json({ error: "Message required" });

    let prompt;
    if (language === "english") {
      prompt = message; // Respond naturally in English
    } else {
      prompt = `Respond in isiZulu: ${message}`; // Respond in isiZulu
    }

    // Use the recommended text generation model
    const result = await callHuggingFaceAPI("tiiuae/falcon-7b-instruct", prompt);
    
    let audioUrl = null;
    if (generateAudio) {
      try {
        audioUrl = await generateSpeech(result, language);
      } catch (audioError) {
        console.error('Audio generation failed:', audioError);
      }
    }
    
    res.json({ 
      reply: result, 
      language,
      audioUrl 
    });
  } catch (err) {
    res.status(500).json({ error: "Chatbot failed", details: err.message });
  }
});

// Socket.IO for real-time chat
io.on("connection", (socket) => {
  console.log("Client connected");

  socket.on("chat message", async (data) => {
    try {
      const { message, language = "zulu", generateAudio = false } = data;
      
      let prompt;
      if (language === "english") {
        prompt = message; // Respond naturally in English
      } else {
        prompt = `Respond in isiZulu: ${message}`; // Respond in isiZulu
      }

      // Emit thinking/processing state
      socket.emit("bot thinking", { message: "Processing your request..." });
      
      // Use the recommended text generation model
      const result = await callHuggingFaceAPI("tiiuae/falcon-7b-instruct", prompt);
      
      let audioUrl = null;
      if (generateAudio) {
        try {
          audioUrl = await generateSpeech(result, language);
        } catch (audioError) {
          console.error('Audio generation failed:', audioError);
        }
      }
      
      socket.emit("bot reply", { 
        reply: result, 
        language,
        audioUrl 
      });
    } catch {
      socket.emit("bot error", "Error processing request.");
    }
  });

  socket.on("disconnect", () => console.log("Client disconnected"));
});

// -------------------- Server --------------------
const PORT = process.env.PORT || 5000;

if (!process.env.HUGGING_FACE_API_KEY) console.warn("⚠️ HUGGING_FACE_API_KEY missing");
if (!process.env.SUPABASE_URL || !process.env.SUPABASE_KEY) console.warn("⚠️ Supabase credentials missing");
if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) console.warn("⚠️ Google Cloud credentials missing - voice features disabled");

server.listen(PORT, async () => {
  console.log(`✅ Server running on port ${PORT}`);
  // Test Supabase connection when server starts
  await testSupabaseConnection();
});