# Capítulo 10: Autenticação, Autorização e Gestão de Identidade

Demonstração prática de segurança web com Dext Framework: carregamento de segredos via `appsettings.yaml`, emissão de Tokens JWT (`/api/v1/auth/login`), middleware de autenticação e proteção de rotas exercitando HTTP **200 OK**, **401 Unauthorized** e **403 Forbidden**.

## Conteúdo do Exemplo
- `SecurityApp.dpr`: Servidor HTTP com rotas de login e proteção RBAC (Role-Based Access Control).
- `appsettings.yaml`: Configurações de chave secreta JWT, Issuer e Audience.
- `requests.http`: Arquivo de teste com chamadas HTTP simulando acessos com e sem permissão.

## Como Compilar e Executar
```powershell
dcc64 -B -IC:\dev\Dext\DextRepository\Sources -UC:\dev\Dext\DextRepository\Sources SecurityApp.dpr
.\SecurityApp.exe
```

## Respostas HTTP Exercitadas
1. **HTTP 401 Unauthorized**: Tentar acessar `/api/v1/protected/user` sem o cabeçalho `Authorization: Bearer <token>`.
2. **HTTP 403 Forbidden**: Tentar acessar `/api/v1/protected/admin` com um token de usuário comum (`user=operador`).
3. **HTTP 200 OK**: Acessar `/api/v1/protected/admin` com token de administrador (`user=admin`).
