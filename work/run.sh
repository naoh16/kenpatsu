#!/bin/sh

perl ../scripts/asj_txt2csv.pl < 2014autumun_program.txt > asj2014a.json
cp -a asj2014a.json ../viewer_app/www/asj2014a.json
