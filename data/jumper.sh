#!/bin/bash

jumperPermission="/data/conf/jumperPermission"
jumperList="/data/conf/jumperList"
hostCount=0
permissionCount=0


# 加载全部IP列表
function loadHost(){
    while read line
    do
        if [[ "$line" =~ ^#.* ]]; then
            continue;
        else
            tmps[$hostCount]=$line
            let hostCount+=1
        fi
    done < $jumperList
#    echo ${tmps[@]}
}

# 加载用户登陆IP权限
function loadPermission(){
    OLD_IFS="$IFS"
    IFS="="

    while read line
    do
        if [[ "$line" =~ ^"$1".* ]]; then
            arry=($line)
            IFS="$OLD_IFS"
	    #echo ${arry[$*]}
            for var in ${arry[1]}
            do
                IFS=","
	        arry2=($var)
		for var2 in ${arry2[@]}
		do
		    tmpsPer[$permissionCount]=$var2
		    let permissionCount+=1
		   
		done
            done
	fi
    done < $jumperPermission
}


cc=0
# 获取用户登陆IP列表
function compare(){
    for i in ${tmpsPer[@]}
    do
        for j in ${tmps[@]}
	do
            if [[ "${j%%=*}" == "$i" ]]; then
                dd[$cc]=$j
                let cc+=1
            fi
        done 
    done
}

# 异常处理
function trapper(){
    trap '' INT QUIT TSTP TERM HUP
}



# 展示菜单
function menu(){
    ff=0

    echo -e "=========\033[44;37m `whoami` \033[0m, 欢迎您登录跳板机=========="	
    echo -e "现在是北京时间: " "\033[32m $(date "+%F %T") \033[0m"
    for d in ${dd[@]}
    do
   
	    echo -e "\033[32m ["$ff"] \033[0m" `echo $d | cut -d"=" -f1`  "\t\t\t"  
	    let ff+=1
      
    done
    wait
    echo -e "\033[31m [99]\033[0m  退出跳板机 "
    echo -e "\033[35m [111] 查询服务所在机器 \033[0m"
    echo -e "\033[31m 友情提示: 所有主机默认不操作300s即自动断开 \033[0m"
    echo -e "================================================"
}


# 检查输入内容
function checkInt(){
    if [[ $* == "" ]]; then
	echo 0
    else
	IntNum=`echo $* | sed 's/[0-9]//g'`
	if [[ $IntNum == "" ]];then
            echo 1
	else
            echo 0
	fi
    fi
}


remoteIdx=0
# 业务登陆逻辑处理
function host(){
    re=$(checkInt "$*")

    if [[ $re == 0  ]];then
	echo 1
    elif [[ $re == 1  ]] && [[ "${dd[$*]}" != ""  ]];then
	#echo ${dd[$*]}
	OLD_IFS="$IFS"
	IFS="="
	arry=(${dd[$*]})
	IFS="$OLD_IFS"
        
        for var in ${arry[1]}
	do
	    IFS=":"
	    arry2=($var)
	    for var2 in ${arry2[@]}
	    do
	        remoteHost[$remoteIdx]=$var2
		let remoteIdx+=1
            done
	done
	wait
        user=`whoami`
        echo  "${remoteHost[0]} ${remoteHost[1]} $user"
        
    elif [[ ${dd[$*]} == "" ]]; then
	echo 1
    else
	echo 1
    fi

}

# 入口
function main(){
  loadPermission `whoami`
  loadHost
  compare
  error=1
  while true
  do
    trapper
    clear
    menu
    read -p "请输入您要登陆的主机序号:" num
    
    if [[ $num == 111 ]]; then
        less /tmp/services.txt
    fi

    if [[ $num == 99 ]]; then
        break;
    else
        [ $error -gt 3 ] && echo "$(whoami)你好,请输入数字范围,否则你只能在这里, 谢谢合作 ~@ @~"
        res=$(host "$num")
	if [[ $res != 1 ]]; then

	    # 拆解返回值
	    OLD_IFS="$IFS"
	    IFS=" "
	    arry=($res IFS="$OLD_IFS")
           
	    echo ${arry[2]} $(date "+%F %T") ${arry[0]} "login" >> /usr/local/records/login.txt;
	   
	    error=0 
	    # 执行expect
            /usr/bin/expect /data/ex.sh $res
	    echo ${arry[2]} $(date "+%F %T") ${arry[0]} "logout" >> /usr/local/records/login.txt; 

        else
	    echo "[x]请输入正确选项"
	    sleep 1;
	fi

    fi	
    let error+=1
    sleep 0.1
  done
}


main
