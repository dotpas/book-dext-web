# Projetos e Exemplos Compiláveis (`book/examples`)

Este diretório contém os projetos de código Delphi e scripts de teste associados a cada capítulo do livro **Desenvolvimento Web Profissional com Delphi e Dext Framework** (`book`).

---

## Estrutura dos Projetos

| Capítulo | Diretório | Arquivo do Projeto | Descrição |
| :--- | :--- | :--- | :--- |
| **Cap. 01** | `chapter-01-first-api` | `Chapter01_FirstAPI.dpr` | Servidor HTTP minimalista de alto rendimento. |
| **Cap. 02** | `chapter-02-minimal-apis` | `Chapter02_InvoicesMinimalAPI.dpr` | Minimal APIs, parâmetros de rota, query e Results. |
| **Cap. 03** | `chapter-03-model-binding` | `Chapter03_ModelBindingApp.dpr` | Model Binding multi-fonte, upload real em disco e método QUERY. |
| **Cap. 04** | `chapter-04-http-pipeline` | `Chapter04_MiddlewareApp.dpr` | Pipeline de Middlewares bidirecional e tratamento global de erros. |
| **Cap. 05** | `chapter-05-validation` | `Chapter05_ValidationApp.dpr` | Motor de validação fluente e Problem Details (RFC 9457). |
| **Cap. 06** | `chapter-06-configuration` | `Chapter06_ConfigApp.dpr` | Carregamento de YAML, variáveis de ambiente e IOptions. |
| **Cap. 07** | `chapter-07-controllers` | `Chapter07_ControllerApp.dpr` | Controllers REST e rotas tipadas. |
| **Cap. 08** | `chapter-08-orm-basics` | `Chapter08_OrmBasicsApp.dpr` | Persistência básica, mapeamento relacional e Unit of Work. |
| **Cap. 09** | `chapter-09-smart-properties` | `Chapter09_SmartPropertiesApp.dpr` | Smart Properties, consultas tipo-seguras e AST em Pascal. |
| **Cap. 10** | `chapter-10-specifications` | `Chapter10_SpecificationsApp.dpr` | Specification Pattern e Keyset Pagination. |
| **Cap. 11** | `chapter-11-domain-cqrs` | `Chapter11_DomainCqrsApp.dpr` | Domain Model rico, entidades POCO e CQRS. |
| **Cap. 12** | `chapter-12-multi-tenancy` | `Chapter12_MultiTenancyApp.dpr` | Mapeamento relacional e isolamento multi-tenant com ITenantAware. |
| **Cap. 13** | `chapter-13-database-as-api` | `Chapter13_DataApiApp.dpr` | Database-as-API com governança e allowlist. |
| **Cap. 14** | `chapter-14-auth-jwt` | `Chapter14_SecurityJwtApp.dpr` | Autenticação JWT, BCrypt, RBAC e Security Headers. |
| **Cap. 15** | `chapter-15-authorization` | `Chapter15_AuthorizationApp.dpr` | Autorização baseada em Roles, Claims e Políticas Customizadas. |
| **Cap. 16** | `chapter-16-cache-resilience` | `Chapter16_CacheCapacityApp.dpr` | Cache L1/L2 Redis, compressão dinâmica e Rate Limiting. |
| **Cap. 17** | `chapter-17-resilience` | `Chapter17_ResilienceApp.dpr` | Resiliência assíncrona 202 Accepted, Circuit Breaker e TDextJobs. |
| **Cap. 18** | `chapter-18-observability` | `Chapter18_ObservabilityApp.dpr` | Probes Health Check Kubernetes e métricas Prometheus. |
| **Cap. 19** | `chapter-19-openapi-swagger` | `Chapter19_SwaggerApp.dpr` | Documentação interativa Swagger UI e especificação OpenAPI 3.0. |
| **Cap. 20** | `chapter-20-frontend-ssr-htmx` | `Chapter20_RealtimeApp.dpr` | Renderização SSR com Dext Templates e interatividade HTMX. |
| **Cap. 21** | `chapter-21-grpc-protobuf` | `Chapter21_GrpcApp.dpr` | APIs binárias com gRPC e Protocol Buffers. |
| **Cap. 22** | `chapter-22-automated-testing` | `Chapter22_TestRunnerApp.dpr` | Suíte de testes com o Dext Testing Framework. |
| **Cap. 23** | `chapter-23-docker-runtime` | `Chapter23_DockerRuntimeApp.dpr` | Compilação nativa Linux64, Dockerfile multi-stage e Graceful Shutdown. |
| **Cap. 24** | `chapter-24-ai-native-mcp` | `Chapter24_McpServerApp.dpr` | APIs AI-Native e servidor Model Context Protocol (MCP). |
| **Lab. 01** | `lab-01-customers-api` | `Lab01_CustomersApi.dpr` | Microsserviço de Clientes completo com validação fluente. |
| **Lab. 02** | `lab-02-persistence-faturamento` | `Lab02_PersistenceFaturamento.dpr` | Persistência de faturamento, Smart Properties e Keyset. |
| **Lab. 03** | `lab-03-secure-multitenant` | `Lab03_SecureMultiTenant.dpr` | Núcleo corporativo seguro multi-tenant com CQRS e JWT. |
| **Lab. 04** | `lab-04-docker-microservice` | `Lab04_DockerMicroservice.dpr` | Microsserviço observável conteinerizado em Docker com OpenAPI. |
| **Lab. 05** | `lab-05-enterprise-final` | `Lab05_EnterpriseFinal.dpr` | Aplicação enterprise multi-canal consolidada. |

## Grupo de Projetos Delphi (`DextBookExamples.groupproj`)

Todos os 29 projetos com seus respectivos `.dproj` estão registrados no arquivo unificado:
➡️ **`DextBookExamples.groupproj`** (aberto diretamente no RAD Studio / Delphi IDE).

---

## Como Executar os Testes Automatizados

Cada projeto possui um script PowerShell dedicado de validação de endpoints e execução de testes em seu diretório:
- **`Test.ChapterXX_<NomeProjeto>.ps1`** / **`Test.LabXX_<NomeProjeto>.ps1`**: Executa o binário compilado, envia requisições de validação de endpoints HTTP/gRPC/CLI, testa respostas e limpa o processo em background.

### Automação Centralizada (Raiz de `book/examples`)

- **`compile_all_examples.ps1`**: Compila rigorosamente todos os 29 projetos `.dpr` com o compilador `dcc64.exe` do RAD Studio.
- **`test_all_examples.ps1`**: Executa sequencialmente a suíte inteira de scripts `Test.*.ps1` de todos os 29 projetos e exibe um relatório consolidado.
- **`build_and_test_all_examples.ps1`**: Executa a esteira completa em 2 etapas: compilação estrita de todos os projetos + disparo e validação de testes de todos os 29 projetos.
