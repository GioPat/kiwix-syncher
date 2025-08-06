# Use Ubuntu 24.04 LTS
FROM ubuntu:24.04

# Install minimal runtime dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m -s /bin/bash jai-user

# Copy your Jai executable
COPY main /usr/local/bin/app

# Make it executable
RUN chmod +x /usr/local/bin/app

# Switch to non-root user
USER jai-user

# Set working directory
WORKDIR /home/jai-user

# Run the executable
CMD ["/usr/local/bin/app"]
