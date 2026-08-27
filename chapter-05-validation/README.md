# Capítulo 05: Validação de Entrada de Dados

Demonstração console da validação declarativa (`[Required]`, `[StringLength]`, `[EmailAddress]`, `[Range]`) e fluente (`TAbstractValidator<T>` com `.When` e `.Must`).

O projeto **não** sobe um servidor HTTP: execute `Chapter05_ValidationApp.exe` (ou o script de teste) para ver o Fail-Fast no terminal. A API HTTP de clientes é consolidada no Laboratório 1.

```powershell
powershell -ExecutionPolicy Bypass -File .\Test.Chapter05_ValidationApp.ps1
```
