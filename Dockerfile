FROM nimlang/nim:1.6.10 AS builder

WORKDIR /usr/src

COPY . ./

RUN nimble build -y -d:release

FROM gcr.io/distroless/base:nonroot

COPY --from=builder /usr/src/app /app

CMD ["/app"]
