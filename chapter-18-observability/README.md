# Capítulo 15: Hospedagem, Deploy, WSL Containers e Observabilidade

Demonstração prática de hospedagem de produção, containerização Docker/WSL, verificação de saúde (Kubernetes Probes) e **telemetria RED (Rate, Errors, Duration)** com Dext Framework.

## Conteúdo do Exemplo
- `HostingApp.dpr`: Servidor com configuração YAML, probe SQLite real (`SELECT 1`) com timeout FireDAC, probes HTTP e métricas RED.
- `appsettings.yaml`: Arquivo de configuração de ambiente.
- `Dockerfile`: Imagem Linux Alpine minimalista pronta para conteinerização.

## Como Compilar e Executar no Windows
```powershell
dcc64 -B -IC:\dev\Dext\DextRepository\Sources -UC:\dev\Dext\DextRepository\Sources HostingApp.dpr
.\HostingApp.exe
```

## Como Testar os Endpoints de Observabilidade
```bash
curl http://localhost:8080/health/live
curl http://localhost:8080/health/ready
curl http://localhost:8080/metrics
```

`leak_test.ps1` executa três ciclos de 500 requests, mede Private Bytes e solicita shutdown coordenado por `IWebApplication.Stop`. O resultado demonstra estabilidade na carga executada; para leak detection de release, complemente com FastMM5 FullDebugMode e análise do relatório de shutdown.
