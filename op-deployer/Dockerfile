FROM python:3.9.18-slim-bullseye

WORKDIR /deploy

RUN apt-get update
RUN apt-get install -y --no-install-recommends git jq
RUN pip install web3 python-dotenv

COPY . /deploy/

RUN mv /deploy/svm /root/.svm

COPY --from=ghcr.io/foundry-rs/foundry:latest /usr/local/bin/forge /usr/bin/

CMD [ "./deploy.sh" ]