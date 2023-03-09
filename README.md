# nim-app

Example containerized [Nim](https://nim-lang.org/) application powered by [Prologue](https://github.com/planety/prologue).

## Build and run locally

```sh
docker build --no-cache -t nim-app:0.1 .
docker run --init -it -p 8080:8080 --rm nim-app:0.1
# curl http://localhost:8080 
```

## Host the app using AWS App Runner

:information_source: This requires an AWS account and will incur some costs.

1. Create AWS ECR repository to host the container images

:information_source: We configure ECR image tags as MUTABLE, to leverage the App Runner autodeploy feature

    ```sh
    aws cloudformation deploy --template-file aws/ecr-repo.yml --stack-name nim-app-ecr --parameter-overrides Name=nim-app
    ecr_repository="$(aws cloudformation describe-stacks --stack-name nim-app-ecr | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "Uri") | .OutputValue')"
    ecr_registry="${ecr_repository%%/nim-app}"
    ```

2. Build, tag and push the docker image to the ECR repository

    ```sh
    aws ecr get-login-password | docker login --username AWS --password-stdin $ecr_registry
    docker build -t nim-app:v1 .
    docker tag nim-app:v1 $ecr_repository:v1
    docker push $ecr_repository:v1
    ```

3. Deploy the app to AWS App Runner

:information_source: We create an autoscaling configuration using AWS CLI, because [Cloudformation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/AWS_AppRunner.html) does not yet support it

    ```sh
    autoscaling_config_arn="$(aws apprunner create-auto-scaling-configuration --auto-scaling-configuration-name nim-app \
        --max-concurrency 100 --min-size 1 --max-size 2 | jq -r '.AutoScalingConfiguration.AutoScalingConfigurationArn')"
    aws cloudformation deploy --template-file aws/app-runner.yml --capabilities CAPABILITY_NAMED_IAM \
        --stack-name nim-app-runner --parameter-overrides Image="$ecr_repository:v1" AutoScalingConfigArn=$autoscaling_config_arn
    echo "Application URL: https://$(aws cloudformation describe-stacks --stack-name nim-app-runner | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "Url") | .OutputValue')"
    ```

4. Try changing the `hello` handler code in [src/app.nim](src/app.nim), then build, tag and push the `v1` image again, and observe result

## Proxy traffic to your site through Cloudflare

This requires a Cloudflare account and website.

1. Create custom domain for App Runner

TODO

2. Configure Cloudflare website to route traffic to AWS App Runner origin

TODO
