# Capítulo 12 - APIs Binárias com gRPC e Protocol Buffers

Este projeto demonstra a infraestrutura do **gRPC e Protocol Buffers** no Dext Framework utilizando contratos `.proto` e a engine de serialização binária.

## Arquivos Principais

- `proto/faturamento_service.proto`: Contrato de interface e mensagens Protobuf.
- `FaturamentoService.pas`: Implementação das mensagens e da interface `IFaturamentoGrpcService` / `TFaturamentoGrpcService`.
- `GrpcApp.dpr`: Aplicação demonstrativa.

## Recursos Demonstrados no Código

1. **Contrato Protobuf e Atributos gRPC**: Definição de serviços com atributos `[GrpcService]` e `[GrpcMethod]`.
2. **Serialização Binária Protocol Buffers (`TProtobufSerializer`)**: Valida a codificação e decodificação binária das mensagens de requisição e resposta.
3. **Registro no Dispatcher (`TDextGrpcDispatcher`)**: Registra a interface e a implementação no dispatcher gRPC. Em produção no servidor Web Dext, a chamada HTTP/2 `POST /ServiceName/MethodName` é roteada para `TDextGrpcDispatcher.Invoke(Ctx)`, que decodifica o stream Protobuf, invoca a RPC via RTTI e serializa a resposta ao cliente.
