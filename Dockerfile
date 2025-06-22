# GLOBAL BUILD ARG
ARG NSD_IMAGE_VERSION=4.12.0
ARG NSD_IMAGE_REVISION=a

# NSD BUILDER
FROM alpine:latest AS builder
LABEL maintainer="cloubit"

# install required programms and dependencies
RUN set -x -e; \
  apk --update --no-cache add \
    ca-certificates \
    pkgconfig \
    curl \
    gnupg \
    shadow \
    linux-headers \
    perl \
    build-base \
  rm -rf /usr/share/man /usr/share/docs /tmp/* /var/tmp/* /var/log/*

# openssl install
ENV OPENSSL_VERSION=openssl-3.5.0 \
  OPENSSL_DOWNLOAD_URL=https://github.com/openssl/openssl/releases/download \
  OPENSSL_SHA256=344d0a79f1a9b08029b0744e2cc401a43f9c90acd1044d09a530b4885a8e9fc0 \
  OPENSSL_PGP_0=BA5473A2B0587B07FB27CF2D216094DFD0CB81EF

WORKDIR /tmp/openssl

RUN set -x -e; \
  curl -sSL "${OPENSSL_DOWNLOAD_URL}"/"${OPENSSL_VERSION}"/"${OPENSSL_VERSION}".tar.gz -o openssl.tar.gz && \
  echo "${OPENSSL_SHA256} ./openssl.tar.gz" | sha256sum -c - && \
  curl -sSL "${OPENSSL_DOWNLOAD_URL}"/"${OPENSSL_VERSION}"/"${OPENSSL_VERSION}".tar.gz.asc -o openssl.tar.gz.asc && \
  GNUPGHOME="$(mktemp -d)" && \
  export GNUPGHOME && \
  gpg --no-tty --keyserver hkps://keys.openpgp.org --recv-keys "${OPENSSL_PGP_0}" && \
  gpg --batch --verify openssl.tar.gz.asc openssl.tar.gz && \
  tar -xzf openssl.tar.gz && \
  rm -f openssl.tar.gz && \
  cd "${OPENSSL_VERSION}" && \
  ./Configure \
    --prefix=/usr/local \
    no-weak-ssl-ciphers \
    no-docs \
    no-ssl3 \
    no-err \
    no-autoerrinit \
    no-shared \
    enable-tfo \
    enable-ktls \
    enable-ec_nistp_64_gcc_128 \
    -fPIC \
    -DOPENSSL_NO_HEARTBEATS \
    -fstack-protector-strong \
    -fstack-clash-protection && \
  make && \
  make -j$(nproc) && \
  make install_sw &&\
  rm -rf /usr/share/man /usr/share/docs /tmp/* /var/tmp/* /var/log/*

# libevent install
ENV LIBEVENT_RELEASE=release-2.1.12-stable \
  LIBEVENT_VERSION=libevent-2.1.12-stable \
  LIBEVENT_DOWNLOAD_URL=https://github.com/libevent/libevent/releases/download \
  LIBEVENT_SHA256=92e6de1be9ec176428fd2367677e61ceffc2ee1cb119035037a27d346b0403bb

WORKDIR /tmp/libevent

RUN curl -sSL "${LIBEVENT_DOWNLOAD_URL}"/"${LIBEVENT_RELEASE}"/"${LIBEVENT_VERSION}".tar.gz -o libevent.tar.gz && \
  echo "${LIBEVENT_SHA256} ./libevent.tar.gz" | sha256sum -c - && \
  tar -xzf libevent.tar.gz && \
  rm -f libevent.tar.gz && \
  cd "${LIBEVENT_VERSION}" && \
	./configure \
    --libdir=/usr/local/lib \
    --includedir=/usr/local/include \
    --enable-openssl \
    --enable-static \
    --disable-shared && \
	make -j$(nproc) && \
	make install && \
  rm -rf /usr/share/man /usr/share/docs /tmp/* /var/tmp/* /var/log/*

# ldns install
ENV LDNS_VERSION=ldns-1.8.4 \
  LDNS_DOWNLOAD_URL=https://nlnetlabs.nl/downloads/ldns \
  LDNS_SHA256=838b907594baaff1cd767e95466a7745998ae64bc74be038dccc62e2de2e4247 \
  LDNS_PGP_0=DC34EE5DB2417BCC151E5100E5F8F8212F77A498

WORKDIR /tmp/ldns

RUN set -x -e; \
    curl -sSL "${LDNS_DOWNLOAD_URL}"/"${LDNS_VERSION}".tar.gz -o ldns.tar.gz && \
    echo "${LDNS_SHA256} ./ldns.tar.gz" | sha256sum -c - && \
    curl -L "${LDNS_DOWNLOAD_URL}"/"${LDNS_VERSION}".tar.gz.asc -o ldns.tar.gz.asc && \
    GNUPGHOME="$(mktemp -d)" && \
    export GNUPGHOME && \
    gpg --no-tty --keyserver hkps://keys.openpgp.org --recv-keys "${LDNS_PGP_0}" && \
    gpg --batch --verify ldns.tar.gz.asc ldns.tar.gz && \
    tar -xzf ldns.tar.gz && \
    rm -f ldns.tar.gz && \
    cd "${LDNS_VERSION}" && \
    ./configure \
      --prefix=/usr/local \
      --with-ssl \
      --with-drill \
      --enable-static \
      --disable-shared &&\
    make -j$(nproc) &&\
    make install && \
    rm -rf /usr/share/man /usr/share/docs /tmp/* /var/tmp/* /var/log/*

  # nsd install
ENV NSD_VERSION=nsd-4.12.0 \
NSD_DOWNLOAD_URL=https://nlnetlabs.nl/downloads/nsd \
NSD_SHA256=f9ecc2cf79ba50580f2df62918efc440084c5bf11057db44c19aa9643cd4b5e8 \
NSD_PGP_0=16A8374956B251465BE0995C38861AF4EC519C61

WORKDIR /tmp/nsd

RUN set -x -e; \
curl -sSL "${NSD_DOWNLOAD_URL}"/"${NSD_VERSION}".tar.gz -o nsd.tar.gz && \
echo "${NSD_SHA256} ./nsd.tar.gz" | sha256sum -c - && \
curl -sSL "${NSD_DOWNLOAD_URL}"/"${NSD_VERSION}".tar.gz.asc -o nsd.tar.gz.asc && \
GNUPGHOME="$(mktemp -d)" && \
export GNUPGHOME && \
gpg --no-tty --keyserver hkps://keys.openpgp.org --recv-keys "${NSD_PGP_0}" && \
gpg --batch --verify nsd.tar.gz.asc nsd.tar.gz && \
tar -xzf nsd.tar.gz && \
rm -f nsd.tar.gz && \
groupadd _nsd && \
useradd -g _nsd -s /dev/null -d /dev/null _nsd && \
cd "${NSD_VERSION}" && \
./configure \
  --prefix=/opt/nsd \
  --with-user=_nsd \
  --with-ssl \
  --with-libevent=/usr/local \
  --with-configdir=/opt/nsd/etc/nsd \
  --with-pidfile=/opt/nsd/etc/nsd/var/run/nsd.pid \
  --with-zonesdir=/opt/nsd/etc/nsd/zones \
  --enable-root-server \
  --enable-static \
  --disable-shared \
  CFLAGS="-O2 -flto -fPIE -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -fstack-protector-strong -Wformat -Werror=format-security" \
  LDFLAGS="-Wl,-z,now -Wl,-z,relro" && \
make -j$(nproc) && \
make install && \
pkill -9 gpg-agent && \
pkill -9 dirmngr && \
rm -rf /usr/share/man /usr/share/docs /tmp/* /var/tmp/* /var/log/* /opt/nsd/include /opt/nsd/share /opt/nsd/etc/nsd/nsd.conf.sample


# NSD STAGE
FROM scratch AS stage
LABEL maintainer="cloubit"

# copy required programs and dependencies to stage
COPY --from=builder /opt/nsd/ \
  /stage/opt/nsd/
COPY --from=builder /bin/sh /bin/ls /bin/rm /bin/cp /bin/cat /bin/mkdir /bin/chown /bin/chmod \
 /stage/bin/
COPY --from=builder /usr/local/bin/ \
  /stage/usr/local/bin/
COPY --from=builder /lib/*musl* \
 /stage/lib/
COPY --from=builder /usr/local/lib/lib* \
  /stage/usr/local/lib/
COPY --from=builder /usr/local/lib/ossl-*/ \
  /stage/usr/local/lib/ossl-modules/
