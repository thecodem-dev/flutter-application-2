const { createClient } = require("@supabase/supabase-js");
require("dotenv/config");

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY);

async function test() {
  const { data, error } = await supabase.from("files").select("*");
  if (error) console.error("Error:", error);
  else console.log("Supabase connected! Data:", data);
}

test();
