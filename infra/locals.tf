locals {
  raw_cluster_list = flatten([
    for client_name, envs in var.clients : [
      for env_name in envs : {
        id          = "${client_name}-${env_name}"
        client      = client_name
        environment = env_name
        cluster_name = "${client_name}-${env_name}"
      }
    ]
  ])

  clusters_map = {
    for cluster in local.raw_cluster_list : cluster.id => cluster
  }
}