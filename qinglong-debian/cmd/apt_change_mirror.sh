#!/usr/bin/env bash
# usage: ./update-apt-mirror.sh <源文件>

MAX_WAIT=60        # 最大等待秒数
CMD_MAIN="/var/apps/${TRIM_APPNAME}/cmd/main"
LOG_FILE=${TRIM_PKGVAR}/apt_source.log

FILE_PATH="${TRIM_APPDEST}/docker/docker-compose.yaml"
CONTAINER=$(grep -E 'container_name\s*:' "$FILE_PATH" | awk -F: '{print $2}' | xargs | head -n1)


log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> ${LOG_FILE}
}

get_apt_source(){
  local arg=${1:-default}
  local base="${TRIM_APPDEST}/apt-sources"
  case "$arg" in
    aliyun) echo "${base}/debian-aliyun.sources" ;;
    tuna)   echo "${base}/debian-tuna.sources" ;;
    ustc)   echo "${base}/debian-ustc.sources" ;;
    default)echo "${base}/debian.sources" ;;
    *)
      log_msg "❌ 不支持的源文件参数: $1"
      return 1
      ;;
  esac
}

is_docker_running () {
  docker inspect "$CONTAINER" 2>>"$LOG_FILE" | grep -q '"Status": "running"'
}

make_sure_container_running() {
  if ! is_docker_running; then
      log_msg "容器未运行，开始启动容器"
      docker start "$CONTAINER" >>"$LOG_FILE" 2>&1
      for ((i=1; i<=MAX_WAIT; i++)); do
        if is_docker_running; then
            log_msg "容器已启动"
            return 0
        fi
        log_msg "等待容器启动... ($i/${MAX_WAIT})"
        sleep 1
      done
      log_msg "❌ 容器启动超时，中断操作"
      exit 1
  fi
  log_msg "✅ 容器正在运行"
  return 0
}

apt_change_mirror() {
  # 拷贝新源 & 更新
  local SRC_FILE="$1"
  log_msg "开始更换APT源为: $SRC_FILE"
  docker cp "$SRC_FILE" "$CONTAINER:/etc/apt/sources.list.d/debian.sources" 2>>"$LOG_FILE"
  log_msg "源文件已拷贝到容器内，开始执行 apt update"
  docker exec "$CONTAINER" sh -c 'apt update -y' 2>>"$LOG_FILE"
  log_msg "apt update 执行完成"
}


SRC_FILE=$(get_apt_source "$1")
[[ -f $SRC_FILE ]] || { log_msg "❌ 源文件 $SRC_FILE 不存在"; exit 1; }
make_sure_container_running
apt_change_mirror "$SRC_FILE"
log_msg "✅ 已更换为 $SRC_FILE"