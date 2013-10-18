#!/bin/sh
sqlite3=/usr/bin/sqlite3
db_openvz=openvz.db
# создаю таблицу tar в которой будет содержаться информация о всех бекапах
# это позволит автоматически созранять и удалять файлы
# 
DUMP_COMPRESSION="tar";  #none tar tar.bz2 tar.7z
DO_RESTART_VZ=1


$sqlite3 $db_openvz  "
create table IF NOT EXISTS  tar (
	id INTEGER UNIQUE,
	latest TEXT, 
	o7 TEXT,
	o6 TEXT, 
	o5 TEXT, 
	o4 TEXT, 
	o3 TEXT, 
	o2 TEXT, 
	o1 TEXT, 
	w1 TEXT, 
	w2 TEXT, 
	w3 TEXT, 
	w4 TEXT, 
	m1 TEXT, 
	m2 TEXT, 
	m3 TEXT, 
	m4 TEXT, 
	m5 TEXT, 
	m6 TEXT, 
	m7 TEXT, 
	m8 TEXT, 
	m9 TEXT, 
	m10 TEXT, 
	m11 TEXT, 
	m12 TEXT, 
	y1 TEXT, 
	y2 TEXT,


        latest_time TEXT,
        o7_time TEXT,
        o6_time TEXT,
        o5_time TEXT,
        o4_time TEXT,
        o3_time TEXT,
        o2_time TEXT,
        o1_time TEXT,
        w1_time TEXT,
        w2_time TEXT,
        w3_time TEXT,
        w4_time TEXT,
        m1_time TEXT,
        m2_time TEXT,
        m3_time TEXT,
        m4_time TEXT,
        m5_time TEXT,
        m6_time TEXT,
        m7_time TEXT,
        m8_time TEXT,
        m9_time TEXT,
        m10_time TEXT,
        m11_time TEXT,
        m12_time TEXT,
        y1_time TEXT,
        y2_time TEXT

);"

day=`date "+%j"`
month=`date "+%m"`
year=`date "+%Y"`
day=`expr $day - 1`
day=`expr $day + 1`

today="$day-$year"

#echo "day"
day=`expr $day - 1`


o1_cur_time="$day-$year"

day=`expr $day - 1`
o2_cur_time="$day-$year"

day=`expr $day - 1`
o3_cur_time="$day-$year"

day=`expr $day - 1`
o4_cur_time="$day-$year"

day=`expr $day - 1`
o5_cur_time="$day-$year"

day=`expr $day - 1`
o6_cur_time="$day-$year"

day=`expr $day - 1`
o7_cur_time="$day-$year"

echo "week"
day=`date "+%j"`
day=`expr $day - 7`
w1_cur_time="$day-$year"

day=`expr $day - 7`
w2_cur_time="$day-$year"

day=`expr $day - 7`
w3_cur_time="$day-$year"

day=`expr $day - 7`
w4_cur_time="$day-$year"

day=`date "+%j"`
#echo "month"

day=`expr $day - 30`
m1_cur_time="$day-$year"

day=`expr $day - 60`
m2_cur_time="$day-$year"

day=`expr $day - 90`
m3_cur_time="$day-$year"


m4_cur_time="$day-$year"
m5_cur_time="$day-$year"
m6_cur_time="$day-$year"
m7_cur_time="$day-$year"
m8_cur_time="$day-$year"
m9_cur_time="$day-$year"
m10_cur_time="$day-$year"
m11_cur_time="$day-$year"
m12_cur_time="$day-$year"




VZ_ROOT="/vz/private"
VZ_DUMP_ROOT="/vz/private/dump"

VZCTL="/usr/sbin/vzctl"

case $DUMP_COMPRESSION in 
"none")
	DO_RSYNC=0
	DO_TAR=0
	DO_TAR_RM=0
	DO_7ZIP=0
	DO_BZ2=0
	EXT_OF_FILE=""
	DO_FILE_ROTATION=0
