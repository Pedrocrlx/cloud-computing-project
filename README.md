# Cloud Infrastructure Automation: Multi-Tenant Odoo Deployment

## Project Overview

This project demonstrates a highly scalable, automated Infrastructure as Code (IaC) solution for deploying Odoo ERP instances.

The goal was to simulate a real-world Cloud Provider scenario where infrastructure needs to be provisioned dynamically for multiple Clients (e.g., Nike, McDonald's, Airbnb) across multiple Environments (Dev, QA, Prod, Beta), ensuring total isolation and reproducibility.

Instead of manually writing hundreds of Kubernetes manifests, this project utilizes Terraform and Dynamic Templating to generate and orchestrate infrastructure programmatically.

## Architectural Decisions & Concepts

To achieve a professional grade of modularity and maintainability, the following concepts were implemented:

### 1. Dynamic Templating & Infrastructure as Code (IaC)

Rather than hardcoding Kubernetes YAML files for every service, the project uses a "Template Injection" strategy.

- **Templates:** Generic Kubernetes manifests (deployment.yaml, service.yaml, secret.yaml) serve as blueprints.
- **Variable Injection:** Terraform iterates through a defined list of clients and environments, injecting variables (Namespace, DB Credentials, Hostnames) into these templates at runtime.
- **Benefit:** Adding a new client (e.g., "Tesla") requires adding one line of code to the variable list, not creating 10 new files.

### 2. Multi-Cluster Simulation

The project orchestrates multiple Minikube Profiles simultaneously to simulate distinct physical clusters or regions. This ensures that a resource spike in one client does not affect the stability of another (Cluster Isolation).

<img width="863" height="416" alt="Screenshot 2026-02-07 173527" src="https://github.com/user-attachments/assets/97b33e72-7d99-474d-974e-9b88cc8e96d7" />

### 3. Namespace Isolation

Within each cluster, environments (Dev, QA, Prod) are separated by Kubernetes Namespaces. This provides:

- **Security:** Secrets and ConfigMaps are scoped locally.
- **Resource Management:** Prevents naming collisions between environments.

### 4. Automated Secret Management

Database credentials are handled securely. The Terraform logic ensures that sensitive data (like passwords) is Base64 encoded before being injected into Kubernetes Secrets, preventing plain-text exposure in the manifests.

## Getting Started

### Prerequisites

- Docker
- Minikube
- Terraform
- Kubectl
- Make

```bash
cd infra
```

### Installation & Deployment

The entire lifecycle of the project is managed via the Makefile to ensure consistency.

> **Note:** Run **make all** to build and setup all the infrastructure...clean, up, hosts, init, validate.

> **Note:** When this command finish if the tests gives you HTTP 500. Please run **make init** and after that run make **test**.

#### 1. Provision Infrastructure

This command starts the Minikube clusters, applies the Terraform plan, and configures the Ingress.

```bash
make up
```

#### 2. Initialize Applications

Runs a post-deployment script to initialize the Odoo databases (prevents HTTP 500 errors on first boot).

```bash
make init
```

#### 3. Automated Testing

Validates that all endpoints are responding correctly (HTTP 200/303).

```bash
make test
```

#### 4. Teardown

Destroys all clusters and cleans up resources.

```bash
make clean
```

## Networking & DNS

The Ingress Controller is configured to route traffic based on host headers.

- `https://odoo.dev.nike.local` → Nike Cluster / Dev Namespace
- `https://odoo.prod.airbnb.local` → Airbnb Cluster / Prod Namespace

> **Note:** Local DNS resolution is handled via `/etc/hosts` injection performed by Minikube ingress-dns.

## Conclusion


This project moves beyond simple containerization. It showcases a Platform Engineering approach, where the infrastructure is treated as a product—flexible, automated, and ready to scale for any number of clients with minimal operational overhead.
