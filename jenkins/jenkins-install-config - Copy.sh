#!/bin/bash

# 1. Установка Jenkins

# Добавляем Jenkins репозиторий и импортируем ключ
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key

# Обновляем пакеты и устанавливаем Jenkins
sudo yum upgrade -y
sudo yum install java-11-openjdk -y
sudo yum install jenkins -y

# Запускаем и добавляем Jenkins в автозагрузку
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Ожидание для завершения запуска Jenkins
sleep 30

# 2. Создание пользователя admin

# Получаем временный пароль для первоначальной настройки Jenkins
TEMP_ADMIN_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# Используем API для создания пользователя через скрипт Groovy
cat <<EOF | sudo tee /var/lib/jenkins/init.groovy.d/basic-security.groovy
#!groovy
import jenkins.model.*
import hudson.security.*
import hudson.util.*
import jenkins.security.s2m.AdminWhitelistRule

def instance = Jenkins.getInstance()
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "password")
instance.setSecurityRealm(hudsonRealm)
instance.save()
EOF

# Перезапускаем Jenkins чтобы применить изменения
sudo systemctl restart jenkins

# 3. Создание Pipeline для мониторинга GitHub репозитория

# Создаем конфигурацию pipeline
cat <<EOF | sudo tee /var/lib/jenkins/jobs/MonitorGitHubPipeline/config.xml
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <actions>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty plugin="workflow-job@2.40">
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github@1.34.1">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </actions>
  <description>Pipeline для мониторинга GitHub репозитория на наличие изменений</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.92">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.4.5">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/MobTesthw/WebPy/</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

# Перезапуск Jenkins чтобы применить pipeline
sudo systemctl restart jenkins

echo "Jenkins установлен, пользователь admin создан, и pipeline для мониторинга GitHub настроен."
