FROM python:3.9-bullseye

WORKDIR /deploy

RUN apt-get update
RUN apt-get install -y --no-install-recommends git jq ca-certificates
RUN pip install web3 python-dotenv

COPY . /deploy/

COPY --from=ghcr.io/foundry-rs/foundry:latest /usr/local/bin/forge /usr/bin/

CMD [ "python", "deploy.py" ]