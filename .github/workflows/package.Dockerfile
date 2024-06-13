FROM alpine:latest AS builder

RUN apk add alpine-sdk ccache doas git
RUN adduser -D abuild-user
RUN addgroup abuild-user abuild
RUN echo "permit nopass abuild-user" >> /etc/doas.conf
USER abuild-user
RUN USER=rd-openresty abuild-keygen --append --install -n
RUN mkdir -p ~/.abuild
RUN echo "JOBS=`nproc`" >> ~/.abuild/abuild.conf

ADD --chown=abuild-user alpine /alpine/
RUN git clone -b v0.0.3 https://github.com/chobits/ngx_http_proxy_connect_module /alpine/ngx_http_proxy_connect_module

WORKDIR /alpine/openresty-zlib
RUN abuild -r
WORKDIR /alpine/openresty-pcre
RUN abuild -r
WORKDIR /alpine/openresty-openssl111
RUN abuild -r
WORKDIR /alpine/openresty
RUN abuild -r

WORKDIR /home/abuild-user/packages/alpine/
RUN cp ~/.abuild/rd-openresty-*.pub .
RUN tar cvf /tmp/openresty.tar \
    *.pub \
    $(uname -m)/rd-openresty-[0-9]*.apk \
    $(uname -m)/rd-openresty-openssl111-[0-9]*.apk \
    $(uname -m)/rd-openresty-pcre-[0-9]*.apk \
    $(uname -m)/rd-openresty-zlib-[0-9]*.apk

FROM scratch
ARG TARGETARCH
COPY --from=builder /tmp/openresty.tar /openresty-${TARGETARCH}.tar
