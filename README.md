# ci-java

CI container image for my self-hosted [Forgejo runner](https://code.forgejo.org/forgejo/runner): `node:26-bookworm` with the official [Eclipse Temurin](https://adoptium.net/) JDKs **21** and **25** preinstalled.

```
ghcr.io/bacherik/ci-java
```

## Why

Java jobs on my runner used `actions/setup-java`, which downloads a ~200 MB JDK from GitHub on every run. That download sometimes stalls, `setup-java` times out and retries, and then the step never exits. The job sits idle until the runner kills it after an hour.

This image ships the JDKs, so Java jobs don't download anything at runtime and don't need `setup-java` at all.

## What's inside

|        |                                                                                                    |
| ------ | -------------------------------------------------------------------------------------------------- |
| Base   | `node:26-bookworm`, the same image as the plain `bacherik` label, so every JS action keeps working |
| JDK 21 | `/usr/lib/jvm/temurin-21`, the default (`JAVA_HOME`, `PATH`)                                       |
| JDK 25 | `/usr/lib/jvm/temurin-25`                                                                          |
| Env    | `JAVA_HOME`, `JAVA_HOME_21_X64`, `JAVA_HOME_25_X64`                                                |

The JDKs are copied unchanged from the official `eclipse-temurin` images (multi-stage build). They live under `/usr/lib/jvm` because Gradle looks there automatically when it searches for toolchains, so Gradle finds them without downloading via foojay.

## Tags

| Tag          | Meaning                                                               |
| ------------ | --------------------------------------------------------------------- |
| `YYYY.MM.DD` | Immutable build from that day. **Use this one in the runner config.** |
| `latest`     | Most recent build.                                                    |

## Updates

- **Renovate** bumps the `FROM` tags in the `Dockerfile` (Temurin and Node patch releases, automerged). Major versions are ignored, so 21 stays 21 and 25 stays 25.
- **A weekly scheduled build** (Monday 05:00 UTC) rebuilds the image so it picks up Debian and Node base image security fixes.
- In BachGitOps, a Renovate custom manager bumps the date tag in the runner config.

### Adding or changing a JDK

1. Add a stage `FROM eclipse-temurin:<version>-jdk AS jdk<major>` to the `Dockerfile`.
2. `COPY --from=jdk<major> /opt/java/openjdk /usr/lib/jvm/temurin-<major>`
3. Add `JAVA_HOME_<major>_X64` and the `java -version` check.

## Usage

### Runner config

```yaml
runner:
  labels:
    - "bacherik:docker://node:26-bookworm"
    - "bacherik-java:docker://ghcr.io/bacherik/ci-java:2026.11.18"
```

Renovate custom manager in `renovate.json`:

```json
{
  "customType": "regex",
  "description": "ci-java runner image tag",
  "managerFilePatterns": ["/apps/forgejo-runner/config\\.yaml$/"],
  "matchStrings": [
    "docker://(?<depName>ghcr\\.io/bacherik/ci-java):(?<currentValue>\\d{4}\\.\\d{2}\\.\\d{2})"
  ],
  "datasourceTemplate": "docker",
  "versioningTemplate": "loose"
}
```

### Workflow

```yaml
jobs:
  build:
    runs-on: bacherik-java
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4

      - uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties', 'gradle.properties') }}
          restore-keys: gradle-

      - run: ./gradlew build --console=plain
```

To check which JDKs Gradle detects, run `./gradlew -q javaToolchains`.