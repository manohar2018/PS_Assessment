
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
                sh "docker build -t public.ecr.aws/m4n3o5v2/demo:${params.IMAGE_TAG} ." 
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
            sh """
              TOKEN=`aws ecr get-login --region`
              aws ecr --region us-east-1 | docker login -u AWS -p $TOKEN public.ecr.aws/m4n3o5v2
              #docker login -u AWS ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/m4n3o5v2
              docker rmi public.ecr.aws/m4n3o5v2/demo:${params.IMAGE_TAG}
              if [[ ! -z `docker images -f 'dangling=true' -q` ]]; then docker rmi `docker images -f 'dangling=true' -q`; fi
            """
            
        }
    }
}
