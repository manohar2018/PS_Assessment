
pipeline {
    options {
        buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '30'))
        disableConcurrentBuilds()
    }

    agent any
    

    parameters {
        
        string(name: 'IMAGE_TAG', defaultValue: '', description: '')
        booleanParam(name: 'PUBLISH', defaultValue: false, description: 'Publish Docker Image?')

    }

    stages {
        stage("Build Docker Image") {
            steps {
                sh "docker build -t 714972241463.dkr.ecr.us-east-1.amazonaws.com/demo:${params.IMAGE_TAG} ." 
            }
        }
        stage("Publish Docker Image") {
            when {
                expression { return params.PUBLISH }
            }
            steps {

                sh """
                 docker login --username AWS --password `aws ecr get-login-password --region us-east-1` 714972241463.dkr.ecr.us-east-1.amazonaws.com
                 docker push 714972241463.dkr.ecr.us-east-1.amazonaws.com/demo:${params.IMAGE_TAG}
                """
            }
        }
    }

    post {
        always {
            sh """#!/bin/bash -xe
              
              docker rmi 714972241463.dkr.ecr.us-east-1.amazonaws.com/demo:${params.IMAGE_TAG}
              if [[ ! -z `docker images -f 'dangling=true' -q` ]]; then docker rmi `docker images -f 'dangling=true' -q`; fi
            """
            
        }
    }
}
