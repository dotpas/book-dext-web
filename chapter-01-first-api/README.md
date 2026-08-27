# Capítulo 01: Primeira API Mínima Dext

Este projeto demonstra a criação e execução da primeira API mínima com o Dext Framework.

## Estrutura
- `Chapter01_FirstAPI.dpr`: Aplicação console Delphi que mapeia o endpoint `GET /`.
- `requests.http`: Requisição de smoke test para a extensão REST Client.
- `Test.Chapter01_FirstAPI.ps1`: Script de verificação automatizada.

## Execução
Compile o projeto na IDE (ou com o compilador Delphi) e execute `Chapter01_FirstAPI.exe`. O servidor escuta em `http://localhost:8080/`.

```powershell
powershell -ExecutionPolicy Bypass -File .\Test.Chapter01_FirstAPI.ps1
```
