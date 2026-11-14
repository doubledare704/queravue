#!/bin/sh
# Seeds the dev Redis (docker-compose.yml, service redis-seed). It starts with
# FLUSHALL. Inline commands go through redis-cli --pipe; "\xNN" carries binary.
set -eu

host="${REDIS_HOST:-127.0.0.1}"
port="${REDIS_PORT:-6379}"
export REDISCLI_AUTH="${REDIS_PASSWORD:-queravue}"
pipe() { redis-cli -h "$host" -p "$port" --pipe >/dev/null; }

echo "seeding $host:$port"
redis-cli -h "$host" -p "$port" FLUSHALL >/dev/null

cat <<'COMMANDS' | pipe
ACL SETUSER viewer on >viewer ~* -@all +@read +@connection +info -memory|usage
SET str:plain "hello world"
SET str:utf8 "héllo €uro 日本語"
SET str:json "{\"id\": 1, \"tags\": [\"a\", \"b\"]}"
SET str:number 42
SET str:empty ""
SET "bin:blob" "\x00\x01\x02\xff\xfe\x80binary"
SET "bin:key:\x00\xff" "value of a binary key"
SET app:users:1:name "Ada"
SET app:users:2:name "Grace"
SET app:cache:session:42 "token-42"
SET app:cache:session:43 "token-43"
SET app:config:feature:dark-mode on
HSET hash:user:1 name Ada email ada@example.com age 36 city London
HSET app:users:1 name Ada role admin
HSET app:users:2 name Grace role dev
RPUSH list:queue job1 job2 job3 job4 job5
RPUSH app:jobs:pending a b c
SADD set:tags red green blue
SADD app:flags:enabled search export
ZADD zset:scores 10 alice 20 bob 30 carol 15.5 dave
ZADD app:leaderboard 100 ada 90 grace
XADD stream:events 1700000000000-0 type login user ada
XADD stream:events 1700000000001-0 type click user ada target button
XADD stream:events 1700000000002-0 type logout user ada
PFADD hll:visitors u1 u2 u3 u4 u5 u1 u2
SET ttl:short "expires in an hour"
EXPIRE ttl:short 3600
SET ttl:long "expires in a day"
EXPIRE ttl:long 86400
SET ttl:persistent "no expiry"
COMMANDS

awk 'BEGIN { for (i = 0; i < 40; i++) { s = ""; for (j = 0; j < 60000; j++) s = s "x"; print "APPEND str:large " s } }' | pipe

awk 'BEGIN { for (i = 1; i <= 1000000; i++) print "SET scan:" i " " i }' | pipe
awk 'BEGIN { for (i = 1; i <= 100000; i++) print "HSET big:hash field" i " value" i }' | pipe
awk 'BEGIN { for (i = 1; i <= 100000; i++) print "RPUSH big:list item" i }' | pipe
awk 'BEGIN { for (i = 1; i <= 100000; i++) print "ZADD big:zset " i " member" i }' | pipe

redis-cli -h "$host" -p "$port" DBSIZE