COPY --from=builder /usr/local/lib6*/lib* \
  /stage/usr/local/lib64/
COPY --from=builder /usr/local/lib6*/ossl-*/ \
  /stage/usr/local/lib64/ossl-modules/
COPY --from=builder /etc/passwd /etc/shadow /etc/group \
  /stage/etc/
COPY --from=builder /etc/ssl/certs/ \
  /stage/etc/ssl/certs/


# UNBOUND FINAL
FROM scratch

ARG NSD_IMAGE_VERSION
ARG NSD_IMAGE_REVISION
ENV NSD_IMAGE=${NSD_IMAGE_VERSION}-${NSD_IMAGE_REVISION}
ARG NSD_CONFIG=data
ENV NSD_CONFIG=${NSD_CONFIG}

LABEL maintainer="cloubit" \
  org.opencontainers.image.version=${NSD_IMAGE} \
  org.opencontainers.image.title="NSD on Docker" \
  org.opencontainers.image.description="NSD is an reliable, stable and secure authoritative DNS name server" \
  org.opencontainers.image.summary="Distroless NSD Docker image, based on Alpine Linux, with focus on security and performance" \
  org.opencontainers.image.vendor="Cloubit GmbH" \
  org.opencontainers.image.base.name="cloubit/nsd" \
  org.opencontainers.image.url="https://hub.docker.com/repository/docker/cloubit/nsd" \
  org.opencontainers.image.source="https://github.com/cloubit/nsd-docker" \
  org.opencontainers.image.authors="cloubit" \
  org.opencontainers.image.licenses="MIT"

COPY --from=stage /stage /
COPY ${NSD_CONFIG} /opt/nsd/etc/nsd/

RUN mkdir -p -m 700 /opt/nsd/etc/nsd/var && \
  mkdir -p -m 700 /opt/nsd/etc/nsd/var/log && \
  mkdir -p -m 700 /opt/nsd/etc/nsd/var/db && \
  mkdir -p -m 700 /opt/nsd/etc/nsd/var/run && \
  mkdir -p -m 700 /opt/nsd/etc/nsd/zones && \
  chown -R _nsd /opt/nsd/etc/nsd

HEALTHCHECK --interval=20s --timeout=30s --start-period=10s --retries=3 \
  CMD drill -D -o cd @127.0.0.1 cloudflare.com || exit 1

EXPOSE 53/tcp 53/udp

WORKDIR /opt/nsd/

ENV PATH=/opt/nsd/sbin:"$PATH"

ENTRYPOINT ["nsd" , "-d"]
