import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.117.2";
const headers = {
 "Access-Control-Allow-Origin": "*",
 "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
 "Access-Control-Allow-Methods": "POST, DELETE, OPTIONS",
 "Content-Type": "application/json",
};
serve(async (req) => {
 const reply = (status: number, body: object) => new Response(JSON.stringify(body), {status, headers});
 if(req.method === "OPTIONS") return new Response("ok", {headers});
 if(!["POST","DELETE"].includes(req.method)) return reply(405,{error:"Method not allowed"});
 const authorization = req.headers.get("Authorization");
 if(!authorization) return reply(401,{error:"Unauthorized"});
 try {
  const url = Deno.env.get("SUPABASE_URL")!;
  const userClient = createClient(url,Deno.env.get("SUPABASE_ANON_KEY")!,{
   global:{headers:{Authorization:authorization}},
   auth:{autoRefreshToken:false,persistSession:false},
  });
  const {data:{user},error} = await userClient.auth.getUser();
  if(error || !user) return reply(401,{error:"Unauthorized"});
  // The RPC checks auth.uid(), deletes only that user's data, and is transactional.
  const {error:cleanupError} = await userClient.rpc("delete_account");
  if(cleanupError) return reply(500,{error:"Failed to delete account data"});
  const admin = createClient(url,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,{
   auth:{autoRefreshToken:false,persistSession:false},
  });
  const {error:authError} = await admin.auth.admin.deleteUser(user.id);
  if(authError) return reply(500,{error:"Failed to delete auth account; retry account deletion"});
  return reply(200,{success:true,message:"Account deleted successfully"});
 } catch {
  return reply(500,{error:"Account deletion unavailable"});
 }
});
