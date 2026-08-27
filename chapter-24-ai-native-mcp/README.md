# Capítulo 24 - APIs AI-Native e Servidor MCP (Model Context Protocol)

Este projeto demonstra a infraestrutura do **Model Context Protocol (MCP)** nativo no Dext Framework para integração com assistentes de IA (Claude, Codex, Antigravity).

## Como Executar

```powershell
$env:DEXT_MCP_AGENT_TOKEN = "obtenha-este-valor-do-seu-secret-store"
.\McpServerApp.exe
```

## Recursos Demonstrados no Código

1. **Registro de Provider com Atributos (`[MCPTool]`)**: Mapeia métodos de classes Delphi como ferramentas disponíveis para assistentes de IA.
2. **Descoberta de Ferramentas e Schemas JSON**: Valida a busca no registro (`Server.Registry.TryGetTool`) e a geração de schemas JSON (`Server.Registry.BuildToolsArray`).
3. **Execução pelo Registry**: Exercita `ToolDef.ResultCallback` com cenário negado e permitido. O secret precisa ser fornecido externamente por `DEXT_MCP_AGENT_TOKEN`; não existe fallback no código.
4. **Modo Servidor e Transposta MCP (`TMCPServer.Run`)**: Em servidores de produção, o método `Server.Run(mtStreamable)` ou `Server.Run(mtStdio)` inicializa o transporte HTTP (`POST /mcp`) ou stdio, realizando a recepção, o parse JSON-RPC 2.0 (`tools/list`, `tools/call`) e o despacho automático para os providers registrados.
