resource "minikube_cluster" "k8s_cluster" {
  for_each = local.clusters_map

  driver       = "docker"
  cluster_name = each.value.cluster_name
  
  cpus   = 1
  memory = "1200mb" 
  
  addons = [
    "ingress",
    "default-storageclass",
    "storage-provisioner"
  ]
  
  wait = ["all"] 
}


resource "local_file" "k8s_manifests" {
  for_each = {
    for item in flatten([
      for cluster_id, cluster in local.clusters_map : [
        # Nota que removi o Ingress/TLS desta lista por enquanto, adicionamos no próximo passo
        for tpl in ["01-namespace", "02-secret", "03-db-statefulset", "04-db-service", "05-odoo-deployment", "06-odoo-service"] : {
          id        = "${cluster_id}-${tpl}"
          cluster   = cluster
          tpl_name  = tpl
        }
      ]
    ]) : item.id => item
  }

  filename = "${path.module}/manifests/${each.value.cluster.id}/${each.value.tpl_name}.yaml"
  
  content = templatefile("${path.module}/templates/${each.value.tpl_name}.yaml", {
    namespace = "${each.value.cluster.client}-${each.value.cluster.environment}"
  })
}

# 3. Aplicação Final (O "Apply" Mágico)
resource "null_resource" "apply_manifests" {
  for_each = local.clusters_map

  # Só corre depois do cluster estar UP e dos ficheiros YAML terem sido gerados
  depends_on = [minikube_cluster.k8s_cluster, local_file.k8s_manifests]

  triggers = {
    # Isto força o apply a correr sempre que houver mudanças nos templates ou na lista de clusters
    manifest_hash = sha256(join("", [for f in local_file.k8s_manifests : f.content if f.filename != ""]))
  }

  provisioner "local-exec" {
    # O kubectl apply -f numa pasta aplica os ficheiros por ordem alfabética
    # 01-namespace corre primeiro, garantindo que o namespace existe antes dos outros.
    command = "minikube -p ${each.value.cluster_name} kubectl -- apply -f ${path.module}/manifests/${each.key}/"
  }
}