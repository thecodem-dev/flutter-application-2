
import express from "express";
import http from "http";
import { Server } from "socket.io";
import multer from "multer";
import pdfParse from "pdf-parse";
import axios from "axios";
import cors from "cors";
import { createClient } from "@supabase/supabase-js";
import "dotenv/config";

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
app.use(express.json());
app.use(express.static("public"));

// Supabase client
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY);

// Multer memory storage
const upload = multer({ storage: multer.memoryStorage() });

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

// Hugging Face API integration function
async function callHuggingFaceAPI(model, prompt) {
  try {
    // Check if API key is available
    if (!process.env.HUGGING_FACE_API_KEY) {
      throw new Error("Hugging Face API key not configured");
    }

    const response = await axios.post(
      `https://api-inference.huggingface.co/models/${model}`,
      { inputs: prompt },
      {
        headers: {
          Authorization: `Bearer ${process.env.HUGGING_FACE_API_KEY}`,
          "Content-Type": "application/json",
        },
        timeout: 30000, // 30 second timeout
      }
    );

    if (response.data && response.data[0] && response.data[0].generated_text) {
      return response.data[0].generated_text;
    } else if (response.data && response.data.error) {
      throw new Error(`Hugging Face API error: ${response.data.error}`);
    } else {
      throw new Error("Unexpected response format from Hugging Face API");
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

    // Download file from storage
    const { data: fileBuffer, error: downloadError } = await supabase.storage
      .from("files")
      .download(fileData.filename);
    
    if (downloadError) throw downloadError;

    const buffer = Buffer.from(await fileBuffer.arrayBuffer());
    const pdfData = await pdfParse(buffer);

    // Simple translation (replace with actual translation service)
    const translatedText = pdfData.text.length > 500 
      ? pdfData.text.substring(0, 500) + "... [Translation truncated for demo]"
      : pdfData.text;

    // Update translation in database
    await supabase
      .from("files")
      .update({ translation: translatedText })
      .eq("id", fileData.id);

    res.json({ 
      success: true,
      originalText: pdfData.text,
      translatedText: translatedText,
      filename: `translated_${fileData.original_name}`,
      downloadUrl: `/files/download/${fileData.filename}`
    });

  } catch (err) {
    console.error('PDF translation error:', err);
    res.status(500).json({ error: "PDF translation failed", details: err.message });
  }
});

// -------------------- Chatbot --------------------
app.post("/chat", async (req, res) => {
  try {
    const { message, language = "zulu" } = req.body;
    if (!message) return res.status(400).json({ error: "Message required" });

    let prompt;
    if (language === "english") {
      prompt = message; // Respond naturally in English
    } else {
      prompt = `Respond in isiZulu: ${message}`; // Respond in isiZulu
    }

    const result = await callHuggingFaceAPI("tiiuae/falcon-7b-instruct", prompt);
    res.json({ reply: result, language });
  } catch (err) {
    res.status(500).json({ error: "Chatbot failed", details: err.message });
  }
});

// Socket.IO for real-time chat
io.on("connection", (socket) => {
  console.log("Client connected");

  socket.on("chat message", async (data) => {
    try {
      const { message, language = "zulu" } = data;
      
      let prompt;
      if (language === "english") {
        prompt = message; // Respond naturally in English
      } else {
        prompt = `Respond in isiZulu: ${message}`; // Respond in isiZulu
      }

      const result = await callHuggingFaceAPI("tiiuae/falcon-7b-instruct", prompt);
      socket.emit("bot reply", { reply: result, language });
    } catch {
      socket.emit("bot error", "Error processing request.");
    }
  });

  socket.on("disconnect", () => console.log("Client disconnected"));
});

// -------------------- Server --------------------
const PORT = process.env.PORT || 3000;

if (!process.env.HUGGING_FACE_API_KEY) console.warn("⚠️ HUGGING_FACE_API_KEY missing");
if (!process.env.SUPABASE_URL || !process.env.SUPABASE_URL) console.warn("⚠️ Supabase credentials missing");

server.listen(PORT, async () => {
  console.log(`✅ Server running on port ${PORT}`);
  // Test Supabase connection when server starts
  await testSupabaseConnection();
});
