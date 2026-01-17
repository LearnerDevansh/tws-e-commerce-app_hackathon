@Library('Shared') _

pipeline {
    agent any
    
    environment {
        // Docker image configuration
        DOCKER_IMAGE_NAME = 'devanshpandey21/easyshop-app'
        DOCKER_MIGRATION_IMAGE_NAME = 'devanshpandey21/easyshop-migration'
        DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
        
        // Git configuration
        GITHUB_CREDENTIALS = credentials('github-creds')
        GIT_BRANCH = "master"
        GIT_REPO_URL = "https://github.com/LearnerDevansh/tws-e-commerce-app_hackathon.git"
        
        // Kubernetes configuration
        K8S_NAMESPACE = "easyshop"
        DEPLOYMENT_NAME = "easyshop"
        
        // ArgoCD configuration (optional)
        ARGOCD_SERVER = credentials('argocd-server')
        ARGOCD_APP_NAME = "easyshop"
    }
    
    stages {
        stage('Cleanup Workspace') {
            steps {
                script {
                    clean_ws()
                }
            }
        }
        
        stage('Clone Repository') {
            steps {
                script {
                    clone("https://github.com/LearnerDevansh/tws-e-commerce-app_hackathon.git","master")
                }
            }
        }
        
        stage('Build Docker Images') {
            parallel {
                stage('Build Main App Image') {
                    steps {
                        script {
                            docker_build(
                                imageName: env.DOCKER_IMAGE_NAME,
                                imageTag: env.DOCKER_IMAGE_TAG,
                                dockerfile: 'Dockerfile',
                                context: '.'
                            )
                        }
                    }
                }
                
                stage('Build Migration Image') {
                    steps {
                        script {
                            docker_build(
                                imageName: env.DOCKER_MIGRATION_IMAGE_NAME,
                                imageTag: env.DOCKER_IMAGE_TAG,
                                dockerfile: 'scripts/Dockerfile.migration',
                                context: '.'
                            )
                        }
                    }
                }
            }
        }
        
        stage('Run Unit Tests') {
            steps {
                script {
                    run_tests()
                }
            }
        }
        
        stage('Security Scan with Trivy') {
            steps {
                script {
                    // Create directory for results
                  
                    trivy_scan()
                    
                }
            }
        }
        
        stage('Push Docker Images') {
            parallel {
                stage('Push Main App Image') {
                    steps {
                        script {
                            docker_push(
                                imageName: env.DOCKER_IMAGE_NAME,
                                imageTag: env.DOCKER_IMAGE_TAG,
                                credentials: 'docker-creds'
                            )
                        }
                    }
                }
                
                stage('Push Migration Image') {
                    steps {
                        script {
                            docker_push(
                                imageName: env.DOCKER_MIGRATION_IMAGE_NAME,
                                imageTag: env.DOCKER_IMAGE_TAG,
                                credentials: 'docker-creds'
                            )
                        }
                    }
                }
            }
        }
        
        stage('Update Kubernetes Manifests') {
            steps {
                script {
                    update_k8s_manifests(
                        imageTag: env.DOCKER_IMAGE_TAG,
                        manifestsPath: 'kubernetes',
                        gitCredentials: 'github-creds',
                        gitUserName: 'Jenkins CI',
                        gitUserEmail: 'misc.devansh22@gmail.com',
                        gitBranch: env.GIT_BRANCH
                    )
                }
            }
        }
        
        stage('Trigger ArgoCD Sync') {
            when {
                expression { return env.ENABLE_ARGOCD == 'true' }
            }
            steps {
                script {
                    echo "Triggering ArgoCD sync for application: ${env.ARGOCD_APP_NAME}"
                    sh """
                        # Wait for manifest update to be pushed
                        sleep 10
                        
                        # Trigger ArgoCD sync (if ArgoCD CLI is available)
                        if command -v argocd &> /dev/null; then
                            argocd app sync ${env.ARGOCD_APP_NAME} --grpc-web
                            argocd app wait ${env.ARGOCD_APP_NAME} --timeout 300
                        else
                            echo "ArgoCD CLI not found, skipping sync trigger"
                            echo "ArgoCD will auto-sync based on configured policy"
                        fi
                    """
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    echo "Verifying deployment in namespace: ${env.K8S_NAMESPACE}"
                    sh """
                        # Check if kubectl is available
                        if command -v kubectl &> /dev/null; then
                            echo "Checking deployment status..."
                            kubectl rollout status deployment/${env.DEPLOYMENT_NAME} -n ${env.K8S_NAMESPACE} --timeout=5m || true
                            
                            echo "Current pods:"
                            kubectl get pods -n ${env.K8S_NAMESPACE} -l app=easyshop || true
                        else
                            echo "kubectl not available, skipping verification"
                            echo "Deployment will be handled by ArgoCD"
                        fi
                    """
                }
            }
        }
        
        stage('Deployment Summary') {
            steps {
                script {
                    echo """
                    ========================================
                    Deployment Summary
                    ========================================
                    Build Number: ${env.BUILD_NUMBER}
                    Docker Image: ${env.DOCKER_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}
                    Migration Image: ${env.DOCKER_MIGRATION_IMAGE_NAME}:${env.DOCKER_IMAGE_TAG}
                    Git Branch: ${env.GIT_BRANCH}
                    Namespace: ${env.K8S_NAMESPACE}
                    Application URL: https://easyshop.devopsdock.site
                    ========================================
                    """
                }
            }
        }
    }
    
    post {
        success {
            script {
                echo "✅ Pipeline completed successfully!"
                // Add notification here if needed
            }
        }
        failure {
            script {
                echo "❌ Pipeline failed!"
                // Add notification here if needed
            }
        }
        always {
            script {
                // Cleanup
                sh 'docker system prune -f || true'
            }
        }
    }
}
