import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import { mkdtempSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { join } from "node:path";

const [out, version] = process.argv.slice(2);
const cli = join(out, "bin/rea");
const root = join(out, "lib/node_modules/rea-agents");
const require = createRequire(join(root, "package.json"));
const timeout = 30_000;
const protocolVersion = "2024-11-05";

function run(args) {
  const result = spawnSync(cli, args, { encoding: "utf8", timeout });
  assert.equal(result.status, 0, result.stderr || result.error?.message);
  return result.stdout;
}

assert.equal(run(["--version"]).trim(), version);
assert.ok(run(["--help"]).includes("analyze-javascript-application"));

// Static analysis must work without an external analysis provider.
const fixture = mkdtempSync(join(process.env.TMPDIR, "rea-fixture-"));
writeFileSync(join(fixture, "package.json"), JSON.stringify({ name: "fixture", main: "index.js" }));
writeFileSync(join(fixture, "index.js"), 'module.exports = "rea-fixture";\n');
const evidence = JSON.parse(run(["analyze-javascript-application", fixture, "--json"]));
assert.ok(JSON.stringify(evidence).includes("index.js"));

// Load the native PTY addon to detect missing runtime libraries.
assert.equal(typeof require("@lydell/node-pty").spawn, "function");

// Initialize the stdio server without agent registration or provider setup.
const server = spawn(cli, ["mcp"], { env: process.env });
let output = "";
let errors = "";
server.stderr.on("data", (data) => { errors += data; });
const timer = setTimeout(() => server.kill("SIGKILL"), timeout);
try {
  const response = await new Promise((resolve, reject) => {
    server.on("error", reject);
    server.on("exit", (code) => reject(new Error(`MCP exited: ${code}: ${errors}`)));
    server.stdout.on("data", (data) => {
      output += data;
      const line = output.split("\n").find((value) => value.trim());
      if (output.includes("\n") && line) resolve(JSON.parse(line));
    });
    server.stdin.write(JSON.stringify({
      jsonrpc: "2.0",
      id: 1,
      method: "initialize",
      params: {
        protocolVersion,
        capabilities: {},
        clientInfo: { name: "nix-install-check", version: "1.0.0" },
      },
    }) + "\n");
  });
  assert.equal(response.id, 1);
  assert.ok(response.result.serverInfo);
} finally {
  clearTimeout(timer);
  server.kill();
}
