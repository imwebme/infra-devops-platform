#!/usr/bin/env python3
"""
EKS Memory Monitor and Auto-Restart Cron Job
모니터링 대상: demo-prod-eks 클러스터의 demo-services 네임스페이스 내 demo-bff deployment
기능: 메모리 사용량이 75%를 초과하면 deployment를 리스타트하여 OOM 방지
"""

import os
import sys
import time
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
import boto3
from botocore.exceptions import ClientError, NoCredentialsError
import json

# Kubernetes 클라이언트
try:
    from kubernetes import client, config
    from kubernetes.client.rest import ApiException
    KUBERNETES_AVAILABLE = True
except ImportError:
    KUBERNETES_AVAILABLE = False
    logging.warning("kubernetes 패키지가 설치되지 않았습니다. pip install kubernetes로 설치해주세요.")

def validate_environment():
    """환경 변수 유효성 검사"""
    required_vars = {
        'SLACK_CHANNEL_ID': os.getenv('SLACK_CHANNEL_ID'),
        'EKS_CLUSTER_NAME': os.getenv('EKS_CLUSTER_NAME')
    }
    
    missing_vars = [var for var, value in required_vars.items() if not value]
    if missing_vars:
        raise ValueError(f"Required environment variables missing: {', '.join(missing_vars)}")
    
    # EKS_DEPLOYMENTS 또는 (EKS_NAMESPACE와 EKS_DEPLOYMENT_NAME) 중 하나는 필수
    if not os.getenv('EKS_DEPLOYMENTS'):
        if not (os.getenv('EKS_NAMESPACE') and os.getenv('EKS_DEPLOYMENT_NAME')):
            raise ValueError("Either EKS_DEPLOYMENTS or both EKS_NAMESPACE and EKS_DEPLOYMENT_NAME must be set")
    
    # MEMORY_THRESHOLD 유효성 검사
    memory_threshold = os.getenv('MEMORY_THRESHOLD', '30')
    try:
        threshold = int(memory_threshold)
        if not 0 <= threshold <= 100:
            raise ValueError
    except ValueError:
        raise ValueError(f"Invalid MEMORY_THRESHOLD value: {memory_threshold}. Must be an integer between 0 and 100")

# 환경 변수 설정
validate_environment()  # 시작 시 환경 변수 검증
SLACK_CHANNEL_ID = os.getenv('SLACK_CHANNEL_ID')
EKS_CLUSTER_NAME = os.getenv('EKS_CLUSTER_NAME')
EKS_DEPLOYMENTS = os.getenv('EKS_DEPLOYMENTS', 'demo-services:demo-bff')
MEMORY_THRESHOLD = int(os.getenv('MEMORY_THRESHOLD', '30'))

# 하위 호환성을 위한 기존 환경변수 지원
EKS_NAMESPACE = os.getenv('EKS_NAMESPACE')
EKS_DEPLOYMENT_NAME = os.getenv('EKS_DEPLOYMENT_NAME')

# 로깅 설정
def setup_logging():
    """로깅 설정 - main.py에서 실행될 때는 버퍼링"""
    import sys
    
    # main.py에서 실행되는지 확인
    is_main_py_execution = any('--files' in arg for arg in sys.argv)
    
    if is_main_py_execution:
        # main.py에서 실행되는 경우 - 로그 버퍼링
        # 로그를 캡처하기 위해 NullHandler 사용
        logging.basicConfig(
            level=logging.INFO,
            handlers=[logging.NullHandler()]  # 로그를 출력하지 않음
        )
        
        # 커스텀 로거 생성 (버퍼링용)
        logger = logging.getLogger(__name__)
        logger.handlers = []  # 기존 핸들러 제거
        logger.addHandler(logging.NullHandler())
        
        return logger
    else:
        # 독립 실행 시 - 상세한 로깅
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.StreamHandler(sys.stdout)
            ]
        )
        
        return logging.getLogger(__name__)

logger = setup_logging()

def parse_deployments(deployments_str: str) -> List[Tuple[str, str]]:
    """deployment 문자열을 파싱하여 (namespace, deployment) 튜플 리스트로 변환"""
    if not deployments_str:
        return []
    
    deployments = []
    for item in deployments_str.split(','):
        item = item.strip()
        if ':' in item:
            namespace, deployment = item.split(':', 1)
            namespace = namespace.strip()
            deployment = deployment.strip()
            if namespace and deployment:  # Ensure both values are non-empty
                deployments.append((namespace, deployment))
            else:
                print(f"잘못된 형식: '{item}' (namespace와 deployment 모두 필수)")
        else:
            print(f"잘못된 형식: '{item}' (올바른 형식: 'namespace:deployment')")
    
    return deployments

