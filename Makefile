.PHONY: build run docker-build argocd-deploy clean

ECR_REPO = 293222827824.dkr.ecr.us-east-1.amazonaws.com/roboshop-orders

build:
	mvn clean package -DskipTests

run:
	MONGO_URL=mongodb://localhost:27017/orders AMQP_HOST=localhost mvn spring-boot:run

docker-build:
	aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 293222827824.dkr.ecr.us-east-1.amazonaws.com
	docker build -t $(ECR_REPO):$(image_tag) .
	trivy image $(ECR_REPO):$(image_tag) -s CRITICAL,HIGH --ignore-unfixed
	docker push $(ECR_REPO):$(image_tag)

argocd-deploy:
	argocd login $(argocd_server) --skip-test-tls --username admin --password $(argocd_admin_password)
	argocd app create roboshop-orders --sync-policy auto --upsert \
		--repo https://github.com/nikkaushal/roboshop-helm-v1.git \
		--path . \
		--dest-server https://kubernetes.default.svc \
		--dest-namespace roboshop \
		--helm-set services.orders.tag=$(image_tag) \
		--values values/roboshop-orders.yml

clean:
	mvn clean
