# golang-starter project

This layouts the basic directory structure for a project in Go

## Development with Docker

Initial:

```
make dev
```

and you will get a container running the app, db migrations run, and file watching for development.

Starting existing dev containers:

`make compose-up`

Rebuilding the container:

`make compose-build`

Stop and destory containers:

`make compose-down`

## See [Makefile](./Makefile) for more cmds

## Adding Dependancies

We are using [Go Modules](https://github.com/golang/go/wiki/Modules)

## Todos

- [x] Sample todo

# How to Document Architecture Decisions?

Create Architecture Decision Record using the following command

```
adr new Implement as Unix shell scripts
```

For more info go [here](https://github.com/npryce/adr-tools#quick-start)

# OSX

To generate the protocol buffers in osx please run the following

```
go install github.com/gogo/protobuf/protoc-gen-gogofast
go install github.com/gogo/protobuf/protoc-gen-gogofaster
```
