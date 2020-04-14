#!/bin/bash

  UPDATED_FILES=`git diff --name-only ${CI_COMMIT_SHA}~ ${CI_COMMIT_SHA}`
  DOCKERFILE=${DOCKERFILE:-Dockerfile}

  log() {
    echo -e "$(date "+%T.%2N") ${@}"
  }

  info() {
    log "INFO  ==> ${@}"
  }

  warn() {
    log "WARN  ==> ${@}"
  }

  error() {
    2>&1 log "ERROR ==> ${@}"
  }

  docker_login() {
    local registry=${1}
    local username=${2}
    local password=${3}

    info "Authenticating with ${registry}..."
    docker login $registry -u $username -p $password
  }

  docker_pull_parent_image () {
      local docker_file=$1
      local parent_images=`sed -n  's|^FROM[[:blank:]]*\([[:graph:]]*\).*|\1|p' ${docker_file} | uniq`
      for parent_image in ${parent_images[@]};do
          info "docker pull ${parent_image}"
          docker pull $parent_image
      done
  }

  docker_push() {
    local IMAGE_BUILD_TAG=${1}
    local IMAGE_BUILD_DIR=${2:-.}

    info "Pushing '$IMAGE_BUILD_TAG'..."
    #docker push $REGISTRY_IMAGE:$IMAGE_BUILD_TAG
    docker push $IMAGE_BUILD_TAG

  }

  docker_build_and_push() {
    if ! docker_build ${1} ${2}; then
      return 1
    fi
    docker_push ${1} ${2}
  }

  function docker_build() {
    local IMAGE_BUILD_TAG=${1}
    local IMAGE_BUILD_DIR=${2:-.}
    if [[ ! -f $IMAGE_BUILD_DIR/$DOCKERFILE ]]; then
      error "$IMAGE_BUILD_DIR/$DOCKERFILE does not exist, please inspect the release configuration in .gitlab-ci.yml"
      return 1
    fi

    info "Building '$IMAGE_BUILD_TAG' from '$IMAGE_BUILD_DIR/'..."
    docker build --rm=false -f $IMAGE_BUILD_DIR/$DOCKERFILE -t $IMAGE_BUILD_TAG $IMAGE_BUILD_DIR/ || return 1
  }

  docker_login $ALI_DOCKER_REGISTRY $ALI_DOCKER_USER $ALI_DOCKER_PASS
  # docker_login $HUAWEI_DOCKER_REGISTRY $HUAWEI_DOCKER_USER $HUAWEI_DOCKER_PASS

  for IMAGE_TAG in ${IMAGE_TAGS[@]};do
    IFS='-' read -r -a s <<< "$IMAGE_TAG"

    version=${s[0]}
    variant=${s[1]}
    suite=${s[2]}

    image_path=${version}/${suite}/${variant}

    echo $UPDATED_FILES
    echo $image_path
    if echo $UPDATED_FILES | grep -qi $image_path; then

       docker_pull_parent_image ${image_path}/Dockerfile
       docker_build shopex-helmfile:${IMAGE_TAG} ${image_path}

       for IMAGE_REGISTRY in ${IMAGE_REGISTRIES[@]};do
         docker tag shopex-helmfile:${IMAGE_TAG} ${IMAGE_REGISTRY}:${IMAGE_TAG}
         docker_push ${IMAGE_REGISTRY}:${IMAGE_TAG} ${image_path}
       done

       docker rmi -f shopex-helmfile:${IMAGE_TAG}
    else
        echo "无更新"
    fi
  done
