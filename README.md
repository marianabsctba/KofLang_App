# Be Safe - Suite de Conscientizacao

App de seguranca feito em [Kof](https://github.com/KofLang/Kof4j) com microsservicos, para treinar pessoas a reconhecer golpes e criar senhas fortes.

- **Detector de phishing**: cole o texto de um e-mail, SMS ou WhatsApp suspeito e receba uma nota de risco com os sinais de golpe encontrados (urgencia, pedido de senha ou Pix, link com dominio que imita marca, link encurtado, IP no lugar de dominio, punycode e outros).
- **Cofre de senhas**: mede a forca de uma senha (entropia, tempo estimado para quebrar, senhas vazadas, sequencias), mostra como um sistema seguro guarda essa senha (PBKDF2) e gera senhas fortes com gerador criptografico.

O app e 100% defensivo: **nao acessa nenhum link e nao guarda nada**. Tudo e processado sobre o texto que a pessoa digita, durante a requisicao.

## Arquitetura

```
navegador ──> gateway (8080) ──> phishing (8081)
               │  serve o      └─> senhas   (8082)
               │  frontend
```

| Pasta | Servico | Porta | O que faz |
|---|---|---|---|
| `servicos/gateway` | gateway | 8080 | Serve o frontend e repassa `/api/*` para o servico certo |
| `servicos/phishing` | phishing | 8081 | `POST /analisar`: analisa o texto e devolve risco e sinais |
| `servicos/senhas` | senhas | 8082 | `POST /avaliar` e `GET /gerar?tamanho=N` |
| `frontend` | - | - | Interface escrita em Kof e compilada para JavaScript (KofJS) |

Tudo e Kof: os servicos rodam na JVM e o frontend e compilado para JS.

## Como rodar (Windows)

1. Baixe o Kof 0.5.0-beta para Windows em [Releases](https://github.com/KofLang/Kof4j/releases) e extraia o conteudo da pasta `kof-0.5.0-beta-windows-x86_64` dentro de `.kof/` na raiz do projeto (ou deixe o `kof` no `PATH`). O pacote ja traz o Java, nao precisa instalar nada.
2. Suba a suite:

```powershell
.\scripts\subir.ps1
```

3. Abra http://localhost:8080
4. Para parar:

```powershell
.\scripts\parar.ps1
```

Os logs ficam em `.logs/` e o frontend compilado em `dist/frontend/`.

### Variaveis de ambiente

| Variavel | Padrao | Uso |
|---|---|---|
| `PORTA` | 8080 / 8081 / 8082 | Porta de cada servico |
| `PHISHING_URL` | `http://localhost:8081` | Onde o gateway encontra o servico de phishing |
| `SENHAS_URL` | `http://localhost:8082` | Onde o gateway encontra o servico de senhas |
| `FRONTEND_DIR` | - | Pasta do frontend compilado que o gateway serve |

## API

```bash
curl -X POST localhost:8080/api/phishing --data-binary "Sua conta sera bloqueada. Confirme sua senha em http://banco-seguro.xyz"
curl -X POST localhost:8080/api/senhas/avaliar --data-binary "minhaSenha123"
curl "localhost:8080/api/senhas/gerar?tamanho=20"
```

A senha vai sempre no corpo de um `POST`, nunca na URL, para nao aparecer em historico nem em log de acesso.

## Notas sobre o Kof 0.5.0-beta

A linguagem ainda esta em beta. Os contornos usados no codigo estao comentados onde aparecem:

- No KofJS, `json.decode` nao converte uma lista de records aninhada dentro de outro record. Os servicos sempre mandam a lista como ultimo campo e o frontend decodifica esse campo a parte.
- No navegador, `http.get`/`http.post` sao assincronos: a chamada fica dentro de `spawn { ... await ... }`.
- No backend JVM, `math.parseIntOrDefault`/`math.clamp` com String anulavel geram bytecode invalido; o servico de senhas converte o numero manualmente.
- O runtime do KofJS injeta um tema proprio; o `frontend/index.html` substitui o padrao e mantem o tema preto e rosa.
