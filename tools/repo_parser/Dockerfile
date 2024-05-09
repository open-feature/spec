FROM cgr.dev/chainguard/python:latest

WORKDIR .

COPY ./spec_finder.py ./
VOLUME /appdir

ENTRYPOINT ["python", "spec_finder.py"]
