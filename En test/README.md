# Fichiers en cours de test

Installer K3s sur sun
```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -
```

Récupérer le token
```bash
cat /var/lib/rancher/k3s/server/node-token
```

Installer K3s-agent sur cloud
```bash
curl -sfL https://get.k3s.io | K3S_URL="https://192.168.0.10:6443" K3S_TOKEN=<token> sh -
```

Déploiement de [Jenkins](jenkins.yml) sur la machine cloud-3
Déploiement de [SonarQube](sonarqube.yml) sur la machine cloud-3
Déploiement de [Jenkins Token](jenkins-k3s.yml) qui génère des clés/certificats pour Jenkins
Reverse proxy nginx [text](default) à mettre dans `/etc/nginx/sites-available/default`

Récupérer le certificat
```bash
kubectl get secret jenkins-token -n default -o jsonpath='{.data.ca\.crt}' | base64 --decode
```

Récupérer le token
```bash
kubectl get secret jenkins-token -n default -o jsonpath='{.data.token}' | base64 --decode
```

| App       | ip privé            | ip privé 2          |
| --------- | ------------------- | ------------------- |
| jenkins   | 10.43.xxx.xxx:8080  | 192.168.80.13:30001 |
| sonarqube | 10.43.xxx.xxx:9000  | 192.168.80.13:30002 |