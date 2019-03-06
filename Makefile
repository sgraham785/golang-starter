.DEFAULT_GOAL := all

########################
## Internal variables
########################
APP_NAME=golang-starter
SERVER_HOST_PORT=8081
SERVER_ADDR=:9000
API_HOST_PORT=8082
SERVER_URL=http://golang-starter:9000
POSTGRES_USER=postgres
POSTGRES_APP_USER=golang-starter_app_user
POSTGRES_ADMIN_USER=golang-starter_app_administrator
POSTGRES_PASSWORD=olvidar
POSTGRES_DB=canary_health
POSTGRES_HOST=golang-starter-pgdb
POSTGRES_HOST_PORT=5435
SFTP_HOST=sftp
SFTP_HOST_PORT=2222
SFTP_USER=sftp-data
SFTP_PASS=password
SFTP_UID=1001
PROJECT_PATH=github.com/canary-health/golang-starter
AWS_SHARED_CREDENTIALS_FILE=/.aws/credentials
AWS_PGP_CIPHERTEXTBLOB=AQIDAHg5l/0VYhzTK60Wy2wfYn/KP8JRT1fRNGEzJc18l0Nb+wECP6cPIMYHXWkPYADCq0XxAAAAfjB8BgkqhkiG9w0BBwagbzBtAgEAMGgGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMczzcfZ1cObp5SCeQAgEQgDvwEgfGYlBbsOEMbJfg5jzpPHP/HpbcNm5qEOeJ8/PTt13AllhaiCHEZhlpEl0geWpYFYaU7KwnmZvQ3g==
AWS_BIDX_CIPHERTEXTBLOB=AQIDAHg5l/0VYhzTK60Wy2wfYn/KP8JRT1fRNGEzJc18l0Nb+wE+mO8UkfbUdyDDNzPAsy9QAAAAfjB8BgkqhkiG9w0BBwagbzBtAgEAMGgGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMPBibI85nohQhzQhAAgEQgDuHijQHbDRRNzHV0CWHWdBWzxjbSlkC6ZRmQtkzDnpROT8HEUZnbJnYWbBauAOmqcXhao1XbDO8hiy+7A==

########################
## Docker Image Name
########################
ifdef ECR_URI
	ifdef TAG
		IMAGE_NAME=--tag ${ECR_URI}:${TAG} --tag "${ECR_URI}:v.$(shell echo ${CODEBUILD_RESOLVED_SOURCE_VERSION} | head -c 8)" 
	endif
else
  IMAGE_NAME=${APP_NAME}
endif

ifndef CODEBUILD_SRC_DIR
	MIGRATION_PATH=$(GOPATH)/src/$(PROJECT_PATH)
else
	MIGRATION_PATH=$(CODEBUILD_SRC_DIR)
endif

ifndef TAG
	MIGRATION_DB_URL=postgres://${POSTGRES_ADMIN_USER}:${POSTGRES_PASSWORD}@localhost:${POSTGRES_HOST_PORT}/${POSTGRES_DB}?sslmode\=disable\&search_path\=${APP_NAME},public
else
	MIGRATION_DB_URL=$(shell echo $(shell aws ssm get-parameter --name /${TAG}/eli-server/MIGRATION_DB_URL --query "Parameter"."Value" --with-decryption))
endif

ifndef AWS_REGION
	AWS_REGION=us-east-1
