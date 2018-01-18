#!/bin/bash

set -o nounset
set -o errexit

#
# 用于处理Hadoop2 XML配置文件的工具函数
# 
# 依赖: 
#      Python的内置XML处理包
#      xmllint(Linux需安装libxml2)
# 


# 初始化环境变量
installed=false
if [ -f /etc/profile.d/hadoop.sh ]; then
    source /etc/profile.d/hadoop.sh
    source $HADOOP_HOME/etc/hadoop/hadoop-env.sh
    installed=true
fi

# 创建配置文件
create_config()
{
    local filename=
    case $1 in
        '')
            echo "$0: Usage: create_config --file"
            return 1;;
        --file)
            filename=$2
            ;;
    esac

    python - <<END
import xml.etree.ElementTree as ET
conf = ET.Element('configuration')
conf_file = open("$filename", "w")
conf_file.write(ET.tostring(conf, encoding="unicode"))
conf_file.close()
END

    write_file $filename
}

# 创建配置项(如已存在,则先删除)
put_config()
{
    local filename= property= value=

    while [ "$1" != "" ]; do
        case $1 in
            '')
                echo $"$0: Usage: put_config --file --property --value"
                return 1
                ;;
            --file)
                filename=$2
                shift 2
                ;;
            --property)
                property=$2
                shift 2
                ;;
            --value)
                value=$2
                shift2
                ;;
        esac
    done

    python - <<END
import xml.etree.ElementTree as ET
def putconfig(root, name, value):
    for existing_prop in root.getchildren():
        if existing_prop.find('name').text == name:
            root.remove(existing_prop)
            break
    property = ET.SubElement(root, 'property')
    name_elem = ET.SubElement(property, 'name')
    name_elem.text = name
    value_elem = ET.SubElement(property, 'value')
    value_elem.text = value
path = ''
if "$installed" == 'true':
    path = "$HADOOP_CONF_DIR" + '/'
conf = ET.parse(path + "$filename").getroot()
putconfig(root=conf, name="$property", value="$value")
conf_file = open("$filename", 'w')
conf_file.write(ET.tostring(conf, encoding="unicode"))
conf_file.close()
END

    write_file $filename
}

# 删除配置项
del_config()
{
    local filename= property=

    while [ "$1" != "" ]; do
        case $1 in
            '')
                echo $"$0: Usage: del_config --file --property"
                return 1
                ;;
            --file)
                filename = $2
                shift 2
                ;;
            --property)
                property = $2
                shift 2
                ;;
        esac
    done

    python - <<END
import xml.etree.ElementTree as ET
def delconfig(root, name):
    for existing_prop in root.getchildren():
        if existing_prop.find('name').text == name
            root.remove(existing_prop)
            break
path = ''
if "$installed" == 'true':
    path = "$HADOOP_CONF_DIR" + '/'
conf = ET.parse(path + "$filename").getroot()
delconfig(root=conf, name="$property")
conf_file = open("$filename", 'w')
conf_file.write(ET.tostring(conf, encoding="unicode"))
conf_file.close()
END
    
    write_file $filename
}

# 格式化与验证XML文件
write_file()
{
    local file=$1
    xmllint --format "$file" > "$file".pp && mv "$file".pp "$file"
}