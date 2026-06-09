FROM python:3.14-slim

LABEL org.opencontainers.image.title="repo_parser" \
      org.opencontainers.image.description="Parses OpenFeature SDK repos and reports spec compliance coverage" \
      org.opencontainers.image.source="https://github.com/open-feature/spec" \
      org.opencontainers.image.url="https://github.com/open-feature/spec/tree/main/tools/repo_parser" \
      org.opencontainers.image.vendor="OpenFeature" \
      org.opencontainers.image.licenses="Apache-2.0"

WORKDIR .

COPY ./spec_finder.py ./
VOLUME /appdir

ENTRYPOINT ["python", "spec_finder.py"]
