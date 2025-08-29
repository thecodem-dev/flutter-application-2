# Backend Setup

## Environment Variables

Create a `.env` file in the backend directory with the following variables:

```env
# Supabase Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_KEY=your_supabase_project_api_key

# Hugging Face API Configuration
HUGGING_FACE_API_KEY=your_hugging_face_api_key

# Server Configuration (optional)
PORT=3000
```

## Testing Supabase Connection

To test the Supabase connection, run:

```bash
node test-supabase.js
```

## Running the Server

To start the server, run:

```bash
npm start
```

Or for development with auto-restart:

```bash
npm run dev
