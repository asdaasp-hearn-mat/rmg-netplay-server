FROM golang:1.26 as builder
WORKDIR /workspace

COPY . .
RUN go mod download
RUN CGO_ENABLED=0 go build -a -o rmg-netplay-server .

FROM registry.access.redhat.com/ubi10/ubi-minimal:latest
WORKDIR /

COPY --from=builder /workspace/rmg-netplay-server .

ENTRYPOINT ["/rmg-netplay-server"]
