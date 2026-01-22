variable "clients" {
  description = "Map of clients to their respective environments"
  type        = map(list(string))
  
  default = {
    airbnb    = ["dev", "prod"]
    #nike      = ["dev", "qa", "prod"]
    #mcdonalds = ["dev", "qa", "beta", "prod"]
  }
}

