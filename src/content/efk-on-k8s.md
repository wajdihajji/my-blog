---
title: "Open Distro Elasticsearch, Fluentd and Kibana on on-prem Kubernetes cluster"
date: "2022-02-20"
draft: false
path: "/blog/efk-on-k8s"
---

This blog shows how to deploy [Opendistro Elasticsearch](https://opendistro.github.io/for-elasticsearch-docs/)
and [Fluentbit](https://fluentbit.io/) on on-prem Kubernetes cluster.

### Opendistro ES Helm chart
Create a namespace for the deployment.
```bash
kubectl create namespace kube-logging
```

Create a PV and PVC for Elasticsearch master and data statefulset.
```bash
kubectl apply -f opendistro-es/pv.yaml
```

Create self-signed TLS certificates secret for the Kibana endpoint.
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $KEY_FILE -out $CERT_FILE -subj "/CN=$HOST/O=$HOST"
kubectl create secret tls $CERT_NAME --key $KEY_FILE --cert $CERT_FILE -n kube-logging
```

Update [values.yaml](./opendistro-es/values.yaml) with the settings above
and deploy the Opendistro ES helm chart.
```bash
git clone https://github.com/opendistro-for-elasticsearch/opendistro-build /tmp/opendistro-build
cd /tmp/opendistro-build/helm/opendistro-es/
helm package /tmp/opendistro-build/helm/opendistro-es/
helm install opendistro-es opendistro-es-1.13.1.tgz -n kube-logging --values=./opendistro-es/values.yaml
```

To change the `admin` password.

- Get `internal_users.yml` from a pod of `opendistro-es-master` statefulset.
```bash
kubectl exec -it -n kube-logging opendistro-es-master-0 -- cat  /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/internal_users.yml > /tmp/internal_users.yml
```

- To create a new password of `admin` user, you need the `hash.sh` script available in `opendistro-es-master`
instances.
```bash
kubectl exec -n kube-logging opendistro-es-master-0 -- bash  /usr/share/elasticsearch/plugins/opendistro_security/tools/hash.sh -p strongpassword
```

- Edit `/tmp/internal_users.yml` by setting `admin` password with the output of the command above.
You can also change credentials of other users.

Create a secret for `internal_users.yml`.
```bash
kubectl create secret generic -n kube-logging internal-users --from-file=/tmp/internal_users.yml
```
- Update [values.yaml](./opendistro-es/values.yaml) and upgrade the helm chart.

## Fluentbit

Get the root certificate from one of the `opendistro-es-client` deployment pods.
```bash
kubectl exec -it -n kube-logging opendistro-es-client-6d45c88594-gfh2s -- cat /usr/share/elasticsearch/config/root-ca.pem > /tmp/es-root-ca.pem
```

Create a configmap for the root certificate.
```bash
kubectl create cm -n kube-logging es-root-ca --from-file=/tmp/es-root-ca.pem
```

Create secret containing `FLUENT_ELASTICSEARCH_USER` and `FLUENT_ELASTICSEARCH_PASSWORD` values.
```bash
kubectl create secret generic opendistro-es-client -n kube-logging --from-literal=user=foo --from-literal=password=bar
```

Update [fluentbit-ds.yaml](./fluentbit/fluentbit-ds.yaml)

Create the resources in [fluentbit](./fluentbit) directory.
```bash
kubectl apply -f ./fluentbit
```

## TODO
- For production environment, make sure to use your own SSL certificates.