;;
"tar")
	DO_RSYNC=1
	DO_TAR=1
	DO_TAR_RM=0
	DO_BZ2=0
	DO_7ZIP=0
	EXT_OF_FILE=".tar"
	DO_FILE_ROTATION=1
;;
"tar.bz2")
        DO_RSYNC=1
        DO_TAR=1
        DO_TAR_RM=1
        DO_BZ2=1
        DO_7ZIP=0
	EXT_OF_FILE=".tar.bz2"
	DO_FILE_ROTATION=1
;;
"tar.7z")
        DO_RSYNC=1
        DO_TAR=1
        DO_TAR_RM=1
        DO_BZ2=0
        DO_7ZIP=1
	EXT_OF_FILE=".tar.7z"
	DO_FILE_ROTATION=1
;;
*)
        DO_RSYNC=0
        DO_TAR=0
        DO_TAR_RM=0
        DO_7ZIP=0
        DO_BZ2=0
	EXT_OF_FILE=""
	DO_FILE_ROTATION=0
;;
esac


#DO_FILE_ROTATION=1


VZ_NotStop=() #пишем подряд контейнеры, которые будут в такой последовательности бекапиться

shopt -s extglob

if [ ! -d "$VZ_ROOT" ]; then
        mkdir -p $VZ_ROOT
fi
if [ ! -d "$VZ_DUMP_ROOT" ]; then
        mkdir -p $VZ_DUMP_ROOT
fi




cd $VZ_ROOT
date
echo "------------------------------------------------------------------------------------------------------------------------------------------------------"

