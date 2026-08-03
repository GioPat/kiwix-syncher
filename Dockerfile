FROM ubuntu:24.04

ARG KIWIX_TOOLS_VERSION=3.8.2

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# kiwix-manage, for configs that use the on_sync_complete hook to rebuild a
# library.xml. The musl build is statically linked, so only the single binary is
# kept and nothing else is pulled into the image.
ADD https://download.kiwix.org/release/kiwix-tools/kiwix-tools_linux-x86_64-musl-${KIWIX_TOOLS_VERSION}.tar.gz /tmp/kiwix-tools.tar.gz
RUN tar -xzf /tmp/kiwix-tools.tar.gz -C /tmp \
    && install -m 0755 /tmp/kiwix-tools_linux-x86_64-musl-${KIWIX_TOOLS_VERSION}/kiwix-manage /usr/local/bin/kiwix-manage \
    && rm -rf /tmp/kiwix-tools.tar.gz /tmp/kiwix-tools_linux-x86_64-musl-${KIWIX_TOOLS_VERSION}

RUN useradd -m -s /bin/bash kiwix-syncher

COPY ./bin/syncher /usr/local/bin/syncher

RUN chmod +x /usr/local/bin/syncher

USER kiwix-syncher

WORKDIR /home/kiwix-syncher

CMD ["/usr/local/bin/syncher"]