endif
$(shell AWS_REGION=${AWS_REGION})
########################
## External Variables
########################
# 
## Docker Compose Only
#
$(shell echo IMAGE_NAME=${IMAGE_NAME} > .env) # ONLY FIRST ONE W/SINGLE >
$(shell echo PROJECT_PATH=${PROJECT_PATH} >> .env)
$(shell echo SERVER_HOST_PORT=${SERVER_HOST_PORT} >> .env)
$(shell echo API_HOST_PORT=${API_HOST_PORT} >> .env)
$(shell echo POSTGRES_USER=${POSTGRES_USER} >> .env)
$(shell echo POSTGRES_PASSWORD=${POSTGRES_PASSWORD} >> .env)
$(shell echo POSTGRES_DB=${POSTGRES_DB} >> .env)
$(shell echo POSTGRES_HOST_PORT=${POSTGRES_HOST_PORT} >> .env)
$(shell echo SFTP_UID=${SFTP_UID} >> .env)
#
## App Required
# 
$(shell echo APP_NAME=${APP_NAME} >> .env)
$(shell echo SERVER_URL="${SERVER_URL}" >> .env)
$(shell echo SERVER_ADDR="${SERVER_ADDR}" >> .env)
$(shell echo APP_DB_URL=postgres://${POSTGRES_APP_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:5432/${POSTGRES_DB}?sslmode\=disable\&search_path\=${APP_NAME},public >> .env)
$(shell echo AWS_PGP_CIPHERTEXTBLOB=${AWS_PGP_CIPHERTEXTBLOB} >> .env)
$(shell echo AWS_BIDX_CIPHERTEXTBLOB=${AWS_BIDX_CIPHERTEXTBLOB} >> .env)
$(shell echo AWS_SHARED_CREDENTIALS_FILE=${AWS_SHARED_CREDENTIALS_FILE} >> .env)
$(shell echo SFTP_HOST=${SFTP_HOST} >> .env)
$(shell echo SFTP_PORT=${SFTP_HOST_PORT} >> .env)
$(shell echo SFTP_USER=${SFTP_USER} >> .env)
$(shell echo SFTP_PASS=${SFTP_PASS} >> .env)

########################
## Helpers
########################
M=$(shell printf "\033[34;1m▶\033[0m")
TIMESTAMP := $(shell /bin/date "+%Y-%m-%d_%H-%M-%S")

sleep: 
	sleep 30

########################
## Start Commands
########################
.PHONY: all dev

all: pb build-server build-image ; $(info $(M) Initializing project complete... )

dev: compose-build sleep migrate-up ; $(info $(M) Setting up project development env complete...)

######
## Watch targets
######
.PHONY: watch-server watch-worker watch-api

watch-server: ; $(info $(M) Watching project server...)
	reflex -d none -sr "\.go$/" -- make build-run-server	

######
## Build & Run targets
######
build-run-server: build-server ; $(info $(M) Running project server...)
	./bin/$(APP_NAME)-server

######
## Build targets
######
build-server: ; $(info $(M) Building project server...)
	go build -o ./bin/$(APP_NAME)-server ./cmd/server

build-cli: ; $(info $(M) Building project cli...)
	go build -o ./bin/$(APP_NAME) ./cmd/cli

######
## Setup commands
######
.PHONY: dep

dep: ; $(info $(M) Ensuring vendored dependencies are up-to-date...)
	go mod vendor

######
## Docker commands
######
.PHONY: build-image build-cli-image build-server-image build-test-image run-container

build-image: ecr-login; $(info $(M) Building docker image...)
	docker build --tag $(IMAGE_NAME) .

build-cli-image: ecr-login ; $(info $(M) Building cli docker image...)
	docker build --file ./build/dkr/cli/Dockerfile $(IMAGE_NAME) .

build-server-image: ecr-login ; $(info $(M) Building server docker image...)
	docker build --file ./build/dkr/server/Dockerfile $(IMAGE_NAME) .

build-test-image: ecr-login ; $(info $(M) Building test docker image...)
	docker build --file ./build/dkr/test/Dockerfile .

run-container: ; $(info $(M) Running docker container...)
	docker run --env-file .env -p $(HOST_PORT):$(CONTAINER_PORT) $(IMAGE_NAME)

######
## Docker Compose commands
######
.PHONY: compose-build compose-up compose-down compose-test	

compose-build: dep ecr-login ; $(info $(M) Running application with docker-compose...)
	sudo docker-compose up -d --build

compose-up: ; $(info $(M) Running application with docker-compose...)
	sudo docker-compose up -d
	
compose-down: ; $(info $(M) Stopping application with docker-compose...)
	sudo docker-compose down

compose-test: ; $(info $(M) Running tests with docker-compose...)
	sudo docker-compose run --rm server make test

######
## Ship commands
######
.PHONY: ecr-login push-image

ecr-login: ; $(info $(M) Logging in to Amazon ECR...)
	$(shell aws ecr get-login --no-include-email --region ${AWS_REGION})

push-image: ecr-login ; $(info $(M) Pushing docker image...)
	docker push ${ECR_URI}

######
## Database commands
######
.PHONY: migrate-up migrate-force-up migrate-down

migrate-up: ;
	docker run --rm -v $(MIGRATION_PATH)/internal/database/migrations/:/migrations/ --network host migrate/migrate -path=/migrations/ -database=$(MIGRATION_DB_URL) up

migrate-down: ;
	docker run --rm -v $(MIGRATION_PATH)/internal/database/migrations/:/migrations/ --network host migrate/migrate -path=/migrations/ -database=$(MIGRATION_DB_URL) down

## Sets clean version in schema_migrations table. 
## Takes param v={{version}} e.g. v=400
migrate-force: ;
	docker run --rm -v $$GOPATH/src/$(PROJECT_PATH)/internal/database/migrations/:/migrations/ --network host migrate/migrate -path=/migrations/ -database $(MIGRATION_DB_URL) force $(v)

#####
## Protobuf commands
#####
.PHONY: pb 

pb: rm-pb; $(info $(M) Generating protobuf files ...)
	for dir in ./_rpc/*; do \
		go generate $$dir/gen.go; \
		echo Generating: $$dir; \
	done

######
## Test commands
######
.PHONY: test test-coverage test-coverage-html

test: rm-coverage ; $(info $(M) Running application tests...)
	retool do go test ./... -cover -covermode=count -coverprofile=coverage.out

test-coverage: ;
	go tool cover -func=coverage.out

test-coverage-html: ;
	go tool cover -html=coverage.out

######
## Clean up commands
######
.PHONY: clean rm-bin rm-pb rm-tools rm-coverage

clean: rm-bin rm-pb rm-tools rm-coverage; $(info $(M) Removing ALL generated files... )

rm-bin: ; $(info $(M) Removing ./bin files... )
	sudo rm -rf ./bin

rm-pb: ; $(info $(M) Removing generated protobuf files... )
	for tw in ./_rpc/**/*.twirp.go; do \
		$(RM) $$tw; \
		echo Removed: $$tw; \
	done
	for pb in ./_rpc/**/*.pb.go; do \
		$(RM) $$pb; \
		echo Removed: $$pb; \
	done
	for tw in ./api/swagger-spec/*.swagger.json; do \
		$(RM) $$tw; \
		echo Removed: $$tw; \
	done
	for tw in ./_rpc/ts_client/lib/*; do \
		$(RM) $$tw; \
		echo Removed: $$tw; \
	done

rm-vendor: ; $(info $(M) Removing ./vendor files... )
	sudo rm -rf ./vendor

rm-coverage: ; $(info $(M) Removing coverage.out files... )
	$(RM) ./coverage.out
