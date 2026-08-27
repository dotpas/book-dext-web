unit InvoiceContracts;

interface

uses
  Dext.Web.ModelBinding;

type
  /// <summary>
  ///   DTO de Entrada Multi-Fonte: Filtro de faturas por Header, Route e Query.
  /// </summary>
  TFiltroFaturasMultiFonteDto = record
    // 1. Extrai o ID do tenant a partir do header customizado
    [FromHeader('X-Tenant-ID')]
    TenantId: string;

    // 2. Extrai o ID do cliente a partir do segmento de rota
    [FromRoute('clienteId')]
    ClienteId: Integer;

    // 3. Extrai o status da fatura a partir da query string
    [FromQuery('status')]
    Status: string;

    // 4. Extrai o limite maximo de registros (com valor padrao)
    [FromQuery('limite')]
    Limite: Integer;
  end;

  /// <summary>
  ///   DTO de Busca Avancada para o metodo HTTP QUERY (RFC 10008).
  /// </summary>
  TCriteriosBuscaAvancadaDto = record
    CentrosCusto: TArray<string>;
    StatusList: TArray<string>;
    ValorMinimo: Currency;
    ValorMaximo: Currency;
    DataInicio: string;
    DataFim: string;
  end;

implementation

end.
