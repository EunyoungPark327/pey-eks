# EKS Terraform Deployment with Application Load Balancer

---

- Terraform의 EKS, VPC 모듈을 통해 손쉽게 인프라 전반을 배포합니다.
- Public ALB를 통해 Private에 배포된 Pod와 통신합니다.

## Overview

- **Public Subnet**
  - ALB와 Internet Gateway가 Public Sunbet에 배포됩니다.
- **Private Subnet**
  - EC2 노드가 실행되며, NAT Gateway를 통해 외부 통신이 가능합니다.
  - 외부 통신 시 같은 Zone의 NAT를 이용합니다.
  - Pod는 ap-northeast-2a, ap-northeast-2c에 분산 배치됩니다.
- **Spring boot 애플리케이션**
  - 테스트 샘플: https://github.com/spring-guides/gs-spring-boot-docker
  - fork한 repo에 [github actions](https://github.com/EunyoungPark327/gs-spring-boot-docker/blob/main/.github/workflows/build.yml)를 추가하여 ecr로 이미지를 빌드 후 푸쉬합니다.
- **Kuberntest Manifest**
  - `deployment.yaml`: Spring Boot 애플리케이션을 배포합니다. `affinity` 설정을 통해 Pod가 노드에 균형 있게 분배되도록 구성합니다.
  - `hpa.yaml`: CPU 사용량 기준으로 자동 `scale-out`을 설정하여 부하에 따라 Pod의 수를 조정합니다.
  - `ingress.yaml`: ALB(Application Load Balancer)를 활용한 외부 통신 설정을 포함합니다.
  - `service.yaml`: ClusterIP 타입의 내부 서비스 구성을 정의합니다.

## Requirementes

| Name       | Version |
| ---------- | ------- |
| terraform  | >= 1.5  |
| aws        | >= 5.40 |
| kubernetes | >= 2.10 |

## Providers

| Name | Version |
| ---- | ------- |
| aws  | >= 5.40 |

## Directory Structure

```bash
├── main.tf              # Main entry for Terraform configurations
├── manifest/            # Kubernetes resource manifests
│   ├── deployment.yaml  # Application Deployment
│   ├── hpa.yaml         # Horizontal Pod Autoscaler
│   ├── ingress.yaml     # ALB Ingress Configuration
│   └── service.yaml     # Kubernetes Service
├── modules/
│   ├── eks/             # EKS Terraform module
│   │   ├── main.tf      # EKS setup
│   │   └── variable.tf  # EKS variables
│   ├── vpc/             # VPC Terraform module
│   │   ├── main.tf      # VPC setup
│   │   ├── output.tf    # VPC outputs
│   │   └── variable.tf  # VPC variables
```

## Usage

### 1. Terraform 초기화

```bash
$ terraform init
$ terraform apply
```

### 2. kubectl 설정

```bash
$ aws eks update-kubeconfig --name <cluster-name>
```

cluster name은 기본 `pey`으로 적용 돼 있습니다.

### 3. helm으로 alb-controller 설치 및 배포

```bash
$ eksctl create iamserviceaccount \
  --name aws-load-balancer-controller \
  --namespace kube-system \
  --cluster <CLUSTER_NAME> \
  --attach-policy-arn arn:aws:iam::aws:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

$ helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=<CLUSTER_NAME> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=<REGION> \
  --set vpcId=<VPC_ID>
```
### 4. Metrics Server 설치
```bash
# Metrics Server 설치
$ kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# 설치 확인
$ kubectl get deployment metrics-server -n kube-system

# 노드 및 파드 메트릭 확인 (Optional)
$ kubectl top nodes
$ kubectl top pods
```
Note: Metrics Server는 클러스터의 리소스(CPU, 메모리) 사용량을 수집하여 HPA가 이를 기반으로 Pod를 스케일링할 수 있도록 지원합니다. 해당 프로젝트에서는 CPU 기반으로 작동합니다.

### 5. 애플리케이션 배포

```bash
$ kubectl apply -f manifest/
```

## Validation

### 1. 서비스 확인

```bash
$ kubectl get svc -A
```

### 2. ingress 및 ALB 확인

```bash
$ kubectl get ingress -A
```

### 3. 애플리케이션 확인

```bash
$ curl http://<alb-dns>
```
