# Capítulo 08 - Persistência de Dados e Multi-Tenancy com Dext Entity ORM

Este projeto demonstra a utilização do **Dext Entity ORM** com suporte nativo a banco SQLite em memória, mapeamento Naming Convention (Snake Case), ciclo de vida do `DbContext` e **isolamento estrito de Multi-Tenancy**.

## Como Executar

```powershell
.\EntityApp.exe
```

## Recursos Demonstrados no Código

1. **Criador de Estrutura Automático (`EnsureCreated`)**: Inicializa o schema da tabela `customers` em memória.
2. **Gerenciamento de Entidades e UUID v7**: Utiliza identificador UUID v7 sequencial para ordenação temporal de execuções.
3. **Isolamento por Tenant no Nível do ORM (`DbSet.Where`)**:
   - Persiste registros de múltiplos *tenants* / empresas clientes (`tenant-alpha` e `tenant-beta`).
   - Constrói a árvore de expressão AST via `DbSet.Where(TProp<string>.Create('TenantId') = 'tenant-alpha')`, garantindo que o filtro SQL `WHERE tenant_id = 'tenant-alpha'` seja executado diretamente no banco de dados **antes** da materialização dos objetos.
