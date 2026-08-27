# Capítulo 13 - Frontend Simplificado (SSR, HTMX, Tailwind CSS e WebSockets)

Este projeto demonstra como criar aplicações web interativas com o Dext Framework combinando **Server-Side Rendering (SSR)** parcial via **HTMX** e eventos em tempo real com **WebSockets Hub (`IHubContext`)**.

## Como Executar

1. Configure tokens de demonstração fora do código e execute o servidor:
   ```powershell
   $env:DEXT_DEMO_TENANT_ALPHA_TOKEN = "troque-este-token-alpha"
   $env:DEXT_DEMO_TENANT_BETA_TOKEN = "troque-este-token-beta"
   .\RealtimeApp.exe
   ```
2. Abra o navegador em `http://localhost:8080`.

## Endpoints e Recursos

- `GET /`: Serve a página principal `wwwroot/index.html`.
- `GET /htmx/update-invoice`: Endpoint parcial que retorna fragmento HTML para atualização sem reload via HTMX.
- `POST /api/v1/trigger-notification`: Obtém o singleton `IHubContext` do gerenciador de hubs (`THubExtensions.GetHubContext`) e executa `HubContext.Clients.All.SendAsync('OnNotification', Msg)`, transmitindo eventos broadcast em tempo real para todos os navegadores WebSocket conectados em `/hubs/notifications`.
- `POST /api/v1/trigger-tenant-notification`: Exige `Authorization: Bearer <token>` e resolve o tenant no servidor antes de enviar ao grupo. O middleware de demonstração deve ser substituído por JWT/OIDC e claims assinadas em produção.
