FROM python:3.11-alpine

ENV FLASK_APP=bullpen_blog.py
ENV FLASK_CONFIG=docker

RUN adduser -D bullpen-blog
USER bullpen-blog

WORKDIR /home/bullpen-blog

COPY requirements requirements
RUN python -m venv venv
RUN venv/bin/pip install -r requirements/docker.txt

COPY app app
COPY migrations migrations
COPY bullpen_blog.py config.py boot.sh ./

# runtime configuration
EXPOSE 5000
ENTRYPOINT ["./boot.sh"]
