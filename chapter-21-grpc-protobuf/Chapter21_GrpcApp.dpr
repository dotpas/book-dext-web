program Chapter21_GrpcApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Web,
  Dext.Web.Interfaces,
  Dext.Web.Grpc.Server,
  Dext.Grpc.Attributes,
  Dext.Serialization.Protobuf,
  FaturamentoService in 'FaturamentoService.pas';

procedure TestGrpcDispatcherAndExecution;
var
  Dispatcher: TDextGrpcDispatcher;
  Svc: IFaturamentoGrpcService;
  Req, DeserializedReq: TCalculateInvoiceRequest;
  Res: TInvoiceResponse;
  ProtoBytes: TBytes;
begin
  Writeln('====================================================');
  Writeln('  Dext gRPC & Protobuf Executable Demo - Cap 12    ');
  Writeln('====================================================');

  // 1. Registrar servico no Dispatcher gRPC do Dext
  Dispatcher := TDextGrpcDispatcher.Create;
  try
    Dispatcher.RegisterService(IFaturamentoGrpcService, TFaturamentoGrpcService);
    Writeln('[1] Servico IFaturamentoGrpcService registrado no Dispatcher gRPC.');

    Req := TCalculateInvoiceRequest.Create;
    try
      Req.CustomerId := 9901;
      Req.Currency := 'BRL';

      // 2. Demonstrar serializacao binaria Protocol Buffers nativa
      ProtoBytes := TProtobufSerializer.Serialize(Req);
      Writeln(Format('[2] Requisicao gRPC serializada em Protocol Buffers binario (%d bytes).', [Length(ProtoBytes)]));

      DeserializedReq := TCalculateInvoiceRequest.Create;
      try
        TProtobufSerializer.Deserialize(ProtoBytes, DeserializedReq);
        Writeln(Format('    [PROTOBUF] Payload deserializado -> CustomerId: %d, Currency: %s',
          [DeserializedReq.CustomerId, DeserializedReq.Currency]));

        // 3. Executar chamada da RPC gRPC via Servico Registrado usando a requisição desserializada
        Writeln(Format('[3] Invocando RPC CalculateInvoice (CustomerId: %d, Currency: %s)...',
          [DeserializedReq.CustomerId, DeserializedReq.Currency]));

        Svc := TFaturamentoGrpcService.Create;
        Res := Svc.CalculateInvoice(DeserializedReq);
        try
          // 4. Testar round-trip de serializacao Protobuf da Resposta
          var ResProtoBytes := TProtobufSerializer.Serialize(Res);
          Writeln(Format('[4] Resposta gRPC serializada em Protocol Buffers (%d bytes).', [Length(ResProtoBytes)]));

          var RoundTripRes := TInvoiceResponse.Create;
          try
            TProtobufSerializer.Deserialize(ResProtoBytes, RoundTripRes);
            Writeln('[5] Resposta gRPC Protobuf deserializada com sucesso:');
            Writeln('    - InvoiceId: ', RoundTripRes.InvoiceId);
            Writeln('    - CustomerId: ', RoundTripRes.CustomerId);
            Writeln('    - TotalAmount: R$ ', FormatFloat('0.00', RoundTripRes.TotalAmount));

            if (RoundTripRes.InvoiceId <> '') and (RoundTripRes.CustomerId = 9901) then
              Writeln('[SUCESSO] Registro do servico gRPC, contrato Protobuf, invocacao da RPC e round-trip de serializacao binaria validados com exito!')
            else
              Writeln('[FALHA] Resposta gRPC com dados incorretos.');
          finally
            RoundTripRes.Free;
          end;
        finally
          Res.Free;
        end;
      finally
        DeserializedReq.Free;
      end;
    finally
      Req.Free;
    end;
  finally
    Dispatcher.Free;
  end;
end;

begin
  try
    TestGrpcDispatcherAndExecution;
  except
    on E: Exception do
      Writeln('[ERRO gRPC]: ', E.Message);
  end;
end.
