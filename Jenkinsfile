
pipeline {
    options {
        buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '30'))
        disableConcurrentBuilds()
    }

    agent {
        docker {
            image 'nexusdockerhosted.sys.ourtesco.com/rdf-api-dev/buildagent:20210215'
            args '--group-add docker -v /var/run/docker.sock:/var/run/docker.sock -v $HOME/.m2:/home/jenkins/.m2 -v /appl/m2/repository:/appl/m2/repository -v $HOME/.sonar:/home/jenkins/.sonar -v $HOME/.docker/config.json:/home/jenkins/.docker/config.json'
        }
    }

    parameters {
        choice(name: 'IMAGE', choices: ["buildagent","centos7-java8","centos7-java8-appl","centos7-java8-launcher-appl","centos7-java11","akhq-0.20.0","zookeeper-2.8.1","kafka-2.8.1","secure-redis","splunk-universalforwarder","kafka_connect-2.8.0","pg-admin"], description: 'Image to build')
        string(name: 'IMAGE_TAG', defaultValue: '', description: '')
        booleanParam(name: 'PUBLISH', defaultValue: false, description: 'Publish Docker Image?')

    }

    stages {
        stage("Build Docker Image") {
            steps {
                dir('Docker_scripts') {
                    withCredentials([usernamePassword(credentialsId: 'svc-longrange-global-nexus', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                        sh "docker build -t nexusdockerhosted.sys.ourtesco.com/rdf-api-dev/${params.IMAGE}:${params.IMAGE_TAG} --build-arg nexus_user=${USERNAME} --build-arg nexus_pass=${PASSWORD} --target ${params.IMAGE} " + getContextPath("${params.IMAGE}")
                    }
                }
            }
        }
        stage("Publish Docker Image") {
            when {
                expression { return params.PUBLISH }
            }
            steps {
                sh "docker push nexusdockerhosted.sys.ourtesco.com/rdf-api-dev/${params.IMAGE}:${params.IMAGE_TAG}"
            }
        }
    }

    post {
        always {
            sh "docker rmi nexusdockerhosted.sys.ourtesco.com/rdf-api-dev/${params.IMAGE}:${params.IMAGE_TAG}"
            sh "if [[ ! -z `docker images -f 'dangling=true' -q` ]]; then docker rmi `docker images -f 'dangling=true' -q`; fi"
        }

        success {
            script {
                if (params.PUBLISH == true || env.BRANCH_NAME == 'master') {
                    rtp parserName: 'HTML', stableText: "</br><h4>Docker Image: ${params.IMAGE}:${params.IMAGE_TAG}</h4>"
                }
            }
        }

        unsuccessful {
            script {
                    withCredentials([string(credentialsId: 'rdfapi_teams_webhookurl', variable: 'WEBHOOKURL')]) {
                        office365ConnectorSend webhookUrl: "${WEBHOOKURL}"
                }
            }
        }
    }
}
