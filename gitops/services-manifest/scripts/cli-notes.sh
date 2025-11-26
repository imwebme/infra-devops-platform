# 어드민 컨테이너 진입 명령어
enter-admin-container

# 루트 파일 시스템 접근
sudo sheltie
cd /var/lib/containerd
cd /var/lib/kubelet

# 디스크 사용량을 확인하고, 사용량 퍼센트(5번째 열 기준)로 정렬
df -h | sort -k 5 -h

# 현재 디렉토리 내 1단계 하위 디렉토리별 용량을 확인하고, 용량 기준으로 내림차순 정렬
du -h --max-depth=1 . | sort -k 1 -h -r

# finalizer 수정 하는 예시
kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{"metadata":{"finalizers":[]}}' --type=merge
