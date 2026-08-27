  # Imagem base minimalista para o executável Linux nativo
FROM alpine:3.18

RUN apk add --no-cache libc6-compat gcompat openssl curl

WORKDIR /app

COPY ./HostingApp .
COPY ./appsettings.yaml .

EXPOSE 8080

ENV DEXT_ENVIRONMENT=Production

ENTRYPOINT ["./HostingApp"]
