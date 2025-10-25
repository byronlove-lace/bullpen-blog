FROM python:3.11-alpine

ENV FLASK_APP=bullpen_blog.py
ENV FLASK_CONFIG=docker

WORKDIR /home/site

COPY requirements requirements
RUN pip install -r requirements/docker.txt

COPY app app
COPY migrations migrations
COPY config.py bullpen_blog.py boot.sh ./
RUN chmod +x boot.sh

# runtime configuration
EXPOSE 5000
ENTRYPOINT ["./boot.sh"]
