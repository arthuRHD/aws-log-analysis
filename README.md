# Log analysis within AWS services

A lambda function that check log files from Cloudwatch and notify Teams by calling their API endpoints when a log matches a filter.

## Usage

```sh
npm run start
```

## Development

To develop and run live code, launch

```sh
npm run start:dev
```

There are no tests right now, when you are done you should build the image and perform exploratory tests

```sh
# Build the docker image
docker build -t aws-log-analysis:test .

# Run the lambda in your local environment
docker run -p 9000:8000 aws-log-analysis:test &

# Query the lambda over HTTP
curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{}'
```
