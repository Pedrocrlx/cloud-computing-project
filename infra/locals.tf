locals {
  current_client = terraform.workspace
  client_envs    = lookup(var.clients, local.current_client, [])

  manifests_list = flatten([
    for env in local.client_envs : [
      for tpl in ["01-namespace", "02-secret", "03-db-statefulset", "04-db-service", "05-odoo-deployment", "06-odoo-service", "07-tls-secret", "08-ingress"] : {
        id          = "${env}-${tpl}"
        client      = local.current_client
        env         = env
        tpl_name    = tpl
        namespace   = "${local.current_client}-${env}"
        domain      = "odoo.${env}.${local.current_client}.local"
      }
    ]
  ])

  manifests_map = {
    for item in local.manifests_list : item.id => item
  }
}