#!/usr/bin/env bash

kill `cat deck.pid`
kill `cat gate.pid`
kill `cat prom.pid`
kill `cat grafana.pid`
rm deck.pid gate.pid prom.pid grafana.pid
