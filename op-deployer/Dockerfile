FROM python:slim-bullseye

WORKDIR /deploy

RUN apt-get update
RUN apt-get install -y --no-install-recommends git jq
RUN pip install web3 python-dotenv 

COPY . /deploy/

COPY --from=ghcr.io/foundry-rs/foundry:nightly-6676e81e2eab70ac2924dd94182d10f2d606bfe2 /usr/local/bin/forge /usr/bin/

CMD [ "python", "deploy.py" ]