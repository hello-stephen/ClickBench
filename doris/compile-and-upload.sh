#!/bin/bash
set -e

DORIS_HOME="/home/ec2-user/selectdb-core/"
BUILD_TYPE=release
# BUILD_TYPE=asan
sudo docker pull apache/doris:build-env-ldb-toolchain-latest
date
sudo docker run -it --rm \
    --name doris_compile_"$(date +%s)" \
    -e BUILD_TYPE=$BUILD_TYPE \
    -e USE_MEM_TRACKER=OFF \
    -v /home/ec2-user/.m2:/root/.m2 \
    -v ${DORIS_HOME}:${DORIS_HOME} \
    apache/doris:build-env-ldb-toolchain-latest \
    bash -c "${DORIS_HOME}/build.sh  --be --fe -j10"
date

sudo chown -R ec2-user:ec2-user $DORIS_HOME

cd ${DORIS_HOME}/output
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
branch_name=$(git symbolic-ref --short HEAD)
commit_id=$(git rev-parse --short HEAD)
package_dirname="${branch_name}-${commit_id}-release-${TIMESTAMP}"
tar_file_name="${package_dirname}.tar.gz"

tar_file_name="selectdb-2.0.0-linux_x64.tar.gz"
echo "--make Doris tar file ${tar_file_name}"
tar -zcf ${tar_file_name} \
    --exclude=fe/selectdb-meta/* \
    --exclude=fe/doris-meta* \
    --exclude=fe/log/* \
    --exclude=be/storage/* \
    --exclude=be/log/* \
    --exclude=be/lib/meta-tool \
    *

echo "aws s3 cp $tar_file_name s3://selectdb/"
aws s3 cp "$tar_file_name" s3://selectdb/
url="https://selectdb.s3.amazonaws.com/$tar_file_name"
echo
echo $url

