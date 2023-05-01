# Momo Store aka Пельменная №2

<img width="900" alt="image" src="https://user-images.githubusercontent.com/9394918/167876466-2c530828-d658-4efe-9064-825626cc6db5.png">

## Интерфейсы
**Магазин:** https://momo-store.std-011-009.ru/  
**Мониторинг:** https://grafana.std-011-009.ru/

## Репозиторий
```
momo-store
 |- backend        - исходный код бэкэнда
 |- frontend       - исходный код фронтэнда
 |- infra
     |- data       - данные для работы приложения (картинки)
     |- helm       - хелм чарты
     |- kubernetes - остальные ресурсы для k8s
     |- terraform  - описание облачной инфраструктуры
```

Деплой осуществляется автоматизировано в указанный k8s кластер (параметры подключения задаются в переменной KUBECONFIG).  
Образы бэкэнда и фронтенда хранятся в container registry непосредственно в [gitlab](https://gitlab.praktikum-services.ru/std-011/momo-store/container_registry).  
Хелм чарты бэкэнда и фронтенда хранятся в [nexus](https://nexus.praktikum-services.ru) репозитории.   
Статический анализ кода осуществляется с помощью [sonarqube](https://sonarqube.praktikum-services.ru/).  
Версионирование бэкэнда и фронтенда автоматическое при внесении изменений (используется ID пайплайна), версии чартов необходимо менять вручную.

## Локальный запуск
**Frontend**
```bash
npm install
NODE_ENV=production VUE_APP_API_URL=http://localhost:8081 npm run serve
```
**Backend**
```bash
go run ./cmd/api
go test -v ./... 
```

## Развертывание приложения
0. Установить terraform, kubectl и helm. Приобрести облако на YC.

1. Заполнить переменные terraform в соотвествии с параметрами подключения к облаку (cloud_id, folder_id, availability_zone).

2. Развернуть требуемые ресурсы в облаке с помощью terraform (если есть s3 для хранения состояния terraform, 
то указать необходимые ключи для доступа в versions.tf)

3. После применения скриптов terraform в облако будут добавлены необходимые сервисные аккаунты, 
managed service и группа узлов для k8s, а также s3 storage для хранения данных из [infra/data](infra/data). 

4. Выполнить shell скрипты из [infra/kubernetes](infra/kubernetes) (текущий контекст kubectl должен соответствовать созданному k8s кластеру) - в кластер будут добавлены ингресс контроллер и менеджер сертификатов. Добавить ресурсы [acme-issuer.yaml](infra/kubernetes/acme-issuer.yaml) и [admin-user.yaml](infra/kubernetes/admin-user.yaml) с помошью kubectl.

5. В CI/CD переменные (KUBECONFIG) добавить параметры подключения для вновь созданного k8s кластера, стоит воспользоваться созданным на предыдущем шаге admin аккаунтом.

6. Адаптировать helm чарты под требуемые условия (например, доменное имя), обновить версии для бэкэнда и фронтенда в nexus, остальные чарты можно применять непосредственно для созданного k8s кластера в любом порядке.

7. Запустить пайплайн бэкенда и фронтенда.

## TODO
- разбить [infra/terraform](infra/terraform) на модули
- вынести [infra/kubernetes](infra/kubernetes) в отдельный хелм чарт
- сделать CI/CD для хелм чартов в [infra/helm](infra/helm)
- добавить хелм чарт для alertmanager