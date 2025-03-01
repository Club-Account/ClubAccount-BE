#!/bin/bash

echo "🚀 배포 시작: $(date)"

# 프로젝트 디렉토리 이동
cd /home/ubuntu || exit

echo "🔎 .env 파일 확인 중..."
if [ ! -f "/home/ubuntu/.env" ]; then
    echo "❌ .env 파일이 없습니다! GitHub Actions에서 제대로 생성되었는지 확인하세요."
    exit 1
fi

# .env 파일 로드
export "$(grep -v '^#' /home/ubuntu/.env | xargs)"

echo "🛑 기존 컨테이너 중지 중..."
docker-compose down  # 기존 컨테이너 중지 및 제거

echo "🐳 최신 Docker 이미지 가져오는 중..."
docker pull $DOCKER_USERNAME/thinkboo-backend-app:latest  # 최신 이미지 가져오기

echo "📂 application.yml 파일 생성 중..."
mkdir -p /home/ubuntu/config
cat > /home/ubuntu/config/application.yml <<EOL
spring:
  config:
    activate:
      on-profile: prod
    location: /app/config/application.yml

  datasource:
    url: ${SPRING_DATASOURCE_URL}
    username: ${SPRING_DATASOURCE_USERNAME}
    password: ${SPRING_DATASOURCE_PASSWORD}
    driver-class-name: com.mysql.cj.jdbc.Driver

logging:
  file:
    name: /app/logs/app.log
  level:
    root: INFO
EOL

echo "🔒 파일 권한 설정 중..."
chmod 600 /home/ubuntu/.env
chmod 600 /home/ubuntu/config/application.yml

echo "🔄 컨테이너 재시작 중..."
docker-compose up -d --force-recreate --remove-orphans  # 최신 이미지로 컨테이너 재시작

echo "🧹 사용하지 않는 Docker 이미지 정리"
docker image prune -f  # 불필요한 이미지 삭제

echo "✅ 배포 완료!"
