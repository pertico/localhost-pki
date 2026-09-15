terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# =========================================================================
# 1. PASO: CA RAÍZ (ROOT CA)
# =========================================================================

# Generar la clave privada de la CA Raíz
resource "tls_private_key" "ca_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Crear el certificado de la CA Raíz (Autofirmado)
resource "tls_self_signed_cert" "ca_cert" {
  private_key_pem       = tls_private_key.ca_key.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = 8760 # 1 año

  subject {
    common_name         = "localhost Terraform Root CA"
    organization        = "Home"
    organizational_unit = "localhost"
  }

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature"
  ]
}

# =========================================================================
# 2. PASO: CA INTERMEDIA (INTERMEDIATE CA)
# =========================================================================

# Generar la clave privada para la CA Intermedia
resource "tls_private_key" "intermediate_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Crear la Solicitud de Firma de Certificado (CSR) para la Intermedia
resource "tls_cert_request" "intermediate_csr" {
  private_key_pem = tls_private_key.intermediate_key.private_key_pem

  subject {
    common_name         = "localhost Terraform Intermediate CA"
    organization        = "Home"
    organizational_unit = "localhost"
  }
}

# FIRMA LOCAL: La CA Raíz firma el CSR de la CA Intermedia
resource "tls_locally_signed_cert" "intermediate_cert" {
  cert_request_pem      = tls_cert_request.intermediate_csr.cert_request_pem
  ca_private_key_pem    = tls_private_key.ca_key.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca_cert.cert_pem
  is_ca_certificate     = true
  validity_period_hours = 4380 # 6 meses

  # Equivalente a max_path_len: 1 en CFSSL (puede firmar otra CA por debajo)
  max_path_length = 1

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature"
  ]
}

# =========================================================================
# 2b. PASO: CA INTERMEDIA PARA SMALLSTEP (SMALLSTEP INTERMEDIATE CA)
# =========================================================================

# Generar la clave privada para la CA Intermedia
resource "tls_private_key" "smallstep_intermediate_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Crear la Solicitud de Firma de Certificado (CSR) para la Intermedia
resource "tls_cert_request" "smallstep_intermediate_csr" {
  private_key_pem = tls_private_key.intermediate_key.private_key_pem

  subject {
    common_name         = "localhost Smallstep Terraform Intermediate CA"
    organization        = "Home"
    organizational_unit = "localhost"
  }
}

# FIRMA LOCAL: La CA Itermedia firma el CSR de la CA de Smallstep
resource "tls_locally_signed_cert" "smallstep_intermediate_cert" {
  cert_request_pem      = tls_cert_request.smallstep_intermediate_csr.cert_request_pem
  ca_private_key_pem    = tls_private_key.intermediate_key.private_key_pem
  ca_cert_pem           = tls_locally_signed_cert.intermediate_cert.cert_pem
  is_ca_certificate     = true
  validity_period_hours = 4380 # 6 meses

  # Equivalente a max_path_len: 1 en CFSSL (puede firmar otra CA por debajo)
  max_path_length = 1

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature"
  ]
}

resource "podman_volume" "step_data" {
  name = "step-data"
}

resource "terraform_data" "step_volume" {
  input = podman_volume.step_data.name

  provisioner "local-exec" {
    # Usamos podman cp para copiar los archivos locales dentro del volumen a través de un contenedor temporal
    command = <<EOT
      podman run --name helper -v ${podman_volume.step_data.name}:/data -d alpine tail -f /dev/null
      podman exec helper mkdir -p /data/certs /data/secrets
      podman cp ${path.module}/../step/certs/root-ca.crt helper:/data/certs/root-ca.crt
      podman cp ${path.module}/../step/certs/intermediate-ca.crt helper:/data/certs/intermediate-ca.crt
      podman cp ${path.module}/../step/certs/acme-intermediate-ca.crt helper:/data/certs/acme-intermediate-ca.crt
      podman cp ${path.module}/../step/secrets/acme-intermediate-ca.key helper:/data/secrets/root-ca.key
      podman rm -f helper
    EOT
  }
}




# =========================================================================
# 3. OUTPUTS: Guardar los archivos resultantes en el disco duro
# =========================================================================

resource "local_file" "save_ca_key" {
  content  = tls_private_key.ca_key.private_key_pem
  filename = "${path.root}/secrets/ca.key"
  file_permission = "0600"
}

resource "local_file" "save_root_cert" {
  content  = tls_self_signed_cert.ca_cert.cert_pem
  filename = "${path.root}/certs/ca.crt"
}

resource "local_file" "save_intermediate_key" {
  content  = tls_private_key.intermediate_key.private_key_pem
  filename = "${path.root}/secrets/intermediate.key"
  file_permission = "0600"
}

resource "local_file" "save_intermediate_cert" {
  content  = tls_locally_signed_cert.intermediate_cert.cert_pem
  filename = "${path.root}/certs/intermediate.crt"
}

resource "local_file" "save_smallstep_intermediate_key" {
  content  = tls_private_key.smallstep_intermediate_key.private_key_pem
  filename = "${path.root}/secrets/smallstep_intermediate.key"
  file_permission = "0600"
}

resource "local_file" "save_smallstep_intermediate_cert" {
  content  = tls_locally_signed_cert.smallstep_intermediate_cert.cert_pem
  filename = "${path.root}/certs/smallstep_intermediate.crt"
}