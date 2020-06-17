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
	    
            #permission=(${"$line"//=/})
            #echo $permission

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
            if [[ "$j" =~ ^"$i".* ]]; then
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

    echo "========= `whoami`, 欢迎登陆跳板机=========="	
    for d in ${dd[@]}
    do
	echo "["$ff"]" $d
	let ff+=1
    done
    echo "[99] 退出跳板机"
    echo "============================================"
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
  while true
  do
    trapper
    clear
    menu
    read -p "请输入您要登陆的主机序号:" num

    if [[ $num == 99 ]]; then
        break;
    else
        res=$(host "$num")
	if [[ $res != 1 ]]; then

	    # 拆解返回值
	    OLD_IFS="$IFS"
	    IFS=" "
	    arry=($res IFS="$OLD_IFS")

	    # 执行expect
            exec /usr/bin/expect /data/ex.sh $res
        else
	    echo "[x]请输入正确选项"
	    sleep 1;
	fi

    fi	
  done
}


main
