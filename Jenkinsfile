pipeline {
    agent any

    environment {
        DOCKER_IMAGE_NAME = 'devanshpandey21/easyshop-app'
        DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
        GIT_BRANCH = "gitops"
    }

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'npm install'
                sh 'npm test'
            }
        }

        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh 'sonar-scanner'
                }
            }
        }

        stage('Trivy Filesystem Scan') {
            steps {
                sh 'trivy fs . --exit-code 1 --severity HIGH,CRITICAL'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} .'
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} --exit-code 1 --severity HIGH,CRITICAL'
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker push ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
                    '''
                }
            }
        }

        stage('Update GitOps Repo') {
            steps {
                sh '''
                    git checkout ${GIT_BRANCH}
                    git pull origin ${GIT_BRANCH}

                    sed -i "s|devanshpandey21/easyshop-app:.*|${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}|g" kubernetes/08-easyshop-deployment.yaml

                    git add .
                    git commit -m "Update image ${DOCKER_IMAGE_TAG}" || true
                    git push origin ${GIT_BRANCH}
                '''
            }
        }
    }
}
