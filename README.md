# nim-app

Example containerized [Nim](https://nim-lang.org/) application powered by [Prologue](https://github.com/planety/prologue).

## Build and run locally

```sh
docker build -t nim-app:v1 .
docker run --init -it -p 8080:8080 --rm nim-app:v1
# curl http://localhost:8080 
```

## Host the app with AWS App Runner (public endpoint)

:warning: This guide is a work in progress, and may be incomplete

:information_source: This requires an [AWS account](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/) and will incur some [costs](https://aws.amazon.com/apprunner/pricing/).

1. Create AWS ECR repository to host the container images

    :information_source: We configure ECR image tags as MUTABLE, to leverage the App Runner autodeployment feature

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

    :information_source: We create an autoscaling configuration using AWS CLI, because [CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/AWS_AppRunner.html) does not yet support it

    ```sh
    autoscaling_config_arn="$(aws apprunner create-auto-scaling-configuration --auto-scaling-configuration-name nim-app \
        --max-concurrency 100 --min-size 1 --max-size 2 | jq -r '.AutoScalingConfiguration.AutoScalingConfigurationArn')"
    aws cloudformation deploy --template-file aws/app-runner.yml --capabilities CAPABILITY_NAMED_IAM \
        --stack-name nim-app-runner --parameter-overrides Image="$ecr_repository:v1" AutoScalingConfigArn=$autoscaling_config_arn
    echo "Application URL: https://$(aws cloudformation describe-stacks --stack-name nim-app-runner | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "Url") | .OutputValue')"
    ```

4. Try changing the `hello` handler code in [src/app.nim](src/app.nim), then build, tag and push the `v1` image again, and observe result

## Proxy traffic to the app through Cloudflare

This requires a [Cloudflare](https://dash.cloudflare.com/sign-up) account and website.

1. Create custom domain for App Runner

    TODO

2. Configure Cloudflare website to route traffic to AWS App Runner origin

    TODO

## Tear down AWS resources

```sh
aws cloudformation delete-stack --stack-name nim-app-runner
aws cloudformation wait stack-delete-complete --stack-name nim-app-runner
aws apprunner delete-auto-scaling-configuration --auto-scaling-configuration-arn $autoscaling_config_arn
for digest in $(aws ecr list-images --repository-name nim-app | jq -r '.imageIds[].imageDigest'); do
    aws ecr batch-delete-image --repository-name nim-app --image-ids imageDigest=$digest
done
aws cloudformation delete-stack --stack-name nim-app-ecr
aws cloudformation wait stack-delete-complete --stack-name nim-app-ecr
```

## TODOs

- Explore use of [AWS C++ SDK](https://aws.amazon.com/sdk-for-cpp/) from Nim (calling e.g. DynamoDB)
