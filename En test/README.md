# Fichiers en cours de test

Déploiement de [Jenkins](jenkins.yml) sur la machine cloud-3
Déploiement de [SonarQube](sonarqube.yml) sur la machine cloud-3
Déploiement de [Jenkins Token](jenkins-k3s.yml) qui génère des clés/certificats pour Jenkins

Récupérer le certificat
```bash
kubectl get secret jenkins-token -n default -o jsonpath='{.data.ca\.crt}' | base64 --decode
```
Récupérer le token
```bash
kubectl get secret jenkins-token -n default -o jsonpath='{.data.token}' | base64 --decode
```