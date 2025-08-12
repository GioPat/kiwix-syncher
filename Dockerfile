FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash kiwix-syncher

COPY ./bin/syncher /usr/local/bin/syncher

RUN chmod +x /usr/local/bin/syncher

USER kiwix-syncher

WORKDIR /home/kiwix-syncher

CMD ["/usr/local/bin/syncher"]
