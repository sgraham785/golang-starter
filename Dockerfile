FROM 872941275684.dkr.ecr.us-east-1.amazonaws.com/alpine-go:1.11

WORKDIR /go/src/github.com/canary-health/golang-starter/
COPY . .
