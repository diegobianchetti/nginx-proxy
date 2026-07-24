# Stage 1 — base: nginx 1.30.4 oficial (Alpine 3.24) + certbot e utilitários
# CVE-2026-42533: correção do map+regex presente a partir do nginx 1.30.4
FROM nginx:1.30.4-alpine AS base

LABEL maintainer="diego@oogway.com.br"

ENV TZ=America/Sao_Paulo

RUN apk add --no-cache \
        certbot \
        certbot-nginx \
        tzdata \
        curl \
        bash \
        openssl \
    && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo "${TZ}" > /etc/timezone \
    && mkdir -p /var/log/nginx /run/nginx

# Stage 2 — config: copia configurações, scripts e páginas de erro
FROM base AS config

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY nginx/nginx.conf           /etc/nginx/nginx.conf
COPY nginx/block-injects.conf   /etc/nginx/conf.d/block-injects.conf
COPY nginx/error-pages.conf     /etc/nginx/conf.d/error-pages.conf
COPY nginx/default.conf         /etc/nginx/conf.d/default.conf

COPY error-pages/               /etc/nginx/error-pages/

COPY VERSION /VERSION

# Stage 3 — final: imagem de produção
FROM config AS final

WORKDIR /etc/nginx

EXPOSE 80 443

CMD ["/usr/local/bin/entrypoint.sh"]