class EKSMemoryMonitor:
    """EKS 클러스터 메모리 모니터링 및 자동 리스타트 클래스"""
    
    def __init__(self, cluster_name: str, namespace: str, deployment_name: str, memory_threshold: int = None):
        self.cluster_name = cluster_name
        self.namespace = namespace
        self.deployment_name = deployment_name
        self.memory_threshold = memory_threshold if memory_threshold is not None else MEMORY_THRESHOLD
        self.region = os.getenv('AWS_DEFAULT_REGION', 'ap-northeast-2')
        
        # AWS 클라이언트 초기화 (EKS 클러스터 정보 조회용)
        try:
            self.ec2_client = boto3.client('ec2', region_name=self.region)
            self.eks_client = boto3.client('eks', region_name=self.region)
            print(f"AWS 클라이언트 초기화 완료 (리전: {self.region})")
        except Exception as e:
            print(f"AWS 클라이언트 초기화 실패: {e}")
            raise
        
        # Kubernetes 클라이언트 초기화
        try:
            self.setup_kubernetes_client()
            print("Kubernetes 클라이언트 초기화 완료")
        except Exception as e:
            print(f"Kubernetes 클라이언트 초기화 실패: {e}")
            raise
    
    def test_kubernetes_connection(self):
        """Kubernetes 연결 테스트"""
        try:
            print("🔗 Kubernetes 연결 테스트 중...")
            v1 = client.CoreV1Api()
            # 간단한 API 호출로 연결 테스트
            v1.list_namespace()
            print("✅ Kubernetes 연결 테스트 성공")
        except Exception as e:
            print(f"❌ Kubernetes 연결 테스트 실패: {e}")
            raise

    def setup_kubernetes_client(self):
        """Kubernetes 클라이언트 설정 (Pod Identity 우선)"""
        if not KUBERNETES_AVAILABLE:
            raise ImportError("kubernetes 패키지가 설치되지 않았습니다")
        
        try:
            # 1차: Pod Identity 환경에서 자동 설정 시도
            print("🔍 Pod Identity 환경에서 Kubernetes 연결 시도 중...")
            config.load_incluster_config()
            print("✅ Pod Identity 환경에서 자동 설정 완료")
            
            # 연결 테스트
            self.test_kubernetes_connection()
            
        except Exception as e:
            print(f"❌ Pod Identity 환경 설정 실패: {e}")
            try:
                # 2차: AWS IAM 역할을 통한 인증 시도 (Pod Identity 실패 시)
                print("🔍 AWS IAM 역할을 통한 인증 시도 중...")
                self.setup_aws_kubernetes_auth()
                print("✅ AWS IAM 역할을 통한 Kubernetes 인증 설정 완료")
            except Exception as e:
                print(f"❌ AWS IAM 인증 설정 실패: {e}")
                raise
    
    def setup_aws_kubernetes_auth(self):
        """AWS IAM 역할을 통한 Kubernetes 인증 설정"""
        try:
            print("🔍 EKS 클러스터 정보 조회 중...")
            # EKS 클러스터 토큰 생성
            cluster_info = self.eks_client.describe_cluster(name=self.cluster_name)
            cluster_endpoint = cluster_info['cluster']['endpoint']
            cluster_ca = cluster_info['cluster']['certificateAuthority']['data']
            print(f"✅ EKS 클러스터 정보 조회 완료: {self.cluster_name}")
            
            # kubeconfig 설정
            kube_config = {
                'apiVersion': 'v1',
                'kind': 'Config',
                'clusters': [{
                    'name': self.cluster_name,
                    'cluster': {
                        'server': cluster_endpoint,
                        'certificate-authority-data': cluster_ca
                    }
                }],
                'contexts': [{
                    'name': self.cluster_name,
                    'context': {
                        'cluster': self.cluster_name,
                        'user': 'aws-iam'
                    }
                }],
                'current-context': self.cluster_name,
                'users': [{
                    'name': 'aws-iam',
                    'user': {
                        'exec': {
                            'apiVersion': 'client.authentication.k8s.io/v1beta1',
                            'command': 'aws',
                            'args': [
                                'eks', 'get-token',
                                '--cluster-name', self.cluster_name,
                                '--region', self.region
                            ]
                        }
                    }
                }]
            }
            
            # 임시 kubeconfig 파일 생성
            import tempfile
            import yaml
            
            with tempfile.NamedTemporaryFile(mode='w', suffix='.yaml', delete=False) as f:
                yaml.dump(kube_config, f)
                temp_config_path = f.name
            
            # Kubernetes 클라이언트 설정
            config.load_kube_config(config_file=temp_config_path)
            
            # 임시 파일 정리
            os.unlink(temp_config_path)
            
        except Exception as e:
            print(f"❌ AWS IAM Kubernetes 인증 설정 실패: {e}")
            raise
    
    def get_cluster_info(self) -> Optional[Dict]:
        """EKS 클러스터 정보 조회"""
        try:
            response = self.eks_client.describe_cluster(name=self.cluster_name)
            cluster_info = response['cluster']
            
            logger.info(f"클러스터 정보 조회 완료: {cluster_info['name']} (상태: {cluster_info['status']})")
            return cluster_info
        except ClientError as e:
            logger.error(f"클러스터 정보 조회 실패: {e}")
            return None
    
    def get_deployment_pods(self) -> List[Dict]:
        """deployment의 파드 목록 조회 (Kubernetes API 사용)"""
        try:
            if not KUBERNETES_AVAILABLE:
                print("Kubernetes 클라이언트를 사용할 수 없습니다")
                return []
            
            # Kubernetes API 클라이언트 생성
            v1 = client.CoreV1Api()
            
            # deployment의 라벨 셀렉터 조회
            apps_v1 = client.AppsV1Api()
            deployment = apps_v1.read_namespaced_deployment(
                name=self.deployment_name,
                namespace=self.namespace
            )
            
            # deployment의 라벨 셀렉터 사용
            label_selector = None
            if deployment.spec.selector.match_labels:
                label_pairs = [f"{k}={v}" for k, v in deployment.spec.selector.match_labels.items()]
                label_selector = ",".join(label_pairs)
            
            # 파드 목록 조회
            if label_selector:
                pods = v1.list_namespaced_pod(
                    namespace=self.namespace,
                    label_selector=label_selector
                )
            else:
                # 라벨 셀렉터가 없는 경우 deployment 이름으로 필터링
                pods = v1.list_namespaced_pod(
                    namespace=self.namespace,
                    field_selector=f"metadata.ownerReferences[?(@.kind=='ReplicaSet')].name~={self.deployment_name}"
                )
            
            # 파드 정보를 딕셔너리로 변환
            pods_list = []
            for pod in pods.items:
                pod_dict = {
                    'metadata': {
                        'name': pod.metadata.name,
                        'labels': dict(pod.metadata.labels) if pod.metadata.labels else {}
                    },
                    'status': {
                        'phase': pod.status.phase
                    }
                }
                pods_list.append(pod_dict)
            
            print(f"파드 조회 완료: {len(pods_list)}개 파드 발견")
            return pods_list
            
        except ApiException as e:
            print(f"Kubernetes API 오류: {e}")
            return []
        except Exception as e:
            print(f"파드 조회 중 오류 발생: {e}")
            return []
    
    def get_pod_memory_usage(self, pod_name: str) -> Optional[float]:
        """특정 파드의 메모리 사용량 조회 (Kubernetes API + metrics-server)"""
        try:
            if not KUBERNETES_AVAILABLE:
                print("Kubernetes 클라이언트를 사용할 수 없습니다")
                return None
            
            # metrics.k8s.io API를 통한 메모리 사용량 조회
            try:
                # CustomObjectsApi를 사용하여 metrics.k8s.io/v1beta1/pods 메트릭 조회
                custom_api = client.CustomObjectsApi()
                
                # metrics.k8s.io API를 통해 파드 메트릭 조회
                metrics_response = custom_api.get_namespaced_custom_object(
                    group="metrics.k8s.io",
                    version="v1beta1",
                    namespace=self.namespace,
                    plural="pods",
                    name=pod_name
                )
                
                # 파드의 컨테이너 메트릭에서 메모리 사용량 추출
                if 'containers' in metrics_response and metrics_response['containers']:
                    # 첫 번째 컨테이너의 메모리 사용량 사용
                    container = metrics_response['containers'][0]
                    if 'usage' in container and 'memory' in container['usage']:
                        memory_str = container['usage']['memory']
                        memory_mb = self.parse_kubernetes_memory(memory_str)
                        print(f"파드 {pod_name} 메모리 사용량 (metrics-server): {memory_mb:.2f} MB")
                        return memory_mb
                
                print(f"파드 {pod_name}의 메모리 메트릭을 찾을 수 없음")
                return None
                
            except client.rest.ApiException as api_error:
                if api_error.status == 404:
                    print(f"파드 {pod_name}의 메트릭이 아직 수집되지 않음 (새로 생성된 파드)")
                else:
                    print(f"metrics.k8s.io API 오류 (파드 {pod_name}): {api_error}")
                return None
                
        except Exception as e:
            print(f"파드 {pod_name} 메모리 사용량 조회 실패: {e}")
            return None
    
    def get_pod_memory_limit(self, pod_name: str) -> Optional[float]:
        """특정 파드의 메모리 제한 조회 (Kubernetes API 사용)"""
        try:
            if not KUBERNETES_AVAILABLE:
                print("Kubernetes 클라이언트를 사용할 수 없습니다")
                return None
            
            # Kubernetes API 클라이언트 생성
            v1 = client.CoreV1Api()
            
            # 파드 정보 조회
            pod = v1.read_namespaced_pod(
                name=pod_name,
                namespace=self.namespace
            )
            
            # 첫 번째 컨테이너의 메모리 제한 조회
            if pod.spec.containers and len(pod.spec.containers) > 0:
                container = pod.spec.containers[0]
                if container.resources and container.resources.limits:
                    memory_limit = container.resources.limits.get('memory')
                    if memory_limit:
                        # Kubernetes 메모리 단위를 MB로 변환
                        memory_mb = self.parse_kubernetes_memory(str(memory_limit))
                        print(f"파드 {pod_name} 메모리 제한: {memory_mb:.2f} MB")
                        return memory_mb
            
            print(f"파드 {pod_name}에 메모리 제한이 설정되지 않았습니다")
            return None
            
        except ApiException as e:
            print(f"Kubernetes API 오류: {e}")
            return None
        except Exception as e:
            print(f"파드 {pod_name} 메모리 제한 조회 실패: {e}")
            return None
    
    def parse_kubernetes_memory(self, memory_str: str) -> float:
        """Kubernetes 메모리 단위를 MB로 변환"""
        memory_str = memory_str.upper()
        
        if memory_str.endswith('KI'):
            return float(memory_str[:-2]) / 1024
        elif memory_str.endswith('MI'):
            return float(memory_str[:-2])
        elif memory_str.endswith('GI'):
            return float(memory_str[:-2]) * 1024
        elif memory_str.endswith('TI'):
            return float(memory_str[:-2]) * 1024 * 1024
        elif memory_str.endswith('K'):
            return float(memory_str[:-1]) / 1024
        elif memory_str.endswith('M'):
            return float(memory_str[:-1])
        elif memory_str.endswith('G'):
            return float(memory_str[:-1]) * 1024
        elif memory_str.endswith('T'):
            return float(memory_str[:-1]) * 1024 * 1024
        else:
            # 바이트 단위로 가정
            return float(memory_str) / (1024 * 1024)
    
    def calculate_memory_usage_percentage(self, pod_name: str) -> Optional[float]:
        """파드의 메모리 사용률 계산"""
        try:
            usage = self.get_pod_memory_usage(pod_name)
            limit = self.get_pod_memory_limit(pod_name)
            
            if usage is None or limit is None:
                print(f"파드 {pod_name}의 메모리 정보를 가져올 수 없음")
                return None
            
            percentage = (usage / limit) * 100
            print(f"파드 {pod_name} 메모리 사용률: {percentage:.2f}% ({usage:.2f}MB / {limit:.2f}MB)")
            
            return percentage
            
        except Exception as e:
            print(f"파드 {pod_name} 메모리 사용률 계산 실패: {e}")
            return None
    
    def check_memory_threshold(self) -> Tuple[bool, List[str]]:
        """메모리 임계치 체크 및 초과 파드 목록 반환"""
        pods = self.get_deployment_pods()
        exceeded_pods = []
        pod_details = []
        
        print(f"🔍 메모리 임계치 체크 시작 (임계치: {self.memory_threshold}%)")
        
        for pod in pods:
            pod_name = pod['metadata']['name']
            pod_status = pod['status']['phase']
            
            # Running 상태가 아닌 파드는 건너뛰기
            if pod_status != 'Running':
                print(f"   • 파드 {pod_name}: {pod_status} 상태 (건너뛰기)")
                continue
            
            usage_percentage = self.calculate_memory_usage_percentage(pod_name)
            if usage_percentage is None:
                print(f"   • 파드 {pod_name}: 메모리 정보 조회 실패")
                continue
            
            # 파드 상세 정보 수집
            pod_detail = {
                'name': pod_name,
                'usage_percentage': usage_percentage,
                'exceeded': usage_percentage > self.memory_threshold
            }
            pod_details.append(pod_detail)
            
            if usage_percentage > self.memory_threshold:
                exceeded_pods.append(pod_name)
                print(f"   ⚠️  파드 {pod_name}: 메모리 임계치 초과 ({usage_percentage:.2f}% > {self.memory_threshold}%)")
            else:
                print(f"   ✅ 파드 {pod_name}: 메모리 사용률 {usage_percentage:.2f}% (정상)")
        
        # 요약 정보 출력
        threshold_exceeded = len(exceeded_pods) > 0
        print(f"📊 메모리 임계치 체크 완료:")
        print(f"   • 전체 파드: {len(pods)}개")
        print(f"   • Running 상태: {len([p for p in pods if p['status']['phase'] == 'Running'])}개")
        print(f"   • 메모리 정보 조회 성공: {len(pod_details)}개")
        print(f"   • 임계치 초과: {len(exceeded_pods)}개")
        
        if exceeded_pods:
            print(f"🚨 임계치 초과 파드 목록: {', '.join(exceeded_pods)}")
        
        return threshold_exceeded, exceeded_pods
    
    def restart_deployment(self) -> bool:
        """deployment 리스타트 수행 (Kubernetes API 사용)"""
        try:
            if not KUBERNETES_AVAILABLE:
                print("Kubernetes 클라이언트를 사용할 수 없습니다")
                return False
            
            # 리스타트 전 현재 파드 목록 조회
            current_pods = self.get_deployment_pods()
            current_pod_names = [pod['metadata']['name'] for pod in current_pods if pod['status']['phase'] == 'Running']
            
            print(f"🔄 Deployment {self.deployment_name} 리스타트 시작...")
            print(f"   • 리스타트 전 파드: {', '.join(current_pod_names)}")
            
            # Kubernetes API 클라이언트 생성
            apps_v1 = client.AppsV1Api()
            
            # deployment 패치를 통한 리스타트
            # restart annotation을 추가하여 리스타트 트리거
            restart_time = datetime.now().isoformat()
            patch_body = {
                'spec': {
                    'template': {
                        'metadata': {
                            'annotations': {
                                'kubectl.kubernetes.io/restartedAt': restart_time
                            }
                        }
                    }
                }
            }
            
            # deployment 패치
            apps_v1.patch_namespaced_deployment(
                name=self.deployment_name,
                namespace=self.namespace,
                body=patch_body
            )
            
            print(f"✅ Deployment {self.deployment_name} 리스타트 명령 전송 완료")
            
            # 리스타트 상태 확인
            restart_success = self.wait_for_rollout_completion()
            
            if restart_success:
                # 리스타트 후 새로운 파드 목록 조회
                new_pods = self.get_deployment_pods()
                new_pod_names = [pod['metadata']['name'] for pod in new_pods if pod['status']['phase'] == 'Running']
                
                print(f"🔄 Deployment {self.deployment_name} 리스타트 완료")
                print(f"   • 리스타트 전 파드: {', '.join(current_pod_names)}")
                print(f"   • 리스타트 후 파드: {', '.join(new_pod_names)}")
                
                # 변경된 파드 식별
                changed_pods = set(current_pod_names) - set(new_pod_names)
                if changed_pods:
                    print(f"   • 리스타트된 파드: {', '.join(changed_pods)}")
                
                return True
            else:
                print(f"❌ Deployment {self.deployment_name} 리스타트 실패")
                return False
                
        except ApiException as e:
            print(f"Kubernetes API 오류: {e}")
            return False
        except Exception as e:
            print(f"deployment 리스타트 중 오류 발생: {e}")
            return False
    
    def wait_for_rollout_completion(self, timeout_minutes: int = 10):
        """deployment 롤아웃 완료 대기 (Kubernetes API 사용)"""
        try:
            if not KUBERNETES_AVAILABLE:
                print("Kubernetes 클라이언트를 사용할 수 없습니다")
                return False
            
            # Kubernetes API 클라이언트 생성
            apps_v1 = client.AppsV1Api()
            
            start_time = time.time()
            timeout_seconds = timeout_minutes * 60
            
            while time.time() - start_time < timeout_seconds:
                try:
                    # deployment 상태 조회
                    deployment = apps_v1.read_namespaced_deployment(
                        name=self.deployment_name,
                        namespace=self.namespace
                    )
                    
                    # 롤아웃 상태 확인
                    if (deployment.status.updated_replicas == deployment.status.replicas and
                        deployment.status.available_replicas == deployment.status.replicas and
                        deployment.status.ready_replicas == deployment.status.replicas):
                        print(f"deployment {self.deployment_name} 롤아웃 완료")
                        return True
                    
                    # 실패 상태 확인
                    if deployment.status.conditions:
                        for condition in deployment.status.conditions:
                            if (condition.type == 'Failed' and 
                                condition.status == 'True'):
                                print(f"deployment {self.deployment_name} 롤아웃 실패: {condition.message}")
                                return False
                    
                    print("롤아웃 진행 중... 30초 후 재확인")
                    time.sleep(30)
                    
                except ApiException as e:
                    print(f"Kubernetes API 오류: {e}")
                    return False
                    
            print(f"deployment 롤아웃 타임아웃 ({timeout_minutes}분)")
            return False
            
        except Exception as e:
            print(f"롤아웃 상태 확인 중 오류 발생: {e}")
            return False
    
    def show_kubernetes_connection_info(self):
        """Kubernetes 연결 정보 표시"""
        try:
            if not KUBERNETES_AVAILABLE:
                print("Kubernetes 클라이언트를 사용할 수 없습니다")
                return
            
            # Kubernetes API 서버 정보 조회
            v1 = client.CoreV1Api()
            
            try:
                # API 서버 버전 정보 조회
                version = v1.get_api_resources()
                print(f"🔗 Kubernetes API 연결 성공")
                print(f"🌐 API 서버: {v1.api_client.configuration.host}")
                print(f"📋 사용 가능한 API 리소스: {len(version.resources)}개")
                
            except ApiException as e:
                print(f"Kubernetes API 연결 실패: {e}")
                
        except Exception as e:
            print(f"Kubernetes 연결 정보 표시 중 오류 발생: {e}")
    
    def show_target_deployment_info(self):
        """타겟 deployment 상세 정보 표시 (Kubernetes API 사용)"""
        try:
            if not KUBERNETES_AVAILABLE:
                print("Kubernetes 클라이언트를 사용할 수 없습니다")
                return
            
            # Kubernetes API 클라이언트 생성
            apps_v1 = client.AppsV1Api()
            
            # deployment 상세 정보 조회
            deployment = apps_v1.read_namespaced_deployment(
                name=self.deployment_name,
                namespace=self.namespace
            )
            
            # 기본 정보
            metadata = deployment.metadata
            spec = deployment.spec
            status = deployment.status
            
            print(f"🎯 타겟 Deployment 정보:")
            print(f"   • 이름: {metadata.name}")
            print(f"   • 생성 시간: {metadata.creation_timestamp}")
            print(f"   • 레플리카 수: {spec.replicas}")
            print(f"   • 사용 가능한 레플리카: {status.available_replicas}")
            print(f"   • 업데이트된 레플리카: {status.updated_replicas}")
            
            # 컨테이너 정보
            containers = spec.template.spec.containers
            for i, container in enumerate(containers):
                print(f"   • 컨테이너 {i+1}: {container.name}")
                
                # 리소스 제한
                if container.resources:
                    if container.resources.limits:
                        if container.resources.limits.get('memory'):
                            print(f"     - 메모리 제한: {container.resources.limits['memory']}")
                        if container.resources.limits.get('cpu'):
                            print(f"     - CPU 제한: {container.resources.limits['cpu']}")
                    
                    if container.resources.requests:
                        if container.resources.requests.get('memory'):
                            print(f"     - 메모리 요청: {container.resources.requests['memory']}")
                        if container.resources.requests.get('cpu'):
                            print(f"     - CPU 요청: {container.resources.requests['cpu']}")
            
            # 라벨 정보
            if metadata.labels:
                label_str = ', '.join([f"{k}={v}" for k, v in metadata.labels.items()])
                print(f"   • 라벨: {label_str}")
                
        except ApiException as e:
            print(f"Kubernetes API 오류: {e}")
        except Exception as e:
            print(f"타겟 deployment 정보 표시 중 오류 발생: {e}")
    
    def show_cluster_summary(self):
        """클러스터 요약 정보 표시 (Kubernetes API 사용)"""
        try:
            if not KUBERNETES_AVAILABLE:
                print("Kubernetes 클라이언트를 사용할 수 없습니다")
                return
            
            # Kubernetes API 클라이언트 생성
            v1 = client.CoreV1Api()
            
            # 노드 정보 조회
            try:
                nodes = v1.list_node()
                ready_nodes = sum(1 for node in nodes.items if node.status.conditions)
                total_nodes = len(nodes.items)
                print(f"🖥️  클러스터 노드: {ready_nodes}/{total_nodes} Ready")
            except ApiException as e:
                print(f"노드 정보 조회 실패: {e}")
            
            # 전체 파드 정보 조회
            try:
                all_pods = v1.list_pod_for_all_namespaces()
                running_pods = sum(1 for pod in all_pods.items if pod.status.phase == 'Running')
                total_pods = len(all_pods.items)
                print(f"📦 전체 파드: {running_pods}/{total_pods} Running")
            except ApiException as e:
                print(f"전체 파드 정보 조회 실패: {e}")
            
            # 타겟 네임스페이스 파드 정보 조회
            try:
                ns_pods = v1.list_namespaced_pod(namespace=self.namespace)
                ns_running_pods = sum(1 for pod in ns_pods.items if pod.status.phase == 'Running')
                ns_total_pods = len(ns_pods.items)
                print(f"🎯 {self.namespace} 네임스페이스: {ns_running_pods}/{ns_total_pods} Running")
            except ApiException as e:
                print(f"{self.namespace} 네임스페이스 파드 정보 조회 실패: {e}")
                
        except Exception as e:
            print(f"클러스터 요약 정보 표시 중 오류 발생: {e}")
    
    def send_slack_notification(self, message: str):
        """Slack 알림 전송"""
        try:
            # 기존 프로젝트의 slackbot 모듈 사용
            from slackbot import slack
            
            # slackbot을 사용하여 메시지 전송
            response = slack.post_message(SLACK_CHANNEL_ID, message)
            
            if response.get('ok'):
                print(f"Slack 알림 전송 완료: 채널 ID {SLACK_CHANNEL_ID}")
                return response.get('ts')  # 타임스탬프 반환
            else:
                print(f"Slack 메시지 전송 실패: {response.get('error')}")
                return None
                
        except ImportError:
            # slackbot 모듈이 없는 경우 slack_sdk 사용 (fallback)
            try:
                from slack_sdk import WebClient
                from slack_sdk.errors import SlackApiError
                
                slack_token = os.getenv('SLACK_TOKEN')
                if not slack_token:
                    print("SLACK_TOKEN이 설정되지 않아 Slack 알림을 보낼 수 없습니다")
                    return None
                
                client = WebClient(token=slack_token)
                
                response = client.chat_postMessage(
                    channel=SLACK_CHANNEL_ID,
                    text=message,
                    username="EKS Memory Monitor",
                    icon_emoji=":warning:"
                )
                
                print(f"Slack 알림 전송 완료: 채널 ID {SLACK_CHANNEL_ID}")
                return response.get('ts')
                
            except Exception as e:
                print(f"Slack SDK를 통한 알림 전송 실패: {e}")
                return None
                
        except Exception as e:
            print(f"Slack 알림 전송 중 예외 발생: {e}")
            return None
    
    def send_slack_thread_reply(self, thread_ts: str, message: str):
        """Slack thread에 답글 전송"""
        try:
            # 기존 프로젝트의 slackbot 모듈 사용
            from slackbot import slack
            
            # slackbot의 post_thread_message 메서드 사용
            response = slack.post_thread_message(
                channel_id=SLACK_CHANNEL_ID,
                message_ts=thread_ts,
                text=message
            )
            
            if response.get('ok'):
                print(f"Slack thread 답글 전송 완료: {thread_ts}")
                return True
            else:
                print(f"Slack thread 답글 전송 실패: {response.get('error')}")
                return False
                
        except ImportError:
            # slackbot 모듈이 없는 경우 slack_sdk 사용 (fallback)
            try:
                from slack_sdk import WebClient
                from slack_sdk.errors import SlackApiError
                
                slack_token = os.getenv('SLACK_TOKEN')
                if not slack_token:
                    print("SLACK_TOKEN이 설정되지 않아 Slack thread 답글을 보낼 수 없습니다")
                    return False
                
                client = WebClient(token=slack_token)
                
                response = client.chat_postMessage(
                    channel=SLACK_CHANNEL_ID,
                    text=message,
                    thread_ts=thread_ts,
                    username="EKS Memory Monitor",
                    icon_emoji=":warning:"
                )
                
                print(f"Slack thread 답글 전송 완료: {thread_ts}")
                return True
                
            except Exception as e:
                print(f"Slack SDK를 통한 thread 답글 전송 실패: {e}")
                return False
                
        except Exception as e:
            print(f"Slack thread 답글 전송 중 예외 발생: {e}")
            return False
    
    def run_monitoring_cycle(self) -> bool:
        """한 번의 모니터링 사이클 실행"""
        try:
            print("=" * 60)
            print(f"EKS 메모리 모니터링 시작 - {datetime.now()}")
            print(f"클러스터: {self.cluster_name}")
            print(f"네임스페이스: {self.namespace}")
            print(f"Deployment: {self.deployment_name}")
            print(f"메모리 임계치: {self.memory_threshold}%")
            print(f"Slack 알림 채널: {SLACK_CHANNEL_ID}")
            print("=" * 60)
            
            # Kubernetes 연결 정보 표시
            self.show_kubernetes_connection_info()
            
            # 타겟 deployment 상세 정보 표시
            self.show_target_deployment_info()
            
            # 클러스터 요약 정보 표시
            self.show_cluster_summary()
            
            # 클러스터 상태 확인
            cluster_info = self.get_cluster_info()
            if not cluster_info:
                print("클러스터 정보를 가져올 수 없어 모니터링을 중단합니다")
                return False
            
            # 메모리 임계치 체크
            threshold_exceeded, exceeded_pods = self.check_memory_threshold()
            
            if threshold_exceeded:
                print(f"메모리 임계치 초과 파드 발견: {exceeded_pods}")
                
                # Slack 알림 전송 (메인 메시지)
                message = f"🚨 *EKS 메모리 임계치 초과*\n"
                message += f"• 클러스터: {self.cluster_name}\n"
                message += f"• Deployment: {self.deployment_name}\n"
                message += f"• 임계치 초과 파드: {', '.join(exceeded_pods)}\n"
                message += f"• 임계치: {self.memory_threshold}%\n"
                message += f"• 시간: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
                message += f"• 자동 리스타트를 시작합니다..."
                
                # 메인 알림 전송하고 thread_ts 받기
                thread_ts = self.send_slack_notification(message)
                
                # deployment 리스타트
                restart_success = self.restart_deployment()
                
                # thread에 결과 추가
                if thread_ts:
                    if restart_success:
                        result_message = f"✅ *리스타트 완료*\n"
                        result_message += f"• 시간: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
                        result_message += f"• 메모리 임계치 초과로 인한 자동 리스타트가 성공적으로 완료되었습니다"
                    else:
                        result_message = f"❌ *리스타트 실패*\n"
                        result_message += f"• 시간: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
                        result_message += f"• 수동 확인이 필요합니다"
                    
                    self.send_slack_thread_reply(thread_ts, result_message)
                    print("Slack thread에 결과 전송 완료")
                else:
                    print("Slack thread_ts를 받지 못해 결과를 전송할 수 없습니다")
                
                return restart_success
            else:
                print("모든 파드가 메모리 임계치 이내입니다")
                return True
                
        except Exception as e:
            print(f"모니터링 사이클 실행 중 오류 발생: {e}")
            return False
        finally:
            print("=" * 60)
            print(f"EKS 메모리 모니터링 완료 - {datetime.now()}")
            print("=" * 60)


