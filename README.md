# nginx-proxy

Container Docker standalone de proxy reverso nginx com certbot integrado.
Base Alpine — imagem leve, sem dependências desnecessárias, pronto para
gerenciar múltiplos domínios em um único host Docker.
Imagem publicada em `ghcr.io/diegobianchetti/nginx-proxy`.

---

## Funcionalidades

- Proxy reverso para containers Docker via vhosts (`.conf` por projeto)
- Renovação automática de certificados Let's Encrypt via certbot + crond
- Certificado self-signed gerado em runtime para o vhost default
- Páginas de erro customizadas em português com identidade visual Jardim Zen
- Proteção contra SQL injection, path traversal e exploits comuns
- Vhost catch-all com `return 444` (sem resposta para domínios não mapeados)

---

## Pré-requisitos

- Docker >= 24 e Docker Compose v2
- Portas 80 e 443 livres no host
- Diretório `/etc/nginx-proxy/vhosts.d/` criado no host (para vhosts dos projetos)

```bash
sudo mkdir -p /etc/nginx-proxy/vhosts.d
```

---

## Como usar

```bash
cp .env.example .env
# Edite .env conforme necessário
docker compose up -d
```

---

## Estrutura de volumes

| Volume / Bind mount | Finalidade |
|---|---|
| `./sites-available` | Vhosts gerenciados manualmente |
| `./sites-enabled` | Vhosts ativos (link ou cópia de sites-available) |
| `/etc/nginx-proxy/vhosts.d` | Vhosts gerados automaticamente pelo cctl (somente leitura) |
| `letsencrypt` | Certificados Let's Encrypt (volume nomeado) |
| `log` | Logs do nginx (volume nomeado) |

---

## Integração com cctl

O `cctl init` gera um arquivo `.conf` de vhost nginx para cada instância instalada.
Esse arquivo é gravado em `/etc/nginx-proxy/vhosts.d/` no host e montado como
`read-only` no container nginx-proxy — sem necessidade de reiniciar o proxy.

O host deve ter o diretório criado antes de qualquer `cctl install`:

```bash
sudo mkdir -p /etc/nginx-proxy/vhosts.d
```

---

## Decisões Técnicas

**Alpine em vez de Ubuntu**
A imagem Alpine do nginx ocupa ~10–15 MB; a equivalente Debian/Ubuntu chega a ~150 MB.
Surface de ataque menor, boot mais rápido, menos pacotes desnecessários instalados.

**crond nativo do Alpine**
O Alpine usa `crond` do pacote `busybox-extras`, não o `cron` do Debian.
A chamada correta é `crond -b -l 8` (background, log level 8).
Tentar usar `cron` ou `service cron start` em Alpine falha silenciosamente.

**TLSv1.2+ apenas**
TLSv1 e TLSv1.1 foram removidos conforme RFC 8996 (março 2021).
Todos os browsers modernos suportam TLSv1.2 e TLSv1.3.
Manter versões antigas aumenta exposição a BEAST, POODLE e ataques similares.

**default.conf retorna 444**
Requisições para IPs ou domínios não mapeados recebem `return 444` (conexão fechada
sem resposta HTTP). Isso impede que scanners saibam que há um servidor web ativo
e evita expor qualquer informação da infraestrutura como resposta padrão.

**Certificado self-signed gerado em runtime**
O Alpine não possui o pacote `ssl-cert` do Debian (que gera snakeoil automaticamente).
O `entrypoint.sh` gera o certificado para o vhost default na primeira execução
via `openssl req -x509`. O certificado é para uso interno apenas (vhost catch-all).

**Bind mount em `/etc/nginx-proxy/vhosts.d/`**
Cada projeto gerenciado pelo `cctl` escreve seu vhost nesse diretório do host.
O nginx-proxy monta esse diretório como `:ro` — o proxy não tem permissão de escrita,
o que isola responsabilidades: cada projeto gerencia seu próprio vhost.

**Páginas de erro em português**
Páginas de erro em inglês genérico prejudicam a experiência de usuários finais
em ambientes brasileiros. As páginas Jardim Zen usam identidade visual consistente,
fonte system-ui (sem dependência de CDN externo) e placeholder `%{HOSTNAME}`
substituído em runtime pelo nginx via `sub_filter`.

---

## Licença

[GPL v3](https://www.gnu.org/licenses/gpl-3.0.html)
