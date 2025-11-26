# Build stage
FROM golang:1.21-alpine AS builder

# Install git (required for go modules)
RUN apk add --no-cache git ca-certificates tzdata

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a -installsuffix cgo \
    -o slack-bot .

# Final stage
FROM scratch

# Copy timezone data
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Copy SSL certificates
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy the binary
COPY --from=builder /app/slack-bot /slack-bot

# Expose port
EXPOSE 8080

# Set environment variables
ENV PORT=8080
ENV TZ=UTC

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ["/slack-bot", "--health-check"]

# Run the application
ENTRYPOINT ["/slack-bot"]