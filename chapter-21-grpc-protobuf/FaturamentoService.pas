unit FaturamentoService;

interface

uses
  System.SysUtils,
  Dext.Grpc.Attributes,
  Dext.Serialization.Protobuf;

type
  [GrpcMessage]
  TCalculateInvoiceRequest = class
  private
    FCustomerId: Int64;
    FCurrency: string;
  public
    [ProtoMember(1)]
    property CustomerId: Int64 read FCustomerId write FCustomerId;
    [ProtoMember(2)]
    property Currency: string read FCurrency write FCurrency;
  end;

  [GrpcMessage]
  TInvoiceResponse = class
  private
    FInvoiceId: string;
    FCustomerId: Int64;
    FTotalAmount: Double;
  public
    [ProtoMember(1)]
    property InvoiceId: string read FInvoiceId write FInvoiceId;
    [ProtoMember(2)]
    property CustomerId: Int64 read FCustomerId write FCustomerId;
    [ProtoMember(3)]
    property TotalAmount: Double read FTotalAmount write FTotalAmount;
  end;

  [GrpcService('dext.faturamento.v1.FaturamentoService')]
  IFaturamentoGrpcService = interface(IInvokable)
    ['{F47B2C10-8A9B-4D7E-8F12-3456789ABCDE}']
    [GrpcMethod('CalculateInvoice')]
    function CalculateInvoice(const Req: TCalculateInvoiceRequest): TInvoiceResponse;
  end;

  TFaturamentoGrpcService = class(TInterfacedObject, IFaturamentoGrpcService)
  public
    function CalculateInvoice(const Req: TCalculateInvoiceRequest): TInvoiceResponse;
  end;

implementation

function TFaturamentoGrpcService.CalculateInvoice(
  const Req: TCalculateInvoiceRequest): TInvoiceResponse;
begin
  Result := TInvoiceResponse.Create;
  Result.InvoiceId := 'INV-998877';
  Result.CustomerId := Req.CustomerId;
  Result.TotalAmount := 250.75;
end;

end.
