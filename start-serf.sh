#!/bin/bash
exec serf agent -tag role=haproxy -join $SERF_1_PORT_7946_TCP_ADDR:$SERF_1_PORT_7946_TCP_PORT -event-handler=/handlers/xlb.lisp
