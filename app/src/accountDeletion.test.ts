/// <reference types="node" />
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { runInNewContext } from "node:vm";
import { transpileModule, ScriptTarget } from "typescript";

function endpoint(slug: string, cleanupError: object | null = null, userError: object | null = null) {
  const user = { auth: { getUser: jest.fn(async () => ({
    data: { user: userError ? null : { id: "verified-owner" } }, error: userError,
  })) }, rpc: jest.fn(async () => ({ error: cleanupError })) };
  const admin = { auth: { admin: { deleteUser: jest.fn(async () => ({ error: null })) } } };
  const createClient = jest.fn()
    .mockReturnValueOnce(user).mockReturnValueOnce(admin);
  let handler!: (req: Request) => Promise<Response>;
  const source = readFileSync(resolve(__dirname, "../../supabase/functions", slug, "index.ts"), "utf8")
    .replace(/^import .*;$/gm, "");
  const compiled = transpileModule(source, { compilerOptions: { target: ScriptTarget.ES2022 } }).outputText;
  runInNewContext(compiled, {
    serve: (callback: typeof handler) => { handler = callback; },
    createClient, Deno: { env: { get: () => "test-only" } }, Response,
  });
  return { handler, user, admin, createClient };
}

for (const slug of ["delete-account", "delete-user"]) {
  test(slug + " rejects unauthenticated requests without database access", async () => {
    const {handler, createClient} = endpoint(slug);
    expect((await handler(new Request("https://test.local", {method:"POST"}))).status).toBe(401);
    expect(createClient).not.toHaveBeenCalled();
  });
  test(slug + " stops before auth deletion when SQL cleanup fails", async () => {
    const {handler, admin} = endpoint(slug, {message:"failed"});
    expect((await handler(new Request("https://test.local", {
      method:"POST", headers:{Authorization:"Bearer test-only"},
    }))).status).toBe(500);
    expect(admin.auth.admin.deleteUser).not.toHaveBeenCalled();
  });
  test(slug + " deletes only verified identity and ignores supplied user ID", async () => {
    const {handler, user, admin} = endpoint(slug);
    expect((await handler(new Request("https://test.local", {
      method:"POST", headers:{Authorization:"Bearer test-only"},
      body:JSON.stringify({user_id:"someone-else"}),
    }))).status).toBe(200);
    expect(user.rpc).toHaveBeenCalledWith("delete_account");
    expect(admin.auth.admin.deleteUser).toHaveBeenCalledWith("verified-owner");
  });
}
