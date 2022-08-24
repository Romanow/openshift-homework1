# Домашнее задание #1: Docker

## Формулировка

В рамках первого домашнего задания, требуется для приложения TODO List собрать backend и frontend части и запустить их в
docker.

* Приложение реализует простейший TODO list:
    * добавить заметку;
    * удалить заметку;
    * вывести все заметки.
* Backend написан на `Kotlin` + `Spring`, frontend написан на `Typescript` + `React/Redux`.
* Backend запускается на порту 8080, профиль `docker`.
* Backend для хранения данных использует PostgreSQL 13.
* Frontend мапится наружу на порт 3000, запросы к backend пробрасываются через `proxy_pass http://backend-service:8080`.

## Требования

* Для успешного выполнения задания нужно установить на host машину:
    * git;
    * OpenJDK 11;
    * Docker.
* Код backend'а и frontend'а хранится в отдельных репозиториях, они подключаются через Git Modules.
* Нужно реализовать двухэтапную сборку приложений, сборку контейнеров описать в
  файлах [backend.Dockerfile](backend.Dockerfile) и [frontend.Dockerfile](frontend.Dockerfile).
* В файле [test.sh](test.sh) дописать необходимые шаги:
    * `createNetworks`;
    * `createVolume`;
    * `runPostgres`;
    * `runBackend`;
    * `runFrontend`.
* Для хранения данных в Postgres нужно создать Volume.
* Внешний маппинг портов:
    * backend 8080:8080;
    * frontend 3000:80.
* Нужно создать две _разных_ сети (`driver=bridge`):
    * для взаимодействия между backend и PostgreSQL;
    * для взаимодействия backend и frontend (для этой сети указать alias для контейнера backend `backend-service`, т.к.
      nginx обращается через proxy_pass к `http://backend-service:8080`).
* Docker compose использовать нельзя, все ресурсы описываются через docker.
* Контейнеры называть `backend`, `frontend`, `postgres`.
* В результате реализации всех описанных выше шагов, должна быть возможность работать TODO list с `localhost:3000`, т.е.
  можно открыть страницу в браузере и проверить работу.
* Для автоматизированной проверки работоспособности выполняется запрос из контейнера frontend в контейнер backend по
  имени сервиса.

## Пояснения

* Для сборки затяните `backend-todo-list` и `backend-todo-list` с помощью
  команды `git submodule update --init --recursive`.
* Backend нужно запустить с профилем `docker`. Для этого требуется внутрь контейнера пробросить переменную
  среды `SPRING_PROFILES_ACTIVE=docker`.
* Для очистки ресурсов можно использовать [cleanup.sh](cleanup.sh), он удаляет контейнеры, сети, volumes.
* Для backend нужно в Postgres создать БД `todo_list` и пользователя `program`:`test`. Здесь можно использовать два
  варианта решения:
    * Можно создать пользователя и БД с помощью переменных среды `POSTGRES_*` при старте
      контейнера [Postgres](https://hub.docker.com/_/postgres). Это рабочий вариант, но созданный пользователь будет
      иметь права SUPERUSER, что плохо с точки зрения безопасности.
    * Обычно для работы с приложением создают отдельного пользователя. В образе Postgres есть возможность использовать
      скрипты инициализации для _первого страта контейнера_ (блок Initialization scripts
      в [документации](https://hub.docker.com/_/postgres)). В backend есть пример такого запуска контейнера Postgres с
      помощью [docker-compose.yml](backend/docker-compose.yml): при старте контейнера создается пользователь с правами
      SUPERUSER, а в `10-create-user-and-db.sql` создается отдельная БД и пользователь для нее. Это нужно, чтобы
      программа работала с пользателем, ограниченным в правах.