---
id: en-docker
title: Containers and Docker Workflows
language: en
family: devops
---
Containers package a process with its complete userland — dependencies, configuration, filesystem — and run it isolated on the host kernel. They start in milliseconds and cost megabytes, which is why the unit of deployment moved from "a server someone configured" to "an image anyone can run". Environment drift between development, CI, and production simply stops existing.

A Dockerfile builds an image as a stack of cached layers. Layer ordering is the first optimization every developer learns: copy dependency manifests and install packages before copying source code, so code changes don't invalidate the dependency cache. Multi-stage builds take it further — compile in a full toolchain image, copy only the artifact into a minimal runtime image, ship something a tenth the size with a fraction of the attack surface.

Swift developers meet Docker twice. Deploying Vapor: official Swift images build Linux binaries, and a two-stage Dockerfile is the standard template. Local development: databases and queues run as disposable containers (`docker run postgres`), and Docker Compose declares the whole service constellation in one file — `docker compose up` replaces a wiki page of setup instructions.

Production hygiene: pin base image versions, run as non-root, inject secrets at runtime (never bake them into layers), and scan images in CI.
