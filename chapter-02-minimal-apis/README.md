# Capítulo 02: Minimal APIs — Rotas, Parâmetros e Resultados

Este projeto demonstra o CRUD mínimo de faturas com Minimal APIs do Dext: rotas `GET`/`POST`/`DELETE`, parâmetros `{id}`, query string e respostas via `Results` / `IHttpContext`.

## Estrutura
- `Chapter02_InvoicesMinimalAPI.dpr`: Servidor console na porta 8080.
- `Test.Chapter02_InvoicesMinimalAPI.ps1`: Validação automatizada dos endpoints.

## Endpoints
- `GET    /api/v1/faturas/resumo`
- `GET    /api/v1/faturas/{id}`
- `GET    /api/v1/faturas/semantica/{id}`
- `GET    /api/v1/faturas?status=...&limite=...`
- `POST   /api/v1/faturas`
- `DELETE /api/v1/faturas/{id}`

## Execução
Compile e execute `Chapter02_InvoicesMinimalAPI.exe`, depois:

```powershell
powershell -ExecutionPolicy Bypass -File .\Test.Chapter02_InvoicesMinimalAPI.ps1
```
