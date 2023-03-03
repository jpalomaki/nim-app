FROM nimlang/nim:1.6.10 AS builder

WORKDIR /usr/src

COPY . ./

RUN nimble build -y -d:release

FROM gcr.io/distroless/base-debian11:nonroot

COPY --from=builder /usr/src/app /app

USER nonroot

CMD ["/app"]

