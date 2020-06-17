#!/bin/bash

# 非root、user1、user2账号(管理员、运维人员等)启用跳板机
[ $UID -ne 1001 ] && [ $UID -ne 0 ] && [ $UID -ne 1000 ] && sh /data/jumper.sh

# 非root、user1、user2账号(管理员、运维人员等)选择quit时直接退出
[ $UID -ne 1001 ] && [ $UID -ne 0 ] && [ $UID -ne 1000 ] && exit 1;