def run_multi_deployment_monitor(cluster_name=None, deployments_str=None, memory_threshold=None, dry_run=False):
    """멀티 deployment EKS 메모리 모니터링 실행 함수"""
    try:
        # 기본값 설정
        cluster_name = cluster_name or EKS_CLUSTER_NAME
        deployments_str = deployments_str or EKS_DEPLOYMENTS
        memory_threshold = memory_threshold or MEMORY_THRESHOLD
        
        # deployment 목록 파싱
        deployments = parse_deployments(deployments_str)
        if not deployments:
            print("모니터링할 deployment가 없습니다")
            return False
        
        print(f"EKS 멀티 deployment 메모리 모니터링 시작")
        print(f"클러스터: {cluster_name}")
        print(f"메모리 임계치: {memory_threshold}%")
        print(f"Dry Run: {dry_run}")
        print(f"모니터링 대상: {len(deployments)}개 deployment")
        for ns, dep in deployments:
            print(f"  • {ns}:{dep}")
        
        # 전체 결과 수집
        all_results = []
        exceeded_deployments = []
        failed_deployments = []
        
        # 각 deployment 모니터링
        for namespace, deployment_name in deployments:
            print(f"\n{'='*50}")
            print(f"모니터링: {namespace}:{deployment_name}")
            print(f"{'='*50}")
            
            try:
                # 모니터링 객체 생성
                monitor = EKSMemoryMonitor(
                    cluster_name=cluster_name,
                    namespace=namespace,
                    deployment_name=deployment_name,
                    memory_threshold=memory_threshold
                )
                
                if dry_run:
                    # dry run에서는 리스타트 함수를 오버라이드
                    monitor.restart_deployment = lambda: (print("DRY RUN: 리스타트 시뮬레이션"), True)[1]
                
                # 메모리 임계치 체크만 수행 (개별 알림 없이)
                threshold_exceeded, exceeded_pods = monitor.check_memory_threshold()
                
                result = {
                    'namespace': namespace,
                    'deployment': deployment_name,
                    'threshold_exceeded': threshold_exceeded,
                    'exceeded_pods': exceeded_pods,
                    'restart_success': None
                }
                
                # 임계치 초과 시 리스타트
                if threshold_exceeded:
                    print(f"메모리 임계치 초과 - 리스타트 수행: {namespace}:{deployment_name}")
                    restart_success = monitor.restart_deployment()
                    result['restart_success'] = restart_success
                    exceeded_deployments.append(result)
                
                all_results.append(result)
                
            except Exception as e:
                print(f"deployment {namespace}:{deployment_name} 모니터링 실패: {str(e)}")
                failed_result = {
                    'namespace': namespace,
                    'deployment': deployment_name,
                    'error': str(e)
                }
                all_results.append(failed_result)
                failed_deployments.append(failed_result)
                continue  # Continue with next deployment
        
        # 통합 Slack 알림 전송 (실패한 deployment 포함)
        if exceeded_deployments or failed_deployments:
            send_consolidated_slack_notification(cluster_name, exceeded_deployments, failed_deployments, memory_threshold)
        
        # 결과 요약
        print(f"\n{'='*60}")
        print("모니터링 결과 요약")
        print(f"{'='*60}")
        
        success_count = sum(1 for r in all_results if not r.get('error') and not r.get('threshold_exceeded'))
        exceeded_count = len(exceeded_deployments)
        error_count = len(failed_deployments)
        
        print(f"전체 deployment: {len(deployments)}개")
        print(f"정상: {success_count}개")
        print(f"임계치 초과: {exceeded_count}개")
        print(f"오류: {error_count}개")
        
        # 모든 deployment가 성공적으로 처리되었는지 확인
        return len(failed_deployments) == 0
        
    except Exception as e:
        print(f"멀티 deployment 모니터링 실행 중 오류 발생: {str(e)}")
        return False

