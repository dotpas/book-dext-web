unit RichInvoiceEntity;

interface

uses
  System.SysUtils,
  Dext.Entity;

type
  [Table('faturas')]
  TRichInvoice = class
  private
    FId: Int64;
    FCustomerId: Int64;
    FAmount: Double;
    FPaidAmount: Double;
    FStatus: string;
  public
    [PK]
    property Id: Int64 read FId write FId;

    [Column('customer_id')]
    property CustomerId: Int64 read FCustomerId write FCustomerId;

    [Column('amount')]
    property Amount: Double read FAmount write FAmount;

    [Column('paid_amount')]
    property PaidAmount: Double read FPaidAmount write FPaidAmount;

    [Column('status')]
    property Status: string read FStatus write FStatus;

    constructor Create; overload;
    constructor Create(const AId, ACustomerId: Int64; const AAmount: Double); overload;
    procedure Liquidate(const AReceived: Double);
    procedure Cancel(const AReason: string);
  end;

implementation

{ TRichInvoice }

constructor TRichInvoice.Create;
begin
  inherited Create;
end;

constructor TRichInvoice.Create(const AId, ACustomerId: Int64; const AAmount: Double);
begin
  inherited Create;
  if ACustomerId <= 0 then
    raise Exception.Create('Cliente invalido.');
  if AAmount <= 0 then
    raise Exception.Create('O valor deve ser positivo.');

  FId := AId;
  FCustomerId := ACustomerId;
  FAmount := AAmount;
  FPaidAmount := 0.0;
  FStatus := 'EMITIDA';
end;

procedure TRichInvoice.Liquidate(const AReceived: Double);
begin
  if FStatus = 'CANCELADA' then
    raise Exception.Create('Fatura cancelada nao pode ser liquidada.');
  if FStatus = 'PAGA' then
    raise Exception.Create('Fatura ja liquidada.');
  if AReceived < FAmount then
    raise Exception.Create('Valor recebido insuficiente.');

  FPaidAmount := AReceived;
  FStatus := 'PAGA';
end;

procedure TRichInvoice.Cancel(const AReason: string);
begin
  if FStatus = 'PAGA' then
    raise Exception.Create('Fatura quitada nao pode ser cancelada.');
  if Trim(AReason) = '' then
    raise Exception.Create('Motivo obrigatorio para cancelamento.');

  FStatus := 'CANCELADA';
end;

end.
