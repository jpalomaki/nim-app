# nim-app

Example containerized Nim application powered by [Prologue](https://github.com/planety/prologue).

## Build and run locally

```sh
docker build -t app:0.1 .
docker run --init -it -p 8080:8080 --rm app:0.1
# curl http://localhost:8080 
```

## TODOs

- Check if we can hide the server header (-d:serverInfo:name?)
- Check if HTTP 204 No Content can be returned without content-length/content-type
- GitHub workflow for building the docker image and publishing to AWS ECR
- CloudFormation template for deploying to AWS App Runner
