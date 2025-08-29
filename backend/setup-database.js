const { createClient } = require("@supabase/supabase-js");
require("dotenv/config");

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY);

async function setupDatabase() {
  console.log("Testing database connection and table setup...");
  
  // Try to query the files table to see if it exists
  const { data, error } = await supabase.from("files").select("*").limit(1);
  
  if (error) {
    if (error.code === 'PGRST205') {
      console.log("❌ Files table does not exist in the database.");
      console.log("Please create the 'files' table in your Supabase dashboard:");
      console.log("1. Go to https://app.supabase.com/");
      console.log("2. Select your project");
      console.log("3. Go to 'Table Editor'");
      console.log("4. Click 'Create a new table'");
      console.log("5. Name it 'files'");
      console.log("6. Add these columns:");
      console.log("   - id: integer (primary key, auto-increment)");
      console.log("   - filename: text (not null)");
      console.log("   - original_name: text (not null)");
      console.log("   - uploader: text (default: 'Teacher')");
      console.log("   - content_type: text");
      console.log("   - translation: text");
      console.log("   - created_at: timestamp (default: now())");
    } else {
      console.error("Error querying files table:", error);
    }
    return;
  }
  
  console.log("✅ Files table exists and is accessible!");
  console.log("Database connection is working correctly.");
  
  // Test inserting a record
  const { data: insertData, error: insertError } = await supabase
    .from('files')
    .insert([
      {
        filename: 'test-file.txt',
        original_name: 'test-file.txt',
        uploader: 'System',
        content_type: 'text/plain'
      }
    ]);
  
  if (insertError) {
    console.error("Error inserting test record:", insertError);
    return;
  }
  
  console.log("✅ Test record inserted successfully!");
  console.log("Database setup completed successfully!");
}

setupDatabase();
