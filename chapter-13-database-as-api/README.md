# Capítulo 09: Hiper-Produtividade - O Padrão Database-as-API

Demonstração prática do padrão **Data API** do Dext Framework, expondo automaticamente entidades de banco de dados (`TCustomer`) como rotas REST completas sem necessidade de controllers ou DTOs manuais.

## Conteúdo do Exemplo
- `DataApiApp.dpr`: Servidor Web que inicializa `TAppDataContext` com SQLite, executa o `SeedDatabase` com dados iniciais e mapeia `/api/v1/customers`.
- `requests.http`: Arquivo de requisições HTTP para testar listagem, busca por ID e cadastro de novos clientes.

## Como Compilar e Executar
```powershell
dcc64 -B -IC:\dev\Dext\DextRepository\Sources -UC:\dev\Dext\DextRepository\Sources DataApiApp.dpr
.\DataApiApp.exe
```

## Como Testar os Endpoints
Envie uma requisição GET para `http://localhost:8080/api/v1/customers` utilizando o arquivo `requests.http` no VS Code/Antigravity ou cURL:
```bash
curl http://localhost:8080/api/v1/customers
```
