# retool

## 1. helm 설치하기

## 2. helm list

```shell
helm list -n retool
```

## 3. retool secret 생성

```shell
kubectl create secret generic retool-secret \
-n retool \
--from-literal=license-key=<license_key> \
--from-literal=encryption-key=<encryption_key> \
--from-literal=jwt-secret=<jwt_secret>
```

## 4. helm install

helm install retool retool/retool -n retool -f ./environments/staging/addons/retool/values.yaml

## 5. helm upgrade

```shell
helm upgrade retool retool/retool -n retool -f ./environments/staging/addons/retool/values.yaml
```
