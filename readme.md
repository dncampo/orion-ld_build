# Intro

This repository implements a docker solution for the compilation of Orion-LD from sources, following the [tutorial](https://github.com/FIWARE/context.Orion-LD/blob/develop/doc/manuals-ld/installation-guide-ubuntu-18.04.3.md).


## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Build the Docker image
In order to build the image, just type the following in the directory where the Dockerfile is:

```
docker build -t orionld-dev . 
``````

## Usage
To start the container with libraries and ready to code, just type:

```
docker run -it -v <PATH_TO_HOST_FOLDER>/context.Orion-LD:/home/builder/git/context.Orion-LD <NAME_OF_DOCKER_IMAGE>
```

For Example:
```
docker run -it -v $HOME/code/fiware/orion-ld_build/src/context.Orion-LD:/home/builder/git/context.Orion-LD orionld-dev
```

If you need to enter to the container as root, you should add the `-u root` directive:

```
docker run -u root -it -v $HOME/code/fiware/orion-ld_build/src/context.Orion-LD:/home/builder/git/context.Orion-LD orionld-dev
```

## Contributing

Guidelines for how to contribute to this project

## License

This project is licensed under the [NAME HERE] License - see the LICENSE.md file for details
