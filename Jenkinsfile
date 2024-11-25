pipeline {
    agent any

    environment {
        // Define environment variables
        TERRAFORM_DIR = 'terraform' // Path to your Terraform configuration files
    }

    stages {
        stage('Checkout Code') {
            steps {
                // Clone the repository
                git branch: 'main', url: 'https://github.com/malekhassine/terraform_aws_k8s_migration.git'
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    // Initialize Terraform
                    sh '''
                    cd $TERRAFORM_DIR
                    terraform init -input=false
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    // Generate Terraform plan
                    sh '''
                    cd $TERRAFORM_DIR
                    terraform plan -out=tfplan -input=false
                    '''
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    // Apply Terraform changes
                    sh '''
                    cd $TERRAFORM_DIR
                    terraform apply -input=false -auto-approve tfplan
                    '''
                }
            }
        }
    }

    post {
        always {
            // Archive logs and Terraform state file for debugging and tracking
            archiveArtifacts artifacts: '**/*.tfstate', fingerprint: true
        }
        success {
            // Notify on success
            echo 'Terraform apply completed successfully!'
        }
        failure {
            // Notify on failure
            echo 'Terraform apply failed!'
        }
    }
}
