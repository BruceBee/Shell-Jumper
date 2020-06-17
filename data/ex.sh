                                                                                                                     90,35         44%
#!/usr/bin/expect

set ip [lrange $argv 0 0]
set port [lrange $argv 1 1]
set user [lrange $argv 2 2]
set time [exec date +%F-%T]
set passwd "xxxxxx"

spawn ssh -p $port user_account@$ip -i /home/$user/id_rsa
expect {
    "?" { send "yes\r" }
}

sleep 0.5
expect {
    ":" { send "$passwd\r" }
}
interact
