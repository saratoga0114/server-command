#!/bin/sh

########## usage() ##########
usage(){
  echo ""
  echo "Usage: backup_db.sh"
  exit 1
}

# backup file type
FILE_TYPE="zip"
ZIP="zip"
TAR="tar zcvf"

# s3
S3_BUCKET="xxxxxxxxxx"

# db
DB_NAME="test"
MYSQLDUMP="mysqldump --defaults-extra-file=/etc/.my.cnf"

# dir
NOW=`date '+%Y%m%d%H%M%S'`
YYYYMM=`date '+%Y%m'`
BACKUP_DIR="/tmp/backup/db"

if [ ! -d "${BACKUP_DIR}" ]; then
  mkdir -p ${BACKUP_DIR}
fi

# The table name is written line by line in table_list.txt
while read table; do
  echo ${table}

  # dump
  if [ "${table}" != "" ]; then
    ${MYSQLDUMP} ${DB_NAME} ${table} > ${BACKUP_DIR}/${NOW}_${table}.sql
  fi
done < `cat table_list.txt`

# archive
cd ${BACKUP_DIR}

if [ -f ${BACKUP_DIR}/db.zip ]; then
  rm -f ${BACKUP_DIR}/db.zip
fi

if [ -f ${BACKUP_DIR}/db.tar.gz ]; then
  rm -f ${BACKUP_DIR}/db.tar.gz
fi

if [ ${FILE_TYPE} = "zip" ]; then
  ${ZIP} ${BACKUP_DIR}/db.zip ${BACKUP_DIR}/${NOW}_*.sql
  aws s3 cp ${BACKUP_DIR}/db.zip s3://${S3_BUCKET}/${YYYYMM}/${DB_NAME}_${NOW}.zip
else
  ${TAR} ${BACKUP_DIR}/db.tar.gz ./${NOW}_*.sql
  aws s3 cp ${BACKUP_DIR}/db.tar.gz s3://${S3_BUCKET}/${YYYYMM}/${DB_NAME}_${NOW}.tar.gz
fi

# clean
find ${BACKUP_DIR} -type f -ctime +1 | xargs rm
