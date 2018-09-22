#!/bin/bash
#set -x
pwd

# Use this script as a starting point to create your own deployment.yml

# Make sure the cluster is running and get the ip_address
ip_addr=$(bx cs workers $PIPELINE_KUBERNETES_CLUSTER_NAME | grep normal | awk '{ print $2 }')
if [ -z $ip_addr ]; then
  echo "$PIPELINE_KUBERNETES_CLUSTER_NAME not created or workers not ready"
  exit 1
fi

# Initialize script variables
NAME="$IDS_PROJECT_NAME"
IMAGE="$PIPELINE_IMAGE_URL"
PORT=$(bx cr image-inspect $IMAGE --format "{{ .ContainerConfig.ExposedPorts }}" | sed -E 's/^[^0-9]*([0-9]+).*$/\1/')
if [ -z "$PORT" ]; then
    PORT=5000
    echo "Port not found in Dockerfile, using $PORT"
fi

#
if [ -z "$NAME_SPACE" ]; then
    NAME_SPACE=default
    echo "Namespace not found in ENV, using default"
fi

#
if [ -z "$DOMAIN" ]; then
    DOMAIN=9.218.8.32.nip.io
    echo "DOMAIN not found in ENV, using $DOMAIN"
fi

#
if [ -z "$ALB" ]; then
    ALB=private-crb1470a2853a34eb39f6b356881c3650b-alb1
    echo "ALB not found in ENV, using $ALB"
fi

#
if [ -z "$PROFILE" ]; then
    PROFILE=bluemix-public
    echo "PROFILE not found in ENV, using $PROFILE"
fi

echo ""
echo "Deploy environment variables:"
echo "NAME=$NAME"
echo "IMAGE=$IMAGE"
echo "PORT=$PORT"
echo ""

DEPLOYMENT_FILE="deployment.yml"
echo "Creating deployment file $DEPLOYMENT_FILE"

kubectl create namespace ranjeeta-spring-fvt || true
kubectl get secret bluemix-default-secret -o yaml | sed 's/default/'"$NAME_SPACE"'/g' > secret.yaml
kubectl -n $NAME_SPACE apply -f secret.yaml || true

# Build the deployment file
DEPLOYMENT=$(cat <<EOF''
apiVersion: v1
kind: Namespace
metadata:
  name: $NAME_SPACE
spec:
  finalizers:
  - kubernetes
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: $NAME
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: $NAME
    spec:
      containers:
      - name: $NAME
        image: $IMAGE
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: $PORT
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "$PROFILE"
      imagePullSecrets:
        - name: bluemix-$NAME_SPACE-secret
---
apiVersion: v1
kind: Service
metadata:
  name: $NAME
  labels:
    app: $NAME
spec:
  ports:
  - port: $PORT
    protocol: TCP
    targetPort: $PORT
  selector:
    app: $NAME
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: $NAME
  annotations:
    ingress.bluemix.net/ALB-ID: "$ALB"
spec:
  tls:
  - hosts:
    - $NAME.$NAME_SPACE.$DOMAIN
    secretName: ranjeeta-spring
  rules:
  - host: $NAME.$NAME_SPACE.$DOMAIN
    http:
      paths:
      - path: /
        backend:
          serviceName: $NAME
          servicePort: $PORT
EOF
)

# Substitute the variables
echo "$DEPLOYMENT" > $DEPLOYMENT_FILE
sed -i 's#$NAME_SPACE#'"$NAME_SPACE"'#g' $DEPLOYMENT_FILE
sed -i 's/$NAME/'"$NAME"'/g' $DEPLOYMENT_FILE
sed -i 's=$IMAGE='"$IMAGE"'=g' $DEPLOYMENT_FILE
sed -i 's/$PORT/'"$PORT"'/g' $DEPLOYMENT_FILE

sed -i 's#$DOMAIN#'"$DOMAIN"'#g' $DEPLOYMENT_FILE
sed -i 's#$ALB#'"$ALB"'#g' $DEPLOYMENT_FILE
sed -i 's#$PROFILE#'"$PROFILE"'#g' $DEPLOYMENT_FILE


# Show the file that is about to be executed
echo ""
echo "DEPLOYING USING MANIFEST:"
echo "cat $DEPLOYMENT_FILE"
cat $DEPLOYMENT_FILE
echo ""

# Execute the file
kubectl="kubectl -n $NAME_SPACE" 

echo "KUBERNETES COMMAND:"
echo "kubectl apply -f $DEPLOYMENT_FILE"
$kubectl apply -f $DEPLOYMENT_FILE 
echo ""

echo ""
echo "DEPLOYED SERVICE:"
$kubectl describe services $NAME 
echo ""

echo "DEPLOYED PODS:"
$kubectl describe pods --selector app=$NAME 
echo ""

echo "DEPLOYED INGRESS:"
$kubectl describe ingress $NAME 
echo ""

# Show the IP address and the PORT of the running app
port=$($kubectl get services | grep "$NAME " | sed 's/.*:\([0-9]*\).*/\1/g')
echo "RUNNING APPLICATION:"
echo "URL=http://$ip_addr"
echo "PORT=$port"
echo ""
echo "$NAME running at: http://$ip_addr:$port"

