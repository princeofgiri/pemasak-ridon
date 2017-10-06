#!/usr/bin/expect

spawn ./sign.sh
expect " "
send "your key password here!!!!\n"

interact
