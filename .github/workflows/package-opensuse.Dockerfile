# syntax=docker/dockerfile:1
FROM registry.opensuse.org/opensuse/leap:15 AS builder

RUN zypper --non-interactive install \
    ccache \
    libtool \
    pattern:devel_rpm_build \
    perl-File-Temp \
    systemtap-sdt-devel \
    wget
# Docker ADD/COPY doesn't derefence symlinks, so we have to copy the whole thing.
COPY . /src
RUN rmdir /usr/src/packages/SOURCES /usr/src/packages/SPECS
RUN ln -s /src/rpm/SOURCES /usr/src/packages/SOURCES
RUN ln -s /src/rpm/SPECS /usr/src/packages/SPECS
WORKDIR /usr/src/packages/SOURCES/
RUN \
    for file in openresty-zlib openresty-pcre openresty-openssl111 openresty; do \
    rpmspec -P /usr/src/packages/SPECS/${file}.spec \
    | awk '/^Source[0-9]+.*http/ { print $2 }' \
    | xargs wget \
    ; done
RUN mv v0.0.3.tar.gz ngx_http_proxy_connect_module-0.0.3.tar.gz
WORKDIR /usr/src/packages/SPECS/
RUN rpmbuild -ba openresty-zlib.spec
RUN rpm --install --nosignature \
    /usr/src/packages/RPMS/$(uname -m)/rd-openresty-zlib{,-devel}-[0-9]*.$(uname -m).rpm
RUN rpmbuild -ba openresty-pcre.spec
RUN rpmbuild -ba openresty-openssl111.spec
RUN rpm --install --nosignature \
    /usr/src/packages/RPMS/$(uname -m)/rd-openresty-openssl111{,-devel}-[0-9]*.$(uname -m).rpm \
    /usr/src/packages/RPMS/$(uname -m)/rd-openresty-pcre{,-devel}-[0-9]*.$(uname -m).rpm
RUN rpmbuild -ba openresty.spec

FROM scratch
COPY --from=builder /usr/src/packages/RPMS /RPMS/
COPY --from=builder /usr/src/packages/SRPMS /SRPMS/