def send_consolidated_slack_notification(cluster_name: str, exceeded_deployments: List[Dict], failed_deployments: List[Dict], memory_threshold: int):
    """통합 Slack 알림 전송 - 메시지 크기 제한 처리"""
    try:
        from slackbot import slack
        
        MAX_MESSAGE_LENGTH = 3000  # Slack message length limit (actual is 4000, leaving buffer)
        
        def create_header():
            total_issues = len(exceeded_deployments) + len(failed_deployments)
            header = f"🚨 *EKS 모니터링 결과 ({total_issues}개 이슈)*\n"
            header += f"• 클러스터: {cluster_name}\n"
            header += f"• 임계치: {memory_threshold}%\n"
            header += f"• 시간: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n"
            return header
        
        def create_deployment_message(result: Dict) -> str:
            msg = f"📦 *{result['namespace']}:{result['deployment']}*\n"
            
            if 'error' in result:
                msg += f"   • 오류: ❌ {result['error']}\n"
            else:
                msg += f"   • 임계치 초과 파드: {', '.join(result['exceeded_pods'])}\n"
                
                if result['restart_success'] is True:
                    msg += f"   • 리스타트: ✅ 성공\n"
                elif result['restart_success'] is False:
                    msg += f"   • 리스타트: ❌ 실패\n"
                else:
                    msg += f"   • 리스타트: 🔄 진행중\n"
            
            return msg + "\n"
        
        # 메시지 청크로 분할하여 전송
        current_message = create_header()
        
        # 실패한 deployment 먼저 보고
        if failed_deployments:
            current_message += "🔴 *실패한 Deployments*\n\n"
            for result in failed_deployments:
                deployment_msg = create_deployment_message(result)
                if len(current_message) + len(deployment_msg) > MAX_MESSAGE_LENGTH:
                    # 현재 청크 전송
                    response = slack.post_message(SLACK_CHANNEL_ID, current_message)
                    if not response.get('ok'):
                        print(f"Slack 메시지 전송 실패: {response.get('error')}")
                    # 새 청크 시작
                    current_message = create_header() + deployment_msg
                else:
                    current_message += deployment_msg
        
        # 임계치 초과 deployment 보고
        if exceeded_deployments:
            if len(current_message) > len(create_header()):
                current_message += "\n"  # Add separator between sections
            current_message += "🟡 *임계치 초과 Deployments*\n\n"
            for result in exceeded_deployments:
                deployment_msg = create_deployment_message(result)
                if len(current_message) + len(deployment_msg) > MAX_MESSAGE_LENGTH:
                    # 현재 청크 전송
                    response = slack.post_message(SLACK_CHANNEL_ID, current_message)
                    if not response.get('ok'):
                        print(f"Slack 메시지 전송 실패: {response.get('error')}")
                    # 새 청크 시작
                    current_message = create_header() + deployment_msg
                else:
                    current_message += deployment_msg
        
        # 마지막 청크 전송
        if len(current_message) > len(create_header()):
            response = slack.post_message(SLACK_CHANNEL_ID, current_message)
            if response.get('ok'):
                print(f"통합 Slack 알림 전송 완료: 채널 ID {SLACK_CHANNEL_ID}")
            else:
                print(f"Slack 메시지 전송 실패: {response.get('error')}")
                
    except Exception as e:
        print(f"통합 Slack 알림 전송 중 오류 발생: {str(e)}")
        # 중요한 오류이므로 예외를 다시 발생시켜 상위에서 처리하도록 함
        raise

