program Chapter05_ValidationApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Validation,
  UserValidator;

procedure DemoValidation;
var
  Dto: TCustomerDto;
  Validator: TCustomerDtoValidator;
  AttrResult, FluentResult: TValidationResult;
  Err: TValidationError;
begin
  Writeln('====================================================');
  Writeln('      Dext Framework - Validation Demo (Cap. 05)    ');
  Writeln('====================================================');

  Dto := TCustomerDto.Create;
  try
    // Preenche com dados com problemas sintáticos e de negócio
    Dto.Name := 'Jo';                  // Erro atributo: tamanho mínimo 3
    Dto.Email := 'email_invalido';     // Erro atributo: formato de e-mail inválido
    Dto.Age := 19;                     // Válido por atributo (18..120)
    Dto.DocumentType := 'PJ';          // Pessoa Jurídica
    Dto.DocumentNumber := '12345678';  // Erro fluente: PJ exige 14 dígitos (não 8)
    Dto.DiscountPercent := 15.0;       // Erro fluente: idade < 21 anos permite max 10%

    // -------------------------------------------------------------------------
    // 1. Validação Declarativa Direta por Atributos (Zero Boilerplate)
    // -------------------------------------------------------------------------
    Writeln('[1] Executando Validacao Declarativa por Atributos (TValidator)...');
    AttrResult := TValidator.Validate(Dto);
    try
      Writeln('  - Valido por Atributos? ', AttrResult.IsValid);
      if not AttrResult.IsValid then
      begin
        Writeln('  - Erros capturados via Atributos [Required/StringLength/EmailAddress]:');
        for Err in AttrResult.Errors do
          Writeln('    * [', Err.FieldName, ']: ', Err.ErrorMessage);
      end;
    finally
      AttrResult.Free;
    end;

    // -------------------------------------------------------------------------
    // 2. Validação Fluente para Regras Condicionais e Cruzadas
    // -------------------------------------------------------------------------
    Writeln;
    Writeln('[2] Executando Validacao Fluente Avancada (TAbstractValidator)...');
    Validator := TCustomerDtoValidator.Create;
    try
      FluentResult := Validator.Validate(Dto);
      try
        Writeln('  - Valido por Regras Fluentes? ', FluentResult.IsValid);
        if not FluentResult.IsValid then
        begin
          Writeln('  - Erros capturados via Regras Fluentes (When / Must):');
          for Err in FluentResult.Errors do
            Writeln('    * [', Err.FieldName, ']: ', Err.ErrorMessage);
        end;
      finally
        FluentResult.Free;
      end;
    finally
      Validator.Free;
    end;

    Writeln;
    Writeln('[SUCCESS] Fail-Fast validation pipeline executed successfully.');
  finally
    Dto.Free;
  end;
end;

begin
  try
    DemoValidation;
  except
    on E: Exception do
      Writeln('Erro: ', E.Message);
  end;
end.
