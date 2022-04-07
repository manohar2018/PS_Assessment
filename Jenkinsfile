
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
                dir('Docker_scripts') {
                    withCredentials([usernamePassword(credentialsId: 'svc-longrange-global-nexus', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                        sh "docker build -t public.ecr.aws/m4n3o5v2/demo:${params.IMAGE_TAG} --build-arg nexus_user=${USERNAME} --build-arg nexus_pass=${PASSWORD} --target ${params.IMAGE} " + getContextPath("${params.IMAGE}")
                    }
                }
            }
        }
        stage("Publish Docker Image") {
            when {
                expression { return params.PUBLISH }
            }
            steps {
                sh "docker push public.ecr.aws/m4n3o5v2/demo:${params.IMAGE_TAG}"
            }
        }
    }

    post {
        always {
            sh "docker rmi public.ecr.aws/m4n3o5v2/demo:${params.IMAGE_TAG}"
            sh "if [[ ! -z `docker images -f 'dangling=true' -q` ]]; then docker rmi `docker images -f 'dangling=true' -q`; fi"
        }
    }
}
