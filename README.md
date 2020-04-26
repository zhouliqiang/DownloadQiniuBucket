# 下载七牛云bucket文件脚本说明
存放在七牛云上的文件由于没有绑定备案域名而无法访问，可能需要备份这些文件。所以，根据七牛云的qrsctl工具，写了Shell脚本来批量下载文件。

这里只在macOS平台进行过测试，如果希望在其他平台上使用，还需要下载不同平台的qrsctl工具 https://developer.qiniu.com/kodo/tools/1300/qrsctl 。

#### 几点说明

##### 1、获取bucket输出处理

```bash
$ ./qrsctl buckets
[bucketname1 bucketname2 bucketname3 bucketname4 bucketname5]
```

这是一个单行文本，为了行处理，需要过滤头和尾的括号“[”和“]”：

```bash
$ sed -n 's/\[//;s/\]//p' | tr " " "\n"
```



##### 2、获取file list输出处理

```bash
$ ./qrsctl listprefix bucketname1 ''
marker:
filename1.jpg
filename2.png
filename3.mp3
```

这里需要去掉一行：

```bash
$ awk 'NR>1'
```



##### 3、文件名有空格的处理

从上面获取file list的输出，如果文件中没有文件名不含空格的话，可以使用while循环处理：

```bash
while read line
do
	# command
	echo $line
done
```

但是，如果文件名包含空格的话，因为空格需要转义，在while循环中，转义符号\不会保留。所以，这里改用了把文件名存储文件，读取文件for循环处理。

存储文件名之前，需要为文件名中的空格添加转义符号\：

```bash
$ awk '{gsub(" ", "\\ ")};{print $0}'
```

这里使用了awk的字符串函数gsub。

虽然这样处理了文件名，但在使用qrsctl下载文件的时候，由于命令格式的问题，依然会下载失败。

```bash
$./qrsctl get bucketname1 'file\ name\ with\ space.jpg' # 不支持的命令格式
```

为了处理失败的情况，这里把下载命令写入了重试Shell脚本文件，在最后再次执行此脚本下载。

