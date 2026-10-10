# Be Safe - Suíte de Conscientização

App de segurança feito em [Kof](https://github.com/KofLang/Kof4j) com microsserviços, para treinar pessoas a reconhecer golpes e criar senhas fortes.

**Acesse:** https://marianabsctba.github.io/KofLang_App/

- **Detector de phishing**: cole o texto de um e-mail, SMS ou WhatsApp suspeito e receba uma nota de risco com os sinais de golpe encontrados (urgência, pedido de senha ou Pix, link com domínio que imita marca, link encurtado, IP no lugar de domínio, punycode e outros).
- **Cofre de senhas**: mede a força de uma senha (entropia, tempo estimado para quebrá-la, senhas vazadas, sequências), mostra como um sistema seguro guarda essa senha (PBKDF2) e gera senhas fortes com gerador criptográfico.

O app é 100% defensivo: **não acessa nenhum link e não guarda nada**. Tudo é processado sobre o texto que a pessoa digita, durante a requisição.

## Arquitetura

```
navegador ──> gateway (8080) ──> phishing (8081)
               │  serve o      └─> senhas   (8082)
               │  frontend
```

| Pasta | Serviço | Porta | O que faz |
|---|---|---|---|
| `servicos/gateway` | gateway | 8080 | Serve o frontend e repassa `/api/*` para o serviço certo |
| `servicos/phishing` | phishing | 8081 | `POST /analisar`: analisa o texto e devolve risco e sinais |
| `servicos/senhas` | senhas | 8082 | `POST /avaliar` e `GET /gerar?tamanho=N` |
| `frontend` | - | - | Interface escrita em Kof e compilada para JavaScript (KofJS) |
| `pages` | - | - | Versão estática para o GitHub Pages, sem servidor |

Tudo é Kof: os serviços rodam na JVM e o frontend é compilado para JS.

## Como rodar (Windows)

1. Baixe o Kof 0.5.0-beta para Windows em [Releases](https://github.com/KofLang/Kof4j/releases) e extraia o conteúdo da pasta `kof-0.5.0-beta-windows-x86_64` dentro de `.kof/` na raiz do projeto (ou deixe o `kof` no `PATH`). O pacote já traz o Java, não precisa instalar nada.
2. Suba a suíte:

```powershell
.\scripts\subir.ps1
```

3. Abra http://localhost:8080
4. Para parar:

```powershell
.\scripts\parar.ps1
```

Os logs ficam em `.logs/` e o frontend compilado em `dist/frontend/`.

### Variáveis de ambiente

| Variável | Padrão | Uso |
|---|---|---|
| `PORTA` | 8080 / 8081 / 8082 | Porta de cada serviço |
| `PHISHING_URL` | `http://localhost:8081` | Onde o gateway encontra o serviço de phishing |
| `SENHAS_URL` | `http://localhost:8082` | Onde o gateway encontra o serviço de senhas |
| `FRONTEND_DIR` | - | Pasta do frontend compilado que o gateway serve |

## API

```bash
curl -X POST localhost:8080/api/phishing --data-binary "Sua conta será bloqueada. Confirme sua senha em http://banco-seguro.xyz"
curl -X POST localhost:8080/api/senhas/avaliar --data-binary "minhaSenha123"
curl "localhost:8080/api/senhas/gerar?tamanho=20"
```

A senha vai sempre no corpo de um `POST`, nunca na URL, para não aparecer em histórico nem em log de acesso.

## Versão estática (GitHub Pages)

A pasta `pages/` tem a mesma suíte sem servidor: a lógica dos microsserviços (`Phishing.kf` e `Senhas.kf`) é compilada junto com a tela para JavaScript e roda inteira no navegador de quem usa. Continua sendo 100% Kof.

- A cada push na `main`, o workflow `.github/workflows/pages.yml` baixa o Kof, confere o checksum, compila e publica.
- Para ativar: no GitHub, **Settings > Pages > Source: GitHub Actions**.
- Diferença para a versão com microsserviços: o PBKDF2 do Kof 0.5.0-beta não roda num navegador comum, então a versão estática explica o hash em vez de mostrá-lo. O gerador de senhas usa `crypto.getRandomValues`, que é seguro.
- Se mudar a lógica em `servicos/phishing` ou `servicos/senhas`, replique em `pages/Phishing.kf` e `pages/Senhas.kf`.

Para testar localmente, compile e sirva `dist/pages` com qualquer servidor estático que entregue `.mjs` como `text/javascript`:

```powershell
.\.kof\bin\kof.bat build pages --target js --output dist/pages
Copy-Item pages\index.html, pages\static dist\pages -Recurse -Force
```

## Notas sobre o Kof 0.5.0-beta

A linguagem ainda está em beta. Os contornos usados no código estão comentados onde aparecem:

- No KofJS, `json.decode` não converte uma lista de records aninhada dentro de outro record. Os serviços sempre mandam a lista como último campo e o frontend decodifica esse campo à parte.
- No navegador, `http.get`/`http.post` são assíncronos: a chamada fica dentro de `spawn { ... await ... }`.
- No backend JVM, `math.parseIntOrDefault`/`math.clamp` com String anulável geram bytecode inválido; o serviço de senhas converte o número manualmente.
- O runtime do KofJS injeta um tema próprio; o `frontend/index.html` substitui o padrão e mantém o tema preto e rosa.
