program Chapter03_ModelBindingApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  Dext.Web,
  Dext.Web.Interfaces,
  Dext.Web.Results,
  Dext.Web.ModelBinding,
  Dext.Json,
  InvoiceContracts in 'InvoiceContracts.pas';

procedure RegisterBindingEndpoints(App: IWebApplication);
begin
  // 1. Endpoint Multi-Fonte (Header + Route + Query)
  App.Builder.MapGet<TFiltroFaturasMultiFonteDto, IResult>(
    '/api/v1/clientes/{clienteId}/faturas',
    function(Filtro: TFiltroFaturasMultiFonteDto): IResult
    begin
      if Filtro.TenantId = '' then
        Exit(Results.BadRequest('O cabecalho X-Tenant-ID e obrigatorio.'));

      if Filtro.ClienteId <= 0 then
        Exit(Results.BadRequest('Identificador de cliente invalido.'));

      if Filtro.Limite <= 0 then
        Filtro.Limite := 20;

      Result := Results.Ok(
        Format('{"tenantId": "%s", "clienteId": %d, "status": "%s", "limite": %d}',
               [Filtro.TenantId, Filtro.ClienteId, Filtro.Status, Filtro.Limite]));
    end);

  // 2. Upload de Arquivos / Comprovantes (Multipart Streaming Real)
  App.Builder.MapPost('/api/v1/faturas/{id}/comprovante',
    procedure(Ctx: IHttpContext)
    const
      MAX_FILE_SIZE = 5242880; // 5 MB em bytes
    var
      Arquivos: IFormFileCollection;
      CaminhoCompleto: string;
      Comprovante: IFormFile;
      DestinoStream: TFileStream;
      IdFatura: Integer;
      NomeArquivoSeguro: string;
      OrigemStream: TStream;
      UploadsDir: string;
    begin
      // Nota didatica: Acesso direto a Ctx.Request para demonstrar controle de baixo nivel,
      // embora um DTO com [FromRoute] tambem seja totalmente suportado pelo Dext.
      IdFatura := StrToIntDef(Ctx.Request.RouteParams['id'], 0);
      if IdFatura <= 0 then
      begin
        Results.Context(Ctx).BadRequest('Identificador de fatura invalido.');
        Exit;
      end;

      Arquivos := Ctx.Request.Files;
      if (Arquivos = nil) or (Arquivos.Count = 0) then
      begin
        Results.Context(Ctx).BadRequest('Nenhum arquivo enviado no payload.');
        Exit;
      end;

      Comprovante := Arquivos[0];

      // Validação de tamanho máximo (5MB)
      if Comprovante.Length > MAX_FILE_SIZE then
      begin
        Results.Context(Ctx).BadRequest('O arquivo excede o limite maximo de 5MB.');
        Exit;
      end;

      // 1. Garante a existência do diretório de uploads
      UploadsDir := '.\uploads';
      if not DirectoryExists(UploadsDir) then
        ForceDirectories(UploadsDir);

      // 2. Sanitiza o nome do arquivo para prevenir Path Traversal
      NomeArquivoSeguro := Format('fatura_%d_%s',
        [IdFatura, ExtractFileName(Comprovante.FileName)]);
      CaminhoCompleto := UploadsDir + PathDelim + NomeArquivoSeguro;

      // 3. Gravação física em disco a partir do Stream do arquivo
      DestinoStream := TFileStream.Create(CaminhoCompleto, fmCreate);
      try
        OrigemStream := Comprovante.Stream;
        if OrigemStream <> nil then
        begin
          OrigemStream.Position := 0;
          DestinoStream.CopyFrom(OrigemStream, OrigemStream.Size);
        end;
      finally
        DestinoStream.Free;
      end;

      Results.Context(Ctx).Created(
        Format('/api/v1/faturas/%d/comprovante', [IdFatura]),
        Format('{"status":"created","arquivo":"%s","bytes":%d,"caminho":"%s"}',
               [NomeArquivoSeguro, Comprovante.Length, CaminhoCompleto]));
    end);

  // 3. Método QUERY (RFC 10008) com Model Binding automático do corpo
  App.Builder.MapQuery<TCriteriosBuscaAvancadaDto, IResult>(
    '/api/v1/faturas/consultar-avancado',
    function(Criterios: TCriteriosBuscaAvancadaDto): IResult
    begin
      Result := Results.Ok(
        Format('{"mensagem":"Busca processada com sucesso","centros":%d,"status":%d}',
               [Length(Criterios.CentrosCusto), Length(Criterios.StatusList)]));
    end);
end;

begin
  try
    Writeln('=== Servidor Model Binding e Contratos de Entrada - Cap 03 ===');
    var App := WebApplication;

    RegisterBindingEndpoints(App);

    Writeln('[SERVER] Endpoints disponiveis em http://localhost:8080:');
    Writeln('  - GET   /api/v1/clientes/{clienteId}/faturas');
    Writeln('  - POST  /api/v1/faturas/{id}/comprovante (Multipart Upload)');
    Writeln('  - QUERY /api/v1/faturas/consultar-avancado (RFC 10008)');

    App.Run(8080);
  except
    on E: Exception do
      Writeln('Erro: ', E.Message);
  end;
end.
