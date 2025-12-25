# Task 02: Use release artifacts to determine available bases

## Current Situation

This project `aicage-image` is a submodule of `aicage`.
The other submodule `aicage-image-base` (in `/home/stefan/development/github/aicage/aicage/aicage-image-base`) builds
base docker images which this project here uses to build final images.

### Current base image lookup

This project currently performs an online lookup to see which base images are actually available.  
This uses a naming pattern: It searches for `ghcr.io/aicage/aicage-image-base:*-latest` where the "*" is the alias for a
base image.  
The result is a list of base-image aliases like: "fedora", "debian", "alpine", "minimal", etc.

## Target Situation

The submodule `aicage-image-base` now has a new release pipeline in `.github/workflows/release.yml` which creates a 
GitHub release for any new tag and stores a `bases.tar.gz` as artifact in it.

This project `aicage-image` here can now use the `bases.tar.gz` from the `latest` release of `aicage-image-base` to
determine available base-images. This method can fully replace the online image registry queries for base-images.

The only time when this can go wrong is where a single final image is built:
- .github/workflows/build.yml
- scripts/util/build.sh (for local tests only)

There it may happen that a base-image from the `bases.tar.gz` does not exist in the image registry. If that happens it's
ok for the pipeline run or the build.sh to crash hard. As the pipeline builds only one final image, all other images are 
not affected.

### Contents of a `bases.tar.gz`

Look at the other submodule `aicage-image-base`. `bases.tar.gz` contains everything in the other submodules `bases` 
folder and there the logic is that only subfolders are allowed and each subfolder name is an alias for a base-image.  
Simple, no extra bogus checking needed.

## Task Workflow

Don't forget to read AGENTS.md and always use the existing venv.

You shall follow this order:
1. Read documentation and code to understand the task. 
2. Aks me questions if something is not clear to you
3. Present me with an implementation solution - this needs my approval
4. Implement the change autonomously including a loop of running-tests, fixing bugs, running tests
5. Run linters as in the pipeline `.github/workflows/build.yml`
6. Present me the change for review
7. Interactively react to my review feedback