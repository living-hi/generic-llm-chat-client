# Generic LLM Chat Client

A small Windows command-line chat client for OpenAI-compatible `chat/completions` APIs.

It can talk to different model providers by changing the endpoint, model name, API key environment variable, and authorization header.

## Files

- `LLMChat.ps1` - main PowerShell client
- `LLMChat.bat` - double-click friendly Windows launcher
- `llm-chat.config.example.json` - example local configuration

## Quick Start

Set an API key in an environment variable:

```powershell
$env:OPENAI_API_KEY = "your-api-key"
```

Run the client:

```powershell
.\LLMChat.ps1 -ProviderName "OpenAI" -Endpoint "https://api.openai.com/v1/chat/completions" -Model "gpt-4.1" -ApiKeyEnv "OPENAI_API_KEY"
```

Or double-click `LLMChat.bat` after creating `llm-chat.config.json`.

## Local Config

Copy `llm-chat.config.example.json` to `llm-chat.config.json`, then edit it for your provider.

Do not commit `llm-chat.config.json` if it contains private endpoints or sensitive defaults. Never put API keys in config files.

## Examples

### Jiutian

```powershell
.\LLMChat.ps1 `
  -ProviderName "Jiutian" `
  -Endpoint "https://jiutian.10086.cn/largemodel/moma/api/v3/chat/completions" `
  -Model "jiutian/jiutian-lan-35b" `
  -ApiKeyEnv "JIUTIAN_API_KEY"
```

### OpenAI-Compatible Local Server

```powershell
.\LLMChat.ps1 `
  -ProviderName "Local" `
  -Endpoint "http://localhost:11434/v1/chat/completions" `
  -Model "qwen2.5:7b" `
  -AuthHeaderName "none"
```

## In-Chat Commands

- `:exit` - quit
- `:clear` - clear conversation context
- `:model` - view or change model
- `:endpoint` - view or change API endpoint
- `:keyenv` - view or change API key environment variable names
- `:config` - show current non-secret configuration
- `:help` - show commands

## Notes

This client targets APIs that accept this request shape:

```json
{
  "model": "model-name",
  "messages": [
    { "role": "user", "content": "hello" }
  ]
}
```

And return an assistant message at `choices[0].message.content`.
