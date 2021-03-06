#!/usr/bin/env bash
set +xe

KX_PATH="$HOME/.kx"
mkdir -p "$KX_PATH/cache"

case "$OSTYPE" in
  *arwin*)
    OS="darwin"
    ;;
  *in32* | *indows*)
    OS="windows"
    ;;
  *)
    OS="linux"
esac

# Attempt to load the server version from cache
if [ ! -z "$KUBECONFIG" ]; then
  if [ "$OS" == "darwin" ]; then
    KUBECONFIG_HASH=$(echo "$KUBECONFIG" | shasum -a 256 | cut -c1-5)
  else
    KUBECONFIG_HASH=$(echo "$KUBECONFIG" | sha256sum | cut -c1-5)
  fi
  VERSION_CACHE_FILE="$KX_PATH/cache/$KUBECONFIG_HASH"
  TARGET_VERSION=$(cat "$VERSION_CACHE_FILE" 2> /dev/null)
fi

# Get the server version from the server if not cached
if [ -z "$TARGET_VERSION" ]; then
  if [ $(echo $TARGET_VERSION | egrep "alpha|beta|rc") ]; then
    TARGET_VERSION=$(kubectl version -o json | jq -r '.serverVersion.gitVersion' | cut -d'.' -f1-4)
  else
    TARGET_VERSION=$(kubectl version -o json | jq -r '.serverVersion.gitVersion' | cut -d'.' -f1-3)
  fi
fi

# Fill the cache if possible
if [ ! -z "$KUBECONFIG" ]; then
  echo "$TARGET_VERSION" > "$VERSION_CACHE_FILE"
fi

TARGET=$KX_PATH/kubectl-$TARGET_VERSION

if [ ! -f $TARGET ]; then
  cd "$KX_PATH"
  curl -LO "https://storage.googleapis.com/kubernetes-release/release/$TARGET_VERSION/bin/$OS/amd64/kubectl"
  mv $KX_PATH/kubectl $TARGET
  chmod +x $TARGET
fi

$TARGET "$@"
