#!/bin/sh
################################################################################
: ${DIALOG=dialog}
    installdir=$0
    if [ $0  == './install.sh' ]; then
    installdir=`pwd`/install.sh 
    fi
    echo $installdir
    user=`whoami`
    if [ $user != "root" ]; then
    echo "Please, execute installation script as root user"
    exit 0
    fi
    echo "Prepearing installation process"
    if ! [ -d "/temp" ]; then  
    mkdir /temp 2>/dev/null
    fi
    tail -n +156 "$installdir" | head -n +697 > /temp/dialog-1.0.20051107-1.2.2.i386.rpm 
    echo EOF >> /temp/dialog-1.0.20051107-1.2.2.i386.rpm                         
    cd /temp
    rpm -i dialog-1.0.20051107-1.2.2.i386.rpm &>/dev/null 
    jbosshome="/opt/jboss"  
    jdk="/opt/jre1.6.0_04"   
    inform="
                                         JBOSS APPLICATION SERVER  
                JAVA DEVELOVEPMENT KIT
                POSTGRESQL DATABASE SERVER 
                STV APPLICATION"

$DIALOG --clear --title "THIS SCRIPT INSTALLING" --msgbox "$inform" 10 44

case $? in
   0)
    echo "OK";;
  255)
    echo "ESC pressed.";;
esac

(
    function forwrite()
    {
    if [ ! -z "$2" ]; then 
    echo "XXX";
    echo "$1"
    echo "XXX";
    pr=` expr $pr + $2`
    echo "$pr"
    else
    pr=` expr $pr + $1`
    echo "$pr"
    fi
    sleep 1;
    }
forwrite "Begin installation" "1"
    service postgresql stop 2>/dev/null
    service jboss stop 2>/dev/null
    tail -n +697 "$installdir" > /temp/install.tar.gz
    if [ -e install.tar.gz ]; then
forwrite "Extrcting file arhive" "10"
    tar -xzf install.tar.gz  &>/dev/null
    chmod -R 755 /temp 2>/dev/null
    else
    echo "Error not corectly creat arhive"
    exit 0
    fi
forwrite "JRE install" "15"
#Java begin install
    chmod -R 755 /temp/jre1.6.0_04 2>/dev/null
    cd /temp
    mkdir "$jdk" 2>/dev/null
    cp -R jre1.6.0_04/* "$jdk/" 2>/dev/null
    chmod -R 755 $jdk 2>/dev/null
    classpath=`cd $jdk ; pwd`/lib/rt.jar
    cd /temp
    echo "#!/bin/sh 
#   if [ -z \$JAVA_HOME ]; then
    export JAVA_HOME=$jdk
    export PATH=\$PATH:$jdk/bin
    export CLASSPATH=.:$classpath
#   fi" > /etc/profile.d/jre1.6.0_04.sh 2>/dev/null
    chmod 755 /etc/profile.d/jre1.6.0_04.sh 2>/dev/null
    `/etc/profile.d/jre1.6.0_04.sh 2>/dev/null`
#Java end install
#Postgresql begin Install
forwrite "Begin DataBase server Postgresql Install" "10"
      rm -rf /var/lib/pgsql/*
      rpm -i postgresql-libs-8.2.6-1PGDG.rhel5.i686.rpm 2>/dev/null
      rpm -i compat-postgresql-libs-4-1PGDG.rhel5.i686.rpm 2>/dev/null
      rpm -i postgresql-8.2.6-1PGDG.rhel5.i686.rpm 2>/dev/null
      rpm -i postgresql-devel-8.2.6-1PGDG.rhel5.i686.rpm 2>/dev/null
      rpm -i postgresql-server-8.2.6-1PGDG.rhel5.i686.rpm 2>/dev/null
      service postgresql initdb &>/dev/null
      cat /temp/conf/pg_hba.conf > /var/lib/pgsql/data/pg_hba.conf 2>/dev/null
      chown postgres:postgres /var/lib/pgsql/data/pg_hba.conf &>/dev/null
      chmod 600 /var/lib/pgsql/data/pg_hba.conf &>/dev/null
      service postgresql start &>/dev/null
forwrite "Creating PostgreSQL server role..." "7"
    su - postgres -c "psql -c \"create role itv login password 'v3Gm51pg' nosuperuser noinherit nocreatedb nocreaterole;\" postgres postgres &>/dev/null " &>/dev/null 
forwrite "Creating database STV..." "4"
    su - postgres -c "psql -c \"create database \\\"STV\\\" with owner = itv encoding = 'WIN1251' tablespace = pg_default;\" postgres postgres &>/dev/null " &>/dev/null 
forwrite "Restoring database..." "10"
    su - postgres -c "pg_restore -i -U postgres -d \"STV\" -v \"/temp/conf/STV.backup\" &>/dev/null "  &>/dev/null 
#Postgresql end install    
forwrite "Jboss application server Install" "25"
#Jboss begin install
    userdel -r jboss 2>/dev/null
    groupadd jboss 2>/dev/null
    adduser -g jboss jboss 2>/dev/null
    mkdir "$jbosshome" 2>/dev/null
    cd  /temp/jboss-4.2.2.GA
    cp -R /temp/jboss-4.2.2.GA/* "$jbosshome" 2>/dev/null
    chown -R jboss:jboss "$jbosshome" 2>/dev/null
forwrite "Installation successfully finished!" "18" 
) |
$DIALOG --title "Processing install..." --cr-wrap --gauge "Install" 10 40 0
    while : 
    do
$DIALOG --title "Enter ip address JBOSS application server listen on" --clear \
        --inputbox "" 16 51 2> /temp/ipaddress
    retval=$?
    case $retval in
    0)  
    if [ ! -z `cat "/temp/ipaddress" | grep -E '(^|[[:space:]])[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*([[:space:]]|$)'` ];
    then
    jbossaddr=`cat /temp/ipaddress`
    forhost="JBOSS_HOST=$jbossaddr"
    forhome="JBOSS_HOME=$jbosshome"
    echo "#!/bin/sh    
    export $forhost 
    export $forhome" > /etc/profile.d/jboss.sh
    chmod  755 /etc/profile.d/jboss.sh 2>/dev/null
    cat /temp/conf/jboss | awk '{gsub("1234567890","'$forhome'"); print;}' > /temp/conf/jbos
    cat /temp/conf/jbos | awk '{gsub("9876543210","'$forhost'"); print;}' > /temp/conf/jboss 2>/dev/null          
    cat /temp/conf/jboss > /etc/init.d/jboss 2>/dev/null
    chmod  755 /etc/init.d/jboss 2>/dev/null
    cp /temp/conf/APP.ear /opt/jboss/server/default/deploy/APP.ear 2>/dev/null
    chown root:root /opt/jboss/server/default/deploy/APP.ear 2>/dev/null
    chmod 644 /opt/jboss/server/default/deploy/APP.ear 2>/dev/null
    `/etc/profile.d/jboss.sh 2>/dev/null`
    chkconfig --add jboss 2>/dev/null
    chkconfig --level 0123456 jboss on 2>/dev/null
    service jboss start 2>/dev/null
#Jboss end install    
#   rm -rf /temp 
    break;
    fi
    ;;
    1)
    echo "Cancel pressed.";;
    255)
    ;;
    esac
    done
exit 1
