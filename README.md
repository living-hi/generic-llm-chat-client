# Generic LLM Chat Client

[English](#generic-llm-chat-client) | [中文](#通用大模型聊天客户端)

A small Windows command-line chat client for OpenAI-compatible `chat/completions` APIs.

It can talk to different model providers by changing the endpoint, model name, API key environment variable, and authorization header.

By default it uses DeepSeek, so no config file is required for the first run.

## Files

- `LLMChat.ps1` - main PowerShell client
- `LLMChat.bat` - double-click friendly Windows launcher
- `llm-chat.config.example.json` - optional advanced configuration example

## Quick Start

### Easiest: double-click

1. Double-click `LLMChat.bat`.
2. Paste your DeepSeek API key when prompted.
3. Start chatting.

The pasted key is only used for the current session.

### Optional: save the key for future runs

Save your DeepSeek API key as a user environment variable:

```powershell
[Environment]::SetEnvironmentVariable("DEEPSEEK_API_KEY", "your-api-key", "User")
```

Close and reopen PowerShell, then run:

```powershell
.\LLMChat.ps1
```

You can also pass the key for one run:

```powershell
.\LLMChat.ps1 -ApiKey "your-api-key"
```

## Optional Config

You do not need a config file for DeepSeek. The default settings are already built into `LLMChat.ps1`.

Use a config file only if you want to make another provider the default. Copy `llm-chat.config.example.json` to `llm-chat.config.json`, then edit it.

Do not commit `llm-chat.config.json` if it contains private endpoints or sensitive defaults. Never put API keys in config files.

## Examples

### OpenAI

```powershell
.\LLMChat.ps1 `
  -ProviderName "OpenAI" `
  -Endpoint "https://api.openai.com/v1/chat/completions" `
  -Model "gpt-4.1" `
  -ApiKeyEnv "OPENAI_API_KEY"
```

### DeepSeek

```powershell
.\LLMChat.ps1 `
  -ProviderName "DeepSeek" `
  -Endpoint "https://api.deepseek.com/chat/completions" `
  -Model "deepseek-v4-pro" `
  -ApiKeyEnv "DEEPSEEK_API_KEY"
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

[English](#generic-llm-chat-client) | [中文](#通用大模型聊天客户端)

这是一个轻量级 Windows 命令行聊天客户端，适用于兼容 OpenAI `chat/completions` 格式的大模型 API。

你可以通过修改接口地址、模型名称、API Key 环境变量和鉴权请求头，切换到不同的大模型服务商。

默认使用 DeepSeek，第一次运行不需要创建或改名任何配置文件。

## 文件说明

- `LLMChat.ps1` - 主要的 PowerShell 聊天客户端
- `LLMChat.bat` - 适合双击运行的 Windows 启动脚本
- `llm-chat.config.example.json` - 可选的高级配置示例

## 快速开始

### 最简单：直接双击

1. 双击 `LLMChat.bat`。
2. 按提示粘贴你的 DeepSeek API Key。
3. 开始聊天。

粘贴的 Key 只在本次运行中使用，不会写入文件。

### 可选：保存 Key，以后不用每次粘贴

把 DeepSeek API Key 保存为用户环境变量：

```powershell
[Environment]::SetEnvironmentVariable("DEEPSEEK_API_KEY", "your-api-key", "User")
```

关闭并重新打开 PowerShell，然后运行：

```powershell
.\LLMChat.ps1
```

也可以只在本次运行时传入：

```powershell
.\LLMChat.ps1 -ApiKey "your-api-key"
```

## 可选配置

使用 DeepSeek 时不需要配置文件，脚本里已经内置了默认配置。

只有当你想把其他服务商设为默认值时，才需要复制配置示例：

```powershell
Copy-Item .\llm-chat.config.example.json .\llm-chat.config.json
```

然后按你的服务商修改 `llm-chat.config.json`。

注意：不要把 API Key 写进配置文件，也不要把包含私有接口或敏感默认值的 `llm-chat.config.json` 提交到 GitHub。

## 使用示例

### OpenAI

```powershell
.\LLMChat.ps1 `
  -ProviderName "OpenAI" `
  -Endpoint "https://api.openai.com/v1/chat/completions" `
  -Model "gpt-4.1" `
  -ApiKeyEnv "OPENAI_API_KEY"
```

### DeepSeek

```powershell
.\LLMChat.ps1 `
  -ProviderName "DeepSeek" `
  -Endpoint "https://api.deepseek.com/chat/completions" `
  -Model "deepseek-v4-pro" `
  -ApiKeyEnv "DEEPSEEK_API_KEY"
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
