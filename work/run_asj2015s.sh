#!/bin/sh

SCRIPT_PATH=../scripts

perl $SCRIPT_PATH/asj2015s_get_sessions.pl 2015spring_program.txt > asj2015s_sessions.json
perl $SCRIPT_PATH/asj2015s_get_data.pl 2015spring_program.tsv > asj2015s_data.json
perl $SCRIPT_PATH/asj2015s_merge.pl asj2015s_sessions.json asj2015s_data.json > asj2015s.json

