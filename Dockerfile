FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash kiwix-monitor

COPY ./bin/monitor /usr/local/bin/monitor

RUN chmod +x /usr/local/bin/monitor

USER kiwix-monitor

WORKDIR /home/kiwix-monitor

CMD ["/usr/local/bin/monitor"]
