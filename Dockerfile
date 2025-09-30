# Build stage
FROM debian:trixie-slim AS builder

WORKDIR /src
RUN apt-get update \
	&& apt-get install -y wget tar build-essential ca-certificates \
	&& rm -rf /var/lib/apt/lists/*
RUN wget -O zig.tar.xz https://ziglang.org/download/0.15.1/zig-x86_64-linux-0.15.1.tar.xz \
	&& tar -xf zig.tar.xz \
	&& mv zig-x86_64-linux-0.15.1 /opt/zig \
	&& ln -s /opt/zig/zig /usr/local/bin/zig
ENV PATH="/opt/zig:$PATH"
COPY . .

RUN zig build --release=safe

# Runtime stage
FROM scratch AS runtime
COPY --from=builder /src/zig-out/bin/cli /json-zig
ENTRYPOINT ["/json-zig"]
