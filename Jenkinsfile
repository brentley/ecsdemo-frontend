pipeline {
    agent {
        label "jenkins-ruby"
    }
    environment {
      ORG               = 'jenkinsx'
      APP_NAME          = 'ecsdemo-frontend'
      CHARTMUSEUM_CREDS = credentials('jenkins-x-chartmuseum')
    }
    stages {
      stage('CI Build and push snapshot') {
        when {
          branch 'PR-*'
        }
        environment {
          PREVIEW_VERSION = "0.0.0-SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER"
          PREVIEW_NAMESPACE = "$APP_NAME-$BRANCH_NAME".toLowerCase()
          HELM_RELEASE = "$PREVIEW_NAMESPACE".toLowerCase()
        }
        steps {
          container('ruby') {
            sh "docker build -t $DOCKER_REGISTRY/$ORG/$APP_NAME:$PREVIEW_VERSION ."
            sh "docker push $DOCKER_REGISTRY/$ORG/$APP_NAME:$PREVIEW_VERSION"
          }

          dir ('./charts/preview') {
           container('ruby') {
             sh "make preview"
             sh "jx preview --app $APP_NAME --dir ../.."
           }
          }
        }
      }
      stage('Build Release') {
        when {
          branch 'master'
        }
        steps {
          container('ruby') {
            // ensure we're not on a detached head
            sh "git checkout master"
            // until we switch to the new kubernetes / jenkins credential implementation use git credentials store
            sh "git config --global credential.helper store"
            // so we can retrieve the version in later steps
            sh "echo \$(jx-release-version) > VERSION"
          }
          dir ('./charts/ecsdemo-frontend') {
            container('ruby') {
              sh "jx step git credentials"
              sh "make tag"
            }
          }
          container('ruby') {
            sh "docker build -t $DOCKER_REGISTRY/$ORG/$APP_NAME:\$(cat VERSION) ."
            sh "docker push $DOCKER_REGISTRY/$ORG/$APP_NAME:\$(cat VERSION)"
          }
        }
      }
      stage('Promote to Environments') {
        when {
          branch 'master'
        }
        steps {
          dir ('./charts/ecsdemo-frontend') {
            container('ruby') {
              sh 'jx step changelog --version v\$(cat ../../VERSION)'

              // release the helm chart
              sh 'jx step helm release'

              // promote through all 'Auto' promotion Environments
              sh 'jx promote -b --all-auto --timeout 1h --version \$(cat ../../VERSION)'
            }
          }
        }
      }
    }
    post {
        always {
            cleanWs()
        }
    }
  }
