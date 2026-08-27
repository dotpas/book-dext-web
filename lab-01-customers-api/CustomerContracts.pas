unit CustomerContracts;

interface

uses
  Dext.Validation,
  Dext.Web.ModelBinding;

type
  /// <summary>
  ///   DTO de Entrada: Criação de Cliente com Validação Declarativa.
  /// </summary>
  TCustomerCreateDto = class
  private
    FName: string;
    FEmail: string;
    FDocumentNumber: string;
    FCreditLimit: Currency;
  public
    [Required, StringLength(3, 80)]
    property Name: string read FName write FName;

    [Required, EmailAddress]
    property Email: string read FEmail write FEmail;

    [Required, StringLength(11, 14)]
    property DocumentNumber: string read FDocumentNumber write FDocumentNumber;

    [Range(0.01, 1000000.0)]
    property CreditLimit: Currency read FCreditLimit write FCreditLimit;
  end;

  /// <summary>
  ///   DTO de Consulta com Binding Multi-Fonte (Header + Query).
  /// </summary>
  TCustomerQueryDto = record
    [FromHeader('X-Tenant-ID')]
    TenantId: string;

    [FromQuery('status')]
    Status: string;

    [FromQuery('limite')]
    Limit: Integer;
  end;

implementation

end.
