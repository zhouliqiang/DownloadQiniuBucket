#!bin/bash
# 下载指定bucket的文件
# 确定登录
echo "please login, input qiniu.com user name:"
read USER_NAME
echo "password:"
read PASSWORD
# chmod +x qrsctl # Do you need?
./qrsctl login $USER_NAME $PASSWORD
[ $? -eq 0 ] && echo "login success+++++++++++++++++++++++++++"
# 获取bucket
echo "input bucket name:"
read BUCKET
# BUCKET='forgithub'
echo "start download files from BUCKET: $BUCKET >>>>>>>>>>>>>>>>>>>>>>>>>"
INDEX=1
RETRY_DOWNLOAD_COMMAND_FILE='retry_download_command_file.sh'
TEMP_FILE='temp_file.txt'
# 使用换行分隔符
IFS='
'
echo "START##################################"
# 处理输出文件信息，单行文本转化为多行，并处理空格
# FILES=`./qrsctl listprefix $BUCKET '' | awk 'NR>1'`
# echo $FILES | awk '{gsub("mp3 ","mp3#");gsub("jpg ","jpg#");gsub("jpeg ","jpeg#");gsub("png ","png#");gsub("mp4 ","mp4#");gsub("gif ","gif#");print $0}' | tr "#" "\n" | awk '{gsub(" ", "\\ ")};{print $0}' > $TEMP_FILE
./qrsctl listprefix $BUCKET '' | awk 'NR>1' | awk '{gsub(" ", "\\ ")};{print $0}' > $TEMP_FILE
# 创建下载失败处理脚本
echo "#!/bin/bash" > $RETRY_DOWNLOAD_COMMAND_FILE
echo "# 下载失败的文件将创建下载命令" >> $RETRY_DOWNLOAD_COMMAND_FILE
for ONE_FILE in `cat $TEMP_FILE`
do
    	echo "preparing to download >>>>>>>>>>>>>>>>>>>>>>>>>>>> $INDEX th file $ONE_FILE"
    	if [ ! -d $BUCKET ]
	then
			mkdir $BUCKET # 创建目录
	fi
	./qrsctl get $BUCKET $ONE_FILE ./$BUCKET/$ONE_FILE # 下载文件
	if [ $? -eq 0 ]
	then
		echo "$INDEX th file ##$ONE_FILE## download success+++++++++++++++++++++++++++"
	else
		echo "$INDEX th file ##$ONE_FILE## download failed---------------------------"
		echo "./qrsctl get $BUCKET $ONE_FILE ./$BUCKET/$ONE_FILE" >> $RETRY_DOWNLOAD_COMMAND_FILE
		echo "write retry download command to file----------------------------"
	fi
       	let INDEX=$INDEX+1
done

# 执行重试下载的脚本
echo "preparing to exec $RETRY_DOWNLOAD_COMMAND_FILE >>>>>>>>>>>>>>>>>>>>>>>>>>>>"
LINE_NUMBERS=`cat $RETRY_DOWNLOAD_COMMAND_FILE | wc -l`
echo "$RETRY_DOWNLOAD_COMMAND_FILE file LINE_NUMBERS = $LINE_NUMBERS"
[ $LINE_NUMBERS -gt 2 ] && sh +x $RETRY_DOWNLOAD_COMMAND_FILE
rm -f $RETRY_DOWNLOAD_COMMAND_FILE && rm -f $TEMP_FILE # 注释查看下载失败的文件
echo "##################################END"
