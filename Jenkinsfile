pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
    }

    triggers {
        cron('H H * * 0')
    }

    parameters {
        string(name: 'IMAGE_PLATFORMS', defaultValue: 'linux/amd64,linux/arm64,linux/arm/v7', description: 'Target platforms for the multi-architecture image')
    }

    environment {
        IMAGE_NAME = 'dohun0310/cups'
        REGISTRY_URL = 'https://index.docker.io/v1/'
        REGISTRY_CREDENTIALS_ID = 'Docker-Hub'
        BUILDER_NAME = "cups-builder-${BUILD_TAG}"
        IMAGE_PLATFORMS = "${params.IMAGE_PLATFORMS ?: 'linux/amd64,linux/arm64,linux/arm/v7'}"
    }

    stages {
        stage('Checkout') {
            steps {
                deleteDir()
                checkout scm

                script {
                    def branch = (env.BRANCH_NAME ?: env.GIT_BRANCH ?: '')
                        .replaceFirst(/^origin\//, '')

                    env.CURRENT_BRANCH = branch
                    env.PUBLISH_IMAGE = branch == 'main' ? 'true' : 'false'
                }
            }
        }

        stage('Prepare builder') {
            steps {
                sh '''
                    set -eu
                    docker run --privileged --rm tonistiigi/binfmt --install all
                    docker buildx create --name "${BUILDER_NAME}" --driver docker-container --bootstrap
                '''
            }
        }

        stage('Build image') {
            when {
                environment name: 'PUBLISH_IMAGE', value: 'false'
            }
            steps {
                sh '''
                    set -eu
                    docker buildx build \
                        --builder "${BUILDER_NAME}" \
                        --platform "${IMAGE_PLATFORMS}" \
                        --tag "${IMAGE_NAME}:ci" \
                        .
                '''
            }
        }

        stage('Publish image') {
            when {
                branch 'main'
            }
            steps {
                script {
                    def version = new Date().format('yyyy-MM-dd')

                    docker.withRegistry(env.REGISTRY_URL, env.REGISTRY_CREDENTIALS_ID) {
                        withEnv(["IMAGE_VERSION=${version}"]) {
                            sh '''
                                set -eu
                                docker buildx build \
                                    --builder "${BUILDER_NAME}" \
                                    --platform "${IMAGE_PLATFORMS}" \
                                    --tag "${IMAGE_NAME}:${IMAGE_VERSION}" \
                                    --tag "${IMAGE_NAME}:latest" \
                                    --push \
                                    .
                            '''
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            sh 'docker buildx rm "${BUILDER_NAME}" >/dev/null 2>&1 || true'
            script {
                def icon = [
                    SUCCESS: '✅',
                    FAILURE: '❌',
                    ABORTED: '⚠️',
                    UNSTABLE: '⚠️'
                ].get(currentBuild.currentResult, 'ℹ️')

                def message = """${icon} ${env.JOB_NAME} #${env.BUILD_NUMBER}: ${currentBuild.currentResult}
Commit: ${(env.GIT_COMMIT ?: 'unknown').take(7)}
Build: ${env.BUILD_URL}"""

                try {
                    withCredentials([
                        string(credentialsId: 'Telegram-Token', variable: 'TELEGRAM_TOKEN'),
                        string(credentialsId: 'Telegram-ID', variable: 'TELEGRAM_ID')
                    ]) {
                        withEnv(["TELEGRAM_MESSAGE=${message}"]) {
                            def notified = sh(
                                returnStatus: true,
                                script: '''
                                    set +x
                                    curl --silent --show-error --fail --max-time 10 --output /dev/null \
                                        --data-urlencode "chat_id=${TELEGRAM_ID}" \
                                        --data-urlencode "text=${TELEGRAM_MESSAGE}" \
                                        "${TELEGRAM_API_BASE:-https://api.telegram.org}/bot${TELEGRAM_TOKEN}/sendMessage"
                                '''
                            )

                            if (notified != 0) {
                                echo 'Telegram notification failed'
                            }
                        }
                    }
                } catch (Exception error) {
                    echo "Telegram notification unavailable: ${error.class.simpleName}"
                }
            }
        }
    }
}