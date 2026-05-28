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

---

# 通用大模型聊天客户端

这是一个轻量级 Windows 命令行聊天客户端，适用于兼容 OpenAI `chat/completions` 格式的大模型 API。

你可以通过修改接口地址、模型名称、API Key 环境变量和鉴权请求头，切换到不同的大模型服务商。

## 文件说明

- `LLMChat.ps1` - 主要的 PowerShell 聊天客户端
- `LLMChat.bat` - 适合双击运行的 Windows 启动脚本
- `llm-chat.config.example.json` - 本地配置文件示例

## 快速开始

先把 API Key 放到环境变量里：

```powershell
$env:OPENAI_API_KEY = "your-api-key"
```

运行客户端：

```powershell
.\LLMChat.ps1 -ProviderName "OpenAI" -Endpoint "https://api.openai.com/v1/chat/completions" -Model "gpt-4.1" -ApiKeyEnv "OPENAI_API_KEY"
```

如果你已经创建了 `llm-chat.config.json`，也可以直接双击 `LLMChat.bat` 启动。

## 本地配置

复制配置示例：

```powershell
Copy-Item .\llm-chat.config.example.json .\llm-chat.config.json
```

然后按你的服务商修改 `llm-chat.config.json`。

注意：不要把 API Key 写进配置文件，也不要把包含私有接口或敏感默认值的 `llm-chat.config.json` 提交到 GitHub。

## 使用示例

### 九天

```powershell
.\LLMChat.ps1 `
  -ProviderName "Jiutian" `
  -Endpoint "https://jiutian.10086.cn/largemodel/moma/api/v3/chat/completions" `
  -Model "jiutian/jiutian-lan-35b" `
  -ApiKeyEnv "JIUTIAN_API_KEY"
```

### 本地 OpenAI 兼容服务

例如 Ollama、LM Studio 或其他本地网关，只要提供兼容的 `/v1/chat/completions` 接口即可：

```powershell
.\LLMChat.ps1 `
  -ProviderName "Local" `
  -Endpoint "http://localhost:11434/v1/chat/completions" `
  -Model "qwen2.5:7b" `
  -AuthHeaderName "none"
```

## 聊天内命令

- `:exit` - 退出
- `:clear` - 清空当前上下文
- `:model` - 查看或切换模型
- `:endpoint` - 查看或切换 API 地址
- `:keyenv` - 查看或切换 API Key 环境变量名称
- `:config` - 查看当前非敏感配置
- `:help` - 查看帮助

## 支持的接口格式

客户端发送的请求格式类似：

```json
{
  "model": "model-name",
  "messages": [
    { "role": "user", "content": "hello" }
  ]
}
```

并默认从 `choices[0].message.content` 读取模型回复。

## 安全建议

- 推荐使用环境变量保存 API Key。
- 不要把真实 API Key 写入脚本、README 或配置文件。
- 发布到 GitHub 前，确认只提交 `llm-chat.config.example.json`，不要提交自己的 `llm-chat.config.json`。
