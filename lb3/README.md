Dieses File beinhaltet die Dokumentation der LB03 des Modul 300.

# Apache2, PHP Infrastruktur als Service (Docker)
Ich habe mit Hilfe von Docker einen Redin/Alpine Dienst installiert. Wird meine Docker-compose Datei ausgeführt, wird eine localhost Seite ghostet, auf dieser man dann sieht, wie viel mal die Seite aufgerufen wurde. Wenn man die Seite neu laded, steigt der Count. Ich konnte zum Glück viele Informationen von Youtube beziehen, was mir sehr geholfen hat.

### Inhaltsverzeichnis
1. [Verzeichnisstruktur](#Verzeichnisstruktur)
2. [Die Dockerdatei erklärt](#Die-Dockerdatei-erklärt)
3. [Die Pythondatei](#Die-Phytondatei)
4. [Die Docker-compose-Datei erklärt](#Die-Docker-compose-Datei-erklärt)
5. [Wie kann man den Dienst testen?](#Wie-kann-man-den-Diesnt-testen)

### Verzeichnisstruktur
Mein Repository ist wie folgt aufgebaut:
```
M300-Services/
  ├─ lb3/
     ├─ Anforderungen.txt
     ├─ Dockerfile
     ├─ README.md
     ├─ app.py
     ├─ docker-compose.yaml
```
### Die Dockerdatei erklärt
```
FROM python:3.7-alpine
WORKDIR /code
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0
RUN apk add --no-cache gcc musl-dev linux-headers
COPY Anforderungen.txt Anforderungen.txt
RUN pip install -r Anforderungen.txt
EXPOSE 5000
COPY . .
CMD ["flask", "run"]
```
Dieses Skript sagt Docker folgendes:
 - Docker soll mit dem Python 3.7 Image starten.
 - Das Workdirectory ist /code.
 - Es sagt flask, dass es app.py benutzen soll, sprich die Variablen werden      definiert.
 - GCC wird installiert.
 - Anschliessend wird die Anforderungen.txt Datei kopiert und deren Inhalt      installiert.
 - Durch die Metadaten EXPOSE wird der Port 5000 definiert.
 - Directory wird kopiert.
 - Der Standart Befehl wird definiert (flask, run)

### Die Pythondatei
```
import time

import redis
from flask import Flask

app = Flask(__name__)
cache = redis.Redis(host='redis', port=6379)

def get_hit_count():
    retries = 5
    while True:
        try:
            return cache.incr('hits')
        except redis.exceptions.ConnectionError as exc:
            if retries == 0:
                raise exc
            retries -= 1
            time.sleep(0.5)

@app.route('/')
def hello():
    count = get_hit_count()
    return 'Hello World! I have been seen {} times.\n'.format(count)
```

### Die Docker-Compose Datei erklärt
```
version: "3.9"
services:
  web:
    build: .
    ports:
      - "8000:5000"
  redis:
    image: "redis:alpine"
```
Diese Datei braucht man um den Dienst zu starten, bzw zu "bauen". Hier ist nochmals die Version definiert, sowie die Ports und welche Services verwendet werden.

### Wie kann man den Dienst testen?
Um den Dienst zu testen, muss man als ersten mein Repository M300-Services klonen. Danach muss man den Dockerclient starten und dann muss man in den lb3 Ordner wechseln. Wenn man das hat, muss man den Befehl "docker-compose up" eingeben. Nun wird der Dienst gestartet. Nun kann man in dem Browser "http://localhost:8000/" eingeben und dann sieht man schon den Counter. Wenn man die Seite aktualisiert, sollte sich dieser erhöhen.
