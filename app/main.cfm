<cfscript>
// Stage 1: read prompt, call OpenRouter chat/completions, print assistant message to stdout
sys = createObject("java", "java.lang.System");
envPrompt = sys.getenv("PROMPT");
prompt = trim(isNull(envPrompt) ? "" : envPrompt);
if (!len(prompt) && structKeyExists(url, "1")) prompt = trim(url["1"]);
envBase = sys.getenv("OPENROUTER_BASE_URL");
baseUrl = trim(isNull(envBase) ? "https://openrouter.ai/api/v1" : envBase);
envKey = sys.getenv("OPENROUTER_API_KEY");
apiKey = trim(isNull(envKey) ? "" : envKey);

if (!len(apiKey)) {
  systemErr = createObject("java", "java.lang.System").err;
  systemErr.println("Error: OPENROUTER_API_KEY is not set");
  createObject("java", "java.lang.System").exit(1);
}
if (!len(prompt)) {
  systemErr = createObject("java", "java.lang.System").err;
  systemErr.println('Error: No prompt provided (set PROMPT or pass -p "prompt")');
  createObject("java", "java.lang.System").exit(1);
}

payload = serializeJSON({
  "model" = "anthropic/claude-haiku-4.5",
  "max_tokens" = 4096,
  "messages" = [ { "role" = "user", "content" = prompt } ]
});

cfhttp(method = "POST", url = baseUrl & "/chat/completions", result = "httpResult") {
  cfhttpparam(type = "header", name = "Authorization", value = "Bearer " & apiKey);
  cfhttpparam(type = "header", name = "Content-Type", value = "application/json");
  cfhttpparam(type = "body", value = payload);
}

if (left(httpResult.statusCode, 1) != "2") {
  systemErr = createObject("java", "java.lang.System").err;
  sc = isNull(httpResult.statusCode) ? "unknown" : httpResult.statusCode;
  fc = isNull(httpResult.fileContent) ? "" : httpResult.fileContent;
  systemErr.println("Error: OpenRouter request failed: " & sc & " " & fc);
  createObject("java", "java.lang.System").exit(1);
}

try {
  data = deserializeJSON(httpResult.fileContent);
} catch (any e) {
  systemErr = createObject("java", "java.lang.System").err;
  systemErr.println("Error: Invalid JSON response");
  createObject("java", "java.lang.System").exit(1);
}

if (!structKeyExists(data, "choices") || !arrayLen(data.choices)) {
  systemErr = createObject("java", "java.lang.System").err;
  systemErr.println("Error: No choices in response");
  createObject("java", "java.lang.System").exit(1);
}

message = structKeyExists(data.choices[1], "message") ? data.choices[1].message : {};
content = structKeyExists(message, "content") ? message.content : "";
writeOutput(content);
</cfscript>
