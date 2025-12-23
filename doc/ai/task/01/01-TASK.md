# Task: Use tool/agent version in image tag


## Information

### Base images
This project here `aicage-image` builds image by:
- the GitHub pipelines
- scripts/util/build.sh (for local testing only)

It uses base-images from other project 'aicage-image-base'. Those images tags have a prefix for the base and end with 
"-latest".

An example of a full base image name:tag is: `ghcr.io/aicage/aicage-image-base:fedora-latest` with `fedora` being the 
base. There currently are 8 bases. If you run tests, best use base `minimal` as it's the smallest.

### Final images

This project here `aicage-image` produces final images for tools/agents. Each subfolder of `tools` represents a tool.

For tool and each base-image detected, it builds an image (matrix: n bases * m tools).

It currently gives each image 2 tags - one with "-latest" and one with the projects tag/version (or `dev` for tests).

An example of a full final image name:tag is: `ghcr.io/aicage/aicage-image:codex-minimal-latest` with base `minimal` 
and tool `codex`. The same image would also be tagged as `ghcr.io/aicage/aicage-image:codex-minimal-0.2.3` with `0.2.3` 
being the git tag of `aicage-image`.

## Changes

### Change 1: Use tool version in docker image tags, not `aicage` git-tags

Each tool folder contains a `version.sh` script which prints the tools version. I want to use that version in the tags 
for docker images instead of the `aicage-image` git tag. So after this tag, with base `minimal`, tool `codex` and 
version of `codex` being `0.77.0` I would expect the image to have these 2 tags:
- `ghcr.io/aicage/aicage-image:codex-minimal-latest` (unchanged)
- `ghcr.io/aicage/aicage-image:codex-minimal-0.77.0` (new)

### Change 2: Use tool version in build pipelines

The build.yml pipeline currently builds one tool/base combination per run. It is triggered by:
- manually in GitHub
- from build-tool.yaml for a given tool (which in turn can be called from build-all.yml)
Those pipelines just build images form current codebase without regard to tool-version or such.

I need a new scheduled pipeline for a given tool.  
This new pipeline shall:
1) Loop over available base-image tags from `ghcr.io/aicage/aicage-image-base` with tags `<base>-latest`.
2) read tool version and see if an image in `ghcr.io/aicage/aicage` with tag `<tool>-<base>-<tool-version>` exists
   If it does not exist, trigger pipeline `build.yml` with tool and base.
3) Read and compare image layers
   If the image from 2) already exists, I want it to check if the last image layer of the base-image is in the layers of the final image.
   Use skopeo to read layers as in:
   ```shell
   skopeo inspect docker://ghcr.io/aicage/aicage:codex-fedora-latest | jq -r '.Layers[]'
   ```
   If the last layer of the base image is not in the final image, then the base-image changed and you shall also 
   trigger `build.yml`.
   `ghcr.io/aicage/aicage:codex-fedora-latest` is an image manifest containing amd64 and arm64 images. So maybe you 
   have to not use manifest or do something a bit different. To avoid fuck-ups you have to discuss your approach in this
   case and get my approval.

New pipeline triggering:
I want this new pipeline to run every 20 minutes, on new git-tags of the repo `aicage-image` or when triggered manually.

## Task Workflow

Don't forget to read AGENTS.md and always use the existing venv.

You shall follow this order:
1. Read documentation and code to understand the task. 
2. Aks me questions if something is not clear to you
3. Present me with an implementation solution - this needs my approval
4. Implement the change autonomously including a loop of running-tests, fixing bugs, running tests
5. Run linters as in the pipeline `.github/workflows/publish.yml`
6. Present me the change for review
7. Interactively react to my review feedback