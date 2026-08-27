unit InvoiceController;

interface

uses
  System.SysUtils,
  Dext.Web,
  Dext.Filters,
  Dext.Filters.BuiltIn;

type
  AuditFaturamentoAttribute = class(ActionFilterAttribute)
  private
    FOperation: string;
  public
    constructor Create(const Operation: string);
    procedure OnActionExecuting(AContext: IActionExecutingContext); override;
    procedure OnActionExecuted(AContext: IActionExecutedContext); override;
  end;

  {$M+}
  [ApiController('/api/v1/faturas')]
  [LogAction]
  TInvoiceController = class
  public
    [HttpGet('')]
    [ResponseCache(30)]
    function ListarFaturas: string;
    
    [HttpGet('/{id}')]
    function ObterPorId(const id: string): string;

    [HttpDelete('/{id}')]
    [AuditFaturamento('CANCELAMENTO_FATURA')]
    function CancelarFatura(const id: string): string;
  end;
  {$M-}

implementation

{ AuditFaturamentoAttribute }

constructor AuditFaturamentoAttribute.Create(const Operation: string);
begin
  inherited Create;
  FOperation := Operation;
end;

procedure AuditFaturamentoAttribute.OnActionExecuting(
  AContext: IActionExecutingContext);
begin
  Writeln(Format('[AUDIT-START] Operacao: %s | Rota: %s', 
    [FOperation, AContext.ActionDescriptor.Route]));
end;

procedure AuditFaturamentoAttribute.OnActionExecuted(
  AContext: IActionExecutedContext);
begin
  if AContext.Exception <> nil then
    Writeln(Format('[AUDIT-FAIL] Falha em %s: %s', 
      [FOperation, AContext.Exception.Message]))
  else
    Writeln(Format('[AUDIT-SUCCESS] Concluida com sucesso: %s', 
      [FOperation]));
end;

{ TInvoiceController }

function TInvoiceController.ListarFaturas: string;
begin
  Result := '[{"id":105,"clienteId":42,"valor":1500.50,"status":"PAGA"},' +
            '{"id":108,"clienteId":42,"valor":3890.00,"status":"PENDENTE"}]';
end;

function TInvoiceController.ObterPorId(const id: string): string;
var
  FaturaId: Integer;
begin
  FaturaId := StrToIntDef(id, 0);
  if FaturaId = 9999 then
    raise Exception.Create('Fatura não encontrada.');
  Result := Format('{"id":%d,"clienteId":42,"valor":1500.50,"status":"PAGA"}',
    [FaturaId]);
end;

function TInvoiceController.CancelarFatura(const id: string): string;
begin
  Result := '{"status":"cancelada"}';
end;

end.
