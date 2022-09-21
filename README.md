# Upstreamable

Adding the support for multiple git up-streams to the projects.

## How to use

- Clone the 'Upstreamable' in the root of the project as the git submodule under the 'Upstreamable' directory
- In the root of the project create a directory called 'Upstreams'
- For each 'upstream' create proper upstream recipe.

## Recipes

The following example illustrates how recipe should look like (`GitFlic.sh`):

```shell
#!/bin/bash

export UPSTREAMABLE_REPOSITORY="git@gitflic.ru:red-elf/upstreamable.git"
```