for DIR in *
do
        if [  -d "$DIR" ]; then
                if [[ "$DIR" != +([0-9]) ]]; then
                        echo "Не сохраняю $DIR так как директория содержит буквы"
                else
                        NOT_BACKUP=0
                        for ((i=0; i<${#VZ_NotStop[@]}; i++)); do
                                if [ "${VZ_NotStop[$i]}" -eq "$DIR" ]; then
                                         NOT_BACKUP=1
                                fi
                        done

                        RUN_OUT=`vzlist |awk '{print $1}'|grep -v V|grep "\<$DIR\>"`
                        let " VZ_RUN = RUN_OUT + 0"

                        #Содержит значение текущей OVZ или пустую строку
                        if [ "$VZ_RUN"  -eq "$DIR" ]; then
                                VZ_IS_RUNNING=1
                        else
                                VZ_IS_RUNNING=0
                        fi


                         if [ "$NOT_BACKUP" -eq "1" ]; then
                                echo "$DIR не будет сохранено"
                         else

				LIST=`$sqlite3 $db_openvz  "SELECT * FROM tar  WHERE id=$DIR"`;
				n=0
				for ROW in $LIST; do
    					n=`expr $n + 1 `
    					id=`echo $ROW | awk '{split($0,a,"|"); print a[1]}'`
					latest=`echo $ROW | awk '{split($0,a,"|"); print a[2]}'`
					o7=`echo $ROW | awk '{split($0,a,"|"); print a[3]}'`
					o6=`echo $ROW | awk '{split($0,a,"|"); print a[4]}'`
					o5=`echo $ROW | awk '{split($0,a,"|"); print a[5]}'`
					o4=`echo $ROW | awk '{split($0,a,"|"); print a[6]}'`
					o3=`echo $ROW | awk '{split($0,a,"|"); print a[7]}'`
					o2=`echo $ROW | awk '{split($0,a,"|"); print a[8]}'`
    					o1=`echo $ROW | awk '{split($0,a,"|"); print a[9]}'`
					#    w1=`echo $ROW | awk '{split($0,a,"|"); print a[10]}'`
					#    w2=`echo $ROW | awk '{split($0,a,"|"); print a[11]}'`
					#    w3=`echo $ROW | awk '{split($0,a,"|"); print a[12]}'`
					#    w4=`echo $ROW | awk '{split($0,a,"|"); print a[13]}'`
					#    m1=`echo $ROW | awk '{split($0,a,"|"); print a[14]}'`
					#    m2=`echo $ROW | awk '{split($0,a,"|"); print a[15]}'`
					#    m3=`echo $ROW | awk '{split($0,a,"|"); print a[16]}'`
					#    m4=`echo $ROW | awk '{split($0,a,"|"); print a[17]}'`
					#    m5=`echo $ROW | awk '{split($0,a,"|"); print a[18]}'`
					#    m6=`echo $ROW | awk '{split($0,a,"|"); print a[19]}'`
					#    m7=`echo $ROW | awk '{split($0,a,"|"); print a[20]}'`
					#    m8=`echo $ROW | awk '{split($0,a,"|"); print a[21]}'`
					#    m9=`echo $ROW | awk '{split($0,a,"|"); print a[22]}'`
					#    m10=`echo $ROW | awk '{split($0,a,"|"); print a[23]}'`
					#    m11=`echo $ROW | awk '{split($0,a,"|"); print a[24]}'`
					#    m12=`echo $ROW | awk '{split($0,a,"|"); print a[25]}'`
					#    y1=`echo $ROW | awk '{split($0,a,"|"); print a[26]}'`
					#    y2=`echo $ROW | awk '{split($0,a,"|"); print a[27]}'`
					#######time##########
    					#latest_time=`echo $ROW | awk '{split($0,a,"|"); print a[28]}'`
					#   o7_time=`echo $ROW | awk '{split($0,a,"|"); print a[29]}'`
 					#   o6_time=`echo $ROW | awk '{split($0,a,"|"); print a[30]}'`
 					#   o5_time=`echo $ROW | awk '{split($0,a,"|"); print a[31]}'`
 					#   o4_time=`echo $ROW | awk '{split($0,a,"|"); print a[32]}'`
 					#   o3_time=`echo $ROW | awk '{split($0,a,"|"); print a[33]}'`
    					#o2_time=`echo $ROW | awk '{split($0,a,"|"); print a[34]}'`
    					#o1_time=`echo $ROW | awk '{split($0,a,"|"); print a[35]}'`
 					#   w1_time=`echo $ROW | awk '{split($0,a,"|"); print a[36]}'`
 					#   w2_time=`echo $ROW | awk '{split($0,a,"|"); print a[37]}'`
 					#   w3_time=`echo $ROW | awk '{split($0,a,"|"); print a[38]}'`
 					#   w4_time=`echo $ROW | awk '{split($0,a,"|"); print a[39]}'`
 					#   m1_time=`echo $ROW | awk '{split($0,a,"|"); print a[40]}'`
 					#   m2_time=`echo $ROW | awk '{split($0,a,"|"); print a[41]}'`
 					#   m3_time=`echo $ROW | awk '{split($0,a,"|"); print a[42]}'`
 					#   m4_time=`echo $ROW | awk '{split($0,a,"|"); print a[43]}'`
 					#   m5_time=`echo $ROW | awk '{split($0,a,"|"); print a[44]}'`
 					#   m6_time=`echo $ROW | awk '{split($0,a,"|"); print a[45]}'`
 					#   m7_time=`echo $ROW | awk '{split($0,a,"|"); print a[46]}'`
 					#   m8_time=`echo $ROW | awk '{split($0,a,"|"); print a[47]}'`
 					#   m9_time=`echo $ROW | awk '{split($0,a,"|"); print a[48]}'`
 					#   m10_time=`echo $ROW | awk '{split($0,a,"|"); print a[49]}'`
 					#   m11_time=`echo $ROW | awk '{split($0,a,"|"); print a[50]}'`
 					#   m12_time=`echo $ROW | awk '{split($0,a,"|"); print a[51]}'`
 					#   y1_time=`echo $ROW | awk '{split($0,a,"|"); print a[52]}'`
 					#   y2_time=`echo $ROW | awk '{split($0,a,"|"); print a[53]}'`
     
   					 echo "$id -> $latest -> $o1 -> $o2 ";
     
				done
				

                                echo "Сохраняю $DIR"
                                a=`date +%s`
                                if  [ "$VZ_IS_RUNNING"  -eq "1" ]; then
					echo "Остановка VZ: $DIR"
                                		$VZCTL stop $DIR  >/dev/null 2>&1
                                fi
			
				if [ "$DO_RSYNC" -eq "1" ]; then	
                                	nice -n -19 ionice -c1 rsync -acr --numeric-ids --force --delete-excluded  --delete-after  --max-delete=20000  $VZ_ROOT/$DIR $VZ_DUMP_ROOT  #>/dev/null 2>&1
				fi

                                if  [ "$VZ_IS_RUNNING"  -eq "1" ]; then
					 echo "Старт VZ: $DIR"
                                        $VZCTL start $DIR >/dev/null 2>&1
                                fi
                                b=`date +%s`
                                let "e = b -a"
                                if [ "$DO_RSYNC" -eq "1" ]; then
                                	echo "Сохранение $DIR заняло $e sec"
				fi

                             if  [ "$VZ_IS_RUNNING"  -eq "1" ]; then
                                echo "Архивирование начато"
                                a=`date +%s`
                                NAME=`date +%Y-%m-%d--%H-%M-%S`
				NAME=$today
                                TAR_NAME="$DIR.$NAME.tar"
                                TAR_NAME_FOR_7z="$DIR.$NAME.tar"
                                P7ZIP_DUMP="$VZ_DUMP_ROOT/$TAR_NAME_FOR_7z"
				if [ "$DO_TAR" -eq "1" ]; then
					rm $VZ_DUMP_ROOT/$TAR_NAME >/dev/null 2>&1
                                	nice -n 19 ionice -c3 tar --ignore-failed-read -cf $VZ_DUMP_ROOT/$TAR_NAME $DIR/  >/dev/null 2>&1
                                fi 

				c=`date +%s`
                                let "d = c -a"
				if [ "$DO_TAR" -eq "1" ]; then
	                                echo "Время работы tar $d sec"
				fi
                                
                                g=`date +%s`
				if [ "$DO_7ZIP" -eq "1" ]; then
                                	#нужно для 7zip#
					echo "Начинаю архивировать $TAR_NAME_FOR_7z.7z"
                                	# убрал так как есть только 1-н вариант либо тар, либо тар.бз2 либо тар.7з
						#nice -n 19 ionice -c3 cp $VZ_DUMP_ROOT/$TAR_NAME $VZ_DUMP_ROOT/$TAR_NAME_FOR_7z
					rm $VZ_DUMP_ROOT/$TAR_NAME_FOR_7z.7z >/dev/null 2>&1
	                                nice -n 19 ionice -c3 7z a -t7z -mx9   $VZ_DUMP_ROOT/$TAR_NAME_FOR_7z.7z  $P7ZIP_DUMP  >/dev/null 2>&1
				fi
                                c=`date +%s`
                                let "PKZIP = g -c"
                                if [ "$DO_7ZIP" -eq "1" ]; then
                                	echo "Время архивирования $TAR_NAME_FOR_7z.7z $PKZIP sec"
                                fi
				 echo "Архивирую $TAR_NAME.bz2"
                                u=`date +%s`
				if [ "$DO_BZ2" -eq "1" ]; then
					rm "$VZ_DUMP_ROOT/$TAR_NAME.bz2" >/dev/null 2>&1
                                	nice -n 19 ionice -c3 bzip2 $VZ_DUMP_ROOT/$TAR_NAME > /dev/null 2>&1
				fi

                                i=`date +%s`
                                let "BZIP = i -u"
				if [ "$DO_BZ2" -eq "1" ]; then
                                	echo "Время архивирования $TAR_NAME $BZIP sec"
                                fi
				b=`date +%s`
				if [ "$DO_TAR_RM" -eq "1" ]; then
                                	rm $VZ_DUMP_ROOT/$TAR_NAME > /dev/null 2>&1
				fi
                                #rm $P7ZIP_DUMP > /dev/null 2>&1
                                #rm $VZ_DUMP_ROOT/$DIR.latest.tar.bz2  > /dev/null 2>&1
                                #cp $VZ_DUMP_ROOT/$TAR_NAME.bz2 $VZ_DUMP_ROOT/$DIR.latest.tar.bz2  > /dev/null 2>&1
                                #rm $VZ_DUMP_ROOT/$TAR_NAME.bz2   > /dev/null 2>&1
                                #rm $VZ_DUMP_ROOT/$DIR.latest.7z
                                #mv $VZ_DUMP_ROOT/$TAR_NAME_FOR_7z.7z $VZ_DUMP_ROOT/$DIR.latest.7z
				if [ "$DO_FILE_ROTATION" -eq "1" ];then
					o1_curr_name="$VZ_DUMP_ROOT/$DIR.$o1_cur_time$EXT_OF_FILE"
					o2_curr_name="$VZ_DUMP_ROOT/$DIR.$o2_cur_time$EXT_OF_FILE"
					o3_curr_name="$VZ_DUMP_ROOT/$DIR.$o3_cur_time$EXT_OF_FILE"
					o4_curr_name="$VZ_DUMP_ROOT/$DIR.$o4_cur_time$EXT_OF_FILE"
					o5_curr_name="$VZ_DUMP_ROOT/$DIR.$o5_cur_time$EXT_OF_FILE"
					o6_curr_name="$VZ_DUMP_ROOT/$DIR.$o6_cur_time$EXT_OF_FILE"
					o7_curr_name="$VZ_DUMP_ROOT/$DIR.$o7_cur_time$EXT_OF_FILE"
					w1_curr_name="$VZ_DUMP_ROOT/$DIR.$w1_cur_time$EXT_OF_FILE"
					if [ "$o4" != "$o4_curr_name" ]; then
						echo "o4  $o4 != $o4_curr_name"
						rm $o4  > /dev/null 2>&1
						$sqlite3 $db_openvz  "insert into tar (id,o4) values ('$DIR','$o4_curr_name');" > /dev/null 2>&1 
						$sqlite3 $db_openvz "update tar SET o4='$o4_curr_name'  WHERE id='$DIR';" > /dev/null 2>&1  
						 
					fi
					if [ "$o3" != "$o3_curr_name" ]; then
						echo "o3  $o3 != $o3_curr_name"
						rm $o3  > /dev/null 2>&1
						$sqlite3 $db_openvz  "insert into tar (id,o3) values ('$DIR','$o3_curr_name');" > /dev/null 2>&1 
						$sqlite3 $db_openvz "update tar SET o3='$o3_curr_name'  WHERE id='$DIR';" > /dev/null 2>&1  
						 
					fi
					if [ "$o2" != "$o2_curr_name" ]; then
						echo "o2  $o2 != $o2_curr_name"
						rm $o2  > /dev/null 2>&1
						$sqlite3 $db_openvz  "insert into tar (id,o2) values ('$DIR','$o2_curr_name');" > /dev/null 2>&1 
						$sqlite3 $db_openvz "update tar SET o2='$o2_curr_name'  WHERE id='$DIR';" > /dev/null 2>&1  
						 
					fi
					if [ "$o1" != "$o1_curr_name" ]; then
						echo "o1  $o1 != $o1_curr_name"
						rm $o1  > /dev/null 2>&1
						$sqlite3 $db_openvz  "insert into tar (id,o1) values ('$DIR','$o1_curr_name');" > /dev/null 2>&1 
						$sqlite3 $db_openvz "update tar SET o1='$o1_curr_name'  WHERE id='$DIR';" > /dev/null 2>&1  
						 
					fi

				
				fi
                                let "e = b -a"
				if [ "$DO_BZ2" -eq "1" ]; then
                                	echo "Архивирование занало  $e sec  из них ==  BZIP: $BZIP sec"
				fi
                             fi

                         fi
                fi
        fi
done
if [ "$DO_RESTART_VZ" -eq "1" ]; then
	/etc/init.d/vz restart
fi