def run_eks_memory_monitor(cluster_name=None, namespace=None, deployment_name=None, memory_threshold=None, dry_run=False):
    """EKS 메모리 모니터링 실행 함수 (하위 호환성 유지)"""
    # 기존 단일 deployment 방식 지원
    if namespace and deployment_name:
        deployments_str = f"{namespace}:{deployment_name}"
        return run_multi_deployment_monitor(cluster_name, deployments_str, memory_threshold, dry_run)
    else:
        # 환경변수에서 멀티 deployment 설정 사용
        return run_multi_deployment_monitor(cluster_name, None, memory_threshold, dry_run)

# main.py에서 exec()로 실행될 때 사용할 코드
# 환경변수에서 설정을 가져와서 모니터링 실행
try:
    import os
    import sys
    import io
    import contextlib
    
    # 로그를 캡처할 StringIO 버퍼
    log_buffer = io.StringIO()
    
    # 로그 캡처 및 모니터링 실행
    with contextlib.redirect_stdout(log_buffer), contextlib.redirect_stderr(log_buffer):
        # 환경변수에서 설정 가져오기
        cluster_name = os.getenv('EKS_CLUSTER_NAME')
        deployments_str = os.getenv('EKS_DEPLOYMENTS')
        memory_threshold = os.getenv('MEMORY_THRESHOLD')
        dry_run = os.getenv('DRY_RUN', 'false').lower() == 'true'
        
        # 하위 호환성: 기존 단일 deployment 환경변수 지원
        if not deployments_str:
            namespace = os.getenv('EKS_NAMESPACE')
            deployment_name = os.getenv('EKS_DEPLOYMENT_NAME')
            if namespace and deployment_name:
                deployments_str = f"{namespace}:{deployment_name}"
        
        # 메모리 임계치를 정수로 변환
        if memory_threshold:
            try:
                memory_threshold = int(memory_threshold)
            except ValueError:
                memory_threshold = None
        
        # 멀티 deployment 모니터링 실행
        success = run_multi_deployment_monitor(
            cluster_name=cluster_name,
            deployments_str=deployments_str,
            memory_threshold=memory_threshold,
            dry_run=dry_run
        )
    
    # 버퍼된 로그를 한 번에 출력
    log_content = log_buffer.getvalue()
    if log_content.strip():
        print("=== EKS 메모리 모니터링 로그 ===")
        print(log_content)
        print("=== 로그 끝 ===")
    
    # 결과 요약 출력
    if success:
        print("✅ EKS 메모리 모니터링이 성공적으로 완료되었습니다")
    else:
        print("❌ EKS 메모리 모니터링 실행 중 오류가 발생했습니다")
    
except Exception as e:
    print(f"❌ EKS 메모리 모니터링 실행 중 오류 발생: {e}")