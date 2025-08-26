
#  Дипломная работа по профессии «Системный администратор»

Содержание
==========
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
    * [Сайт](#Сайт)
    * [Мониторинг](#Мониторинг)
    * [Логи](#Логи)
    * [Сеть](#Сеть)
    * [Резервное копирование](#Резервное-копирование)
    * [Дополнительно](#Дополнительно)
* [Выполнение работы](#Выполнение-работы)
* [Критерии сдачи](#Критерии-сдачи)
* [Как правильно задавать вопросы дипломному руководителю](#Как-правильно-задавать-вопросы-дипломному-руководителю) 

---------

## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/) и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. Используйте [инструкцию](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials).

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible.  

Не используйте для ansible inventory ip-адреса! Вместо этого используйте fqdn имена виртуальных машин в зоне ".ru-central1.internal". Пример: example.ru-central1.internal  - для этого достаточно при создании ВМ указать name=example, hostname=examle !! 

Важно: используйте по-возможности **минимальные конфигурации ВМ**:2 ядра 20% Intel ice lake, 2-4Гб памяти, 10hdd, прерываемая. 

**Так как прерываемая ВМ проработает не больше 24ч, перед сдачей работы на проверку дипломному руководителю сделайте ваши ВМ постоянно работающими.**

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Виртуальные машины не должны обладать внешним Ip-адресом, те находится во внутренней сети. Доступ к ВМ по ssh через бастион-сервер. Доступ к web-порту ВМ через балансировщик yandex cloud.

Настройка балансировщика:

1. Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

2. Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

3. Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

4. Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### Мониторинг
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix. 

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh.  Эта вм будет реализовывать концепцию  [bastion host]( https://cloud.yandex.ru/docs/tutorials/routing/bastion) . Синоним "bastion host" - "Jump host". Подключение  ansible к серверам web и Elasticsearch через данный bastion host можно сделать с помощью  [ProxyCommand](https://docs.ansible.com/ansible/latest/network/user_guide/network_debug_troubleshooting.html#network-delegate-to-vs-proxycommand) . Допускается установка и запуск ansible непосредственно на bastion host.(Этот вариант легче в настройке)

Исходящий доступ в интернет для ВМ внутреннего контура через [NAT-шлюз](https://yandex.cloud/ru/docs/vpc/operations/create-nat-gateway).

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.

### Дополнительно
Не входит в минимальные требования. 

1. Для Zabbix можно реализовать разделение компонент - frontend, server, database. Frontend отдельной ВМ поместите в публичную подсеть, назначте публичный IP. Server поместите в приватную подсеть, настройте security group на разрешение трафика между frontend и server. Для Database используйте [Yandex Managed Service for PostgreSQL](https://cloud.yandex.com/en-ru/services/managed-postgresql). Разверните кластер из двух нод с автоматическим failover.
2. Вместо конкретных ВМ, которые входят в target group, можно создать [Instance Group](https://cloud.yandex.com/en/docs/compute/concepts/instance-groups/), для которой настройте следующие правила автоматического горизонтального масштабирования: минимальное количество ВМ на зону — 1, максимальный размер группы — 3.
3. В Elasticsearch добавьте мониторинг логов самого себя, Kibana, Zabbix, через filebeat. Можно использовать logstash тоже.
4. Воспользуйтесь Yandex Certificate Manager, выпустите сертификат для сайта, если есть доменное имя. Перенастройте работу балансера на HTTPS, при этом нацелен он будет на HTTP веб-серверов.

## Выполнение работы
На этом этапе вы непосредственно выполняете работу. При этом вы можете консультироваться с руководителем по поводу вопросов, требующих уточнения.

⚠️ В случае недоступности ресурсов Elastic для скачивания рекомендуется разворачивать сервисы с помощью docker контейнеров, основанных на официальных образах.

**Важно**: Ещё можно задавать вопросы по поводу того, как реализовать ту или иную функциональность. И руководитель определяет, правильно вы её реализовали или нет. Любые вопросы, которые не освещены в этом документе, стоит уточнять у руководителя. Если его требования и указания расходятся с указанными в этом документе, то приоритетны требования и указания руководителя.

## Критерии сдачи
1. Инфраструктура отвечает минимальным требованиям, описанным в [Задаче](#Задача).
2. Предоставлен доступ ко всем ресурсам, у которых предполагается веб-страница (сайт, Kibana, Zabbix).
3. Для ресурсов, к которым предоставить доступ проблематично, предоставлены скриншоты, команды, stdout, stderr, подтверждающие работу ресурса.
4. Работа оформлена в отдельном репозитории в GitHub или в [Google Docs](https://docs.google.com/), разрешён доступ по ссылке. 
5. Код размещён в репозитории в GitHub.
6. Работа оформлена так, чтобы были понятны ваши решения и компромиссы. 
7. Если использованы дополнительные репозитории, доступ к ним открыт. 

## Как правильно задавать вопросы дипломному руководителю
Что поможет решить большинство частых проблем:
1. Попробовать найти ответ сначала самостоятельно в интернете или в материалах курса и только после этого спрашивать у дипломного руководителя. Навык поиска ответов пригодится вам в профессиональной деятельности.
2. Если вопросов больше одного, присылайте их в виде нумерованного списка. Так дипломному руководителю будет проще отвечать на каждый из них.
3. При необходимости прикрепите к вопросу скриншоты и стрелочкой покажите, где не получается. Программу для этого можно скачать [здесь](https://app.prntscr.com/ru/).

Что может стать источником проблем:
1. Вопросы вида «Ничего не работает. Не запускается. Всё сломалось». Дипломный руководитель не сможет ответить на такой вопрос без дополнительных уточнений. Цените своё время и время других.
2. Откладывание выполнения дипломной работы на последний момент.
3. Ожидание моментального ответа на свой вопрос. Дипломные руководители — работающие инженеры, которые занимаются, кроме преподавания, своими проектами. Их время ограничено, поэтому постарайтесь задавать правильные вопросы, чтобы получать быстрые ответы :)

## Решение

### Создание инфраструктуры

Для создания ифраструктуры использую Terraform.
Одновременно с созданием вируальных машин создаю VPC, Application Load Balanser и группы безопасности.

Terraform
![TerraformPlan](https://github.com/vonoid/Diplom-sys/blob/9c3b2f4466f4ef66eafe2b4d038c4586f2611e36/image/TerraformPlan.jpg)

VPC
![VPC](https://github.com/vonoid/Diplom-sys/blob/9c3b2f4466f4ef66eafe2b4d038c4586f2611e36/image/VPC.jpg)

Application Load Balanser
![ALB](https://github.com/vonoid/Diplom-sys/blob/9c3b2f4466f4ef66eafe2b4d038c4586f2611e36/image/ALB.jpg)

Health check
![ALB2](https://github.com/vonoid/Diplom-sys/blob/9c3b2f4466f4ef66eafe2b4d038c4586f2611e36/image/ALB2.jpg)

ALB map
![ALB3](https://github.com/vonoid/Diplom-sys/blob/9c3b2f4466f4ef66eafe2b4d038c4586f2611e36/image/ALB3.jpg)

Созданные виртуальные машины
![VM](https://github.com/vonoid/Diplom-sys/blob/9c3b2f4466f4ef66eafe2b4d038c4586f2611e36/image/VM.jpg)


### Ansible
Запуск Ansible произвожу на своей локальной машине.
Для каждой задачи создан свой плейбук.

Проверка доступности машин.
![ansible-ping](https://github.com/vonoid/Diplom-sys/blob/9c3b2f4466f4ef66eafe2b4d038c4586f2611e36/image/ansible-ping.jpg)

### Сайт
После деплоя данных на VM web1 и web2 проверяем их работу через балансировщик: http://130.193.58.35

web1
![web1](https://github.com/vonoid/Diplom-sys/blob/9c3b2f4466f4ef66eafe2b4d038c4586f2611e36/image/web1.jpg)

web2
![web2](https://github.com/vonoid/Diplom-sys/blob/9c3b2f4466f4ef66eafe2b4d038c4586f2611e36/image/web2.jpg)

### Мониторинг

### ZAbbix Server

Установка ZAbbix Server
![ZabbixServer](https://github.com/vonoid/Diplom-sys/blob/9c3b2f4466f4ef66eafe2b4d038c4586f2611e36/image/ZabbixServer.jpg)

Установка ZAbbix Agents
![ZabbixAgent](https://github.com/vonoid/Diplom-sys/blob/9c3b2f4466f4ef66eafe2b4d038c4586f2611e36/image/ZabbixAgent.jpg)

Сервер Zabbix доступен по адресу: http://158.160.116.65

Hosts
![Hosts](https://github.com/vonoid/Diplom-sys/blob/b9e3d0835e5c1f9e54eddc659f2ac28896230896/image/ZabbixServerHosts.jpg)

Dashboard с создвнными tresholds
![ZabbixServerDash1](https://github.com/vonoid/Diplom-sys/blob/b9e3d0835e5c1f9e54eddc659f2ac28896230896/image/ZabbixServerDash1.jpg)
![ZabbixServerDash2](https://github.com/vonoid/Diplom-sys/blob/b9e3d0835e5c1f9e54eddc659f2ac28896230896/image/ZabbixServerDash2.jpg)

### Логи

Установка Kibana через dpkg
![KibanaInstal](https://github.com/vonoid/Diplom-sys/blob/3209966ef9dc934e7bec376a27ed427537053c7a/image/KibanaInstal.jpg)

Установка Filebeat
![filebeat](https://github.com/vonoid/Diplom-sys/blob/3209966ef9dc934e7bec376a27ed427537053c7a/image/filebeat.jpg)

Проверка Filebeat c VM web1
![test out filebit from web1](https://github.com/vonoid/Diplom-sys/blob/99abe1718d23c34b87d618fc16ee3b1015272bec/image/test-out-filebit-from-web1.jpg)

Проверка Filebeat c VM web2
![test out filebit from web2](https://github.com/vonoid/Diplom-sys/blob/99abe1718d23c34b87d618fc16ee3b1015272bec/image/test-out-filebit-from-web2.jpg)

Установка Elasticsearch
![elk](https://github.com/vonoid/Diplom-sys/blob/3209966ef9dc934e7bec376a27ed427537053c7a/image/elk.jpg)

Проверка Elasticsearch
http://89.169.159.96:5601

![Elastik](https://github.com/vonoid/Diplom-sys/blob/3209966ef9dc934e7bec376a27ed427537053c7a/image/Elastik.jpg)

### Безопастность

Группы безопасности
![security-groups](https://github.com/vonoid/Diplom-sys/blob/3f16679a56f496a066cf182b3dc9b0612f910627/image/security-groups.jpg)

Примеры настроек
![security-groupsELK](https://github.com/vonoid/Diplom-sys/blob/3f16679a56f496a066cf182b3dc9b0612f910627/image/security-groupsELK.jpg)
![security-groupsWEB](https://github.com/vonoid/Diplom-sys/blob/3f16679a56f496a066cf182b3dc9b0612f910627/image/security-groupsWEB.jpg)

Резервное копирование
Создайте snapshot дисков всех ВМ по расписанию с временем жизни 7 дней
![snapshot-schedule](https://github.com/vonoid/Diplom-sys/blob/3f16679a56f496a066cf182b3dc9b0612f910627/image/snapshot-schedule.jpg)


Итоговая структура проекта:

```
ivan@ubuntu:~/diplom-infra$ tree
.
├── ansible
│   ├── ansible.cfg
│   ├── check-filebeat.yml
│   ├── elk-setup.yml
│   ├── filebeat-playbook.yml
│   ├── inventory
│   │   └── webservers.yml
│   ├── kibana-setup.yml
│   ├── roles
│   │   ├── elasticsearch
│   │   │   ├── files
│   │   │   ├── handlers
│   │   │   │   └── main.yml
│   │   │   ├── tasks
│   │   │   │   └── main.yml
│   │   │   └── templates
│   │   │       └── elasticsearch.yml.j2
│   │   ├── filebeat
│   │   │   ├── files
│   │   │   ├── handlers
│   │   │   │   └── main.yml
│   │   │   ├── tasks
│   │   │   │   ├── configure-filebeat.yml
│   │   │   │   ├── main.yml
│   │   │   │   └── main.yml.backup
│   │   │   └── templates
│   │   │       └── filebeat.yml.j2
│   │   ├── kibana
│   │   │   ├── files
│   │   │   ├── handlers
│   │   │   │   └── main.yml
│   │   │   ├── tasks
│   │   │   │   └── main.yml
│   │   │   └── templates
│   │   │       └── kibana.yml.j2
│   │   ├── nginx
│   │   │   ├── handlers
│   │   │   │   └── main.yml
│   │   │   ├── tasks
│   │   │   │   └── main.yml
│   │   │   └── templates
│   │   │       ├── index.html.j2
│   │   │       └── nginx.conf.j2
│   │   ├── zabbix-agent
│   │   │   ├── tasks
│   │   │   │   └── main.yml
│   │   │   └── templates
│   │   │       └── zabbix_agent2.conf.j2
│   │   └── zabbix-server
│   │       ├── handlers
│   │       │   └── main.yml
│   │       ├── tasks
│   │       │   └── main.yml
│   │       └── templates
│   │           ├── nginx.conf.j2
│   │           └── zabbix_server.conf.j2
│   ├── site.yml
│   ├── zabbix-agents.yml
│   └── zabbix.yml
├── backup
│   └── ansible
│       ├── ansible.cfg
│       ├── inventory
│       │   └── webservers.yml
│       ├── roles
│       │   └── nginx
│       │       ├── handlers
│       │       │   └── main.yml
│       │       ├── tasks
│       │       │   └── main.yml
│       │       └── templates
│       │           ├── index.html.j2
│       │           └── nginx.conf.j2
│       └── site.yml
├── key.json
└── terraform
    ├── bastion.tf
    ├── data.tf
    ├── loadbalancer.tf
    ├── monitoring.tf
    ├── private_subnets.tf
    ├── provider.tf
    ├── security_groups.tf
    ├── terraform.tfstate
    ├── terraform.tfstate.1755936947.backup
    ├── terraform.tfstate.1755937520.backup
    ├── terraform.tfstate.1755950988.backup
    ├── terraform.tfstate.1755964646.backup
    ├── terraform.tfstate.1755964647.backup
    ├── terraform.tfstate.backup
    ├── vpc.tf
    └── web.tf

39 directories, 54 files


```




