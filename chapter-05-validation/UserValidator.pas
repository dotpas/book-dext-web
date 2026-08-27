unit UserValidator;

interface

uses
  System.SysUtils,
  System.Rtti,
  Dext.Validation;

type
  /// <summary>
  ///   DTO com Validação Declarativa básica via Atributos (Zero-Boilerplate).
  /// </summary>
  TCustomerDto = class
  private
    FName: string;
    FEmail: string;
    FAge: Integer;
    FDocumentType: string;
    FDocumentNumber: string;
    FDiscountPercent: Double;
  public
    [Required, StringLength(3, 100)]
    property Name: string read FName write FName;

    [Required, EmailAddress]
    property Email: string read FEmail write FEmail;

    [Range(18, 120)]
    property Age: Integer read FAge write FAge;

    [Required]
    property DocumentType: string read FDocumentType write FDocumentType;

    property DocumentNumber: string read FDocumentNumber write FDocumentNumber;

    [Range(0.0, 100.0)]
    property DiscountPercent: Double read FDiscountPercent write FDiscountPercent;
  end;

  /// <summary>
  ///   Validador Fluente para Regras Condicionais e Validação Cruzada.
  /// </summary>
  TCustomerDtoValidator = class(TAbstractValidator<TCustomerDto>)
  public
    constructor Create; override;
  end;

  // Alias de compatibilidade
  TUserDto = TCustomerDto;
  TUserDtoValidator = TCustomerDtoValidator;

implementation

constructor TCustomerDtoValidator.Create;
begin
  inherited Create;

  // Regras condicionais: se PJ, CNPJ deve ter 14 dígitos; se PF, CPF deve ter 11
  RuleFor('DocumentNumber')
    .Required
    .Length(14, 14)
    .When(function(C: TCustomerDto): Boolean
      begin
        Result := (C <> nil) and (SameText(C.DocumentType, 'PJ'));
      end)
    .WithMessage('CNPJ para Pessoa Juridica deve conter 14 digitos.');

  RuleFor('DocumentNumber')
    .Required
    .Length(11, 11)
    .When(function(C: TCustomerDto): Boolean
      begin
        Result := (C <> nil) and (SameText(C.DocumentType, 'PF'));
      end)
    .WithMessage('CPF para Pessoa Fisica deve conter 11 digitos.');

  // Validação cruzada: clientes menores de 21 anos não podem ter desconto > 10%
  RuleFor('DiscountPercent')
    .Must(function(C: TCustomerDto; Val: TValue): Boolean
      begin
        if (C = nil) or (C.Age >= 21) then
          Exit(True);
        Result := C.DiscountPercent <= 10.0;
      end)
    .WithMessage('Desconto maximo para clientes com menos de 21 anos e 10%.');
end;

end.
