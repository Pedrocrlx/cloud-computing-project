resource "minikube_cluster" "main" {
  driver       = "docker"
  cluster_name = local.current_client
  cpus         = 2
  memory       = "4096mb" 
  addons       = ["ingress", "default-storageclass", "storage-provisioner"]
  wait         = ["all"] 
}

# Create TLS Private Keys (1 per environment)
resource "tls_private_key" "pk" {
  for_each  = toset(local.client_envs) # Create one key per environment Prod, Dev...
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create Self-Signed Certificate (1 per environment)
resource "tls_self_signed_cert" "cert" {
  for_each        = toset(local.client_envs)
  private_key_pem = tls_private_key.pk[each.key].private_key_pem

  subject {
    common_name  = "odoo.${each.key}.${local.current_client}.local"
    organization = "Terraform Odoo Corp"
  }

  validity_period_hours = 24

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Generate random passwords for DB (1 per environment, e.g., Prod, Dev...)
resource "random_password" "db_pass" {
  for_each = toset(local.client_envs)
  length   = 16
  special  = false # No special characters for simplicity
}

resource "local_file" "k8s_manifests" {
  for_each = local.manifests_map

  filename = "${path.module}/manifests/${each.value.client}/${each.value.env}/${each.value.tpl_name}.yaml"
   
  content = templatefile("${path.module}/templates/${each.value.tpl_name}.yaml", {
    namespace = each.value.namespace
    domain    = each.value.domain
  
    # If the template requires a DB password, provide it in base64
    db_password_b64 = base64encode(lookup(random_password.db_pass, each.value.env, { result = "odoo" }).result)

    # Certificate and Key in base64
    cert_b64  = base64encode(lookup(tls_self_signed_cert.cert, each.value.env, { cert_pem = "" }).cert_pem)
    key_b64   = base64encode(lookup(tls_private_key.pk, each.value.env, { private_key_pem = "" }).private_key_pem)
  })
}

resource "null_resource" "apply_manifests" {
  triggers = {
    manifest_hash = sha256(join("", [for f in local_file.k8s_manifests : f.content]))
  }
  depends_on = [minikube_cluster.main, local_file.k8s_manifests]

  provisioner "local-exec" {
    command = "sleep 60 && minikube -p ${minikube_cluster.main.cluster_name} kubectl -- apply -R -f ${path.module}/manifests/${local.current_client}/"
  }
}