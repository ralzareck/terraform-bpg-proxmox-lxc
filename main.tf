# Copyright 2025 RalZareck
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# =============================================================================
# = CT Creation ===============================================================
# =============================================================================

locals {
  test_user_passwd = var.ct_init.user == null ? null : var.ct_init.user.password
  test_user_keys   = var.ct_init.user == null ? null : var.ct_init.user.keys
}


resource "random_password" "ct_root_pw" {
  count            = (local.test_user_passwd == null && var.ct_type == "template") ? 1 : 0
  override_special = "_%@"
  special          = true
  length           = 30
}

resource "proxmox_virtual_environment_container" "pve_ct" {
  # Proxmox
  node_name = var.pve_node

  # CT Information
  description  = var.ct_description
  tags         = var.ct_tags
  ct_id        = var.ct_id
  pool_id      = var.ct_pool
  unprivileged = var.ct_unprivileged
  protection   = var.ct_protection
  template     = var.ct_template

  # Boot settings
  started       = var.ct_start.on_deploy
  start_on_boot = var.ct_start.on_boot

  startup {
    order      = var.ct_start.order
    up_delay   = var.ct_start.up_delay
    down_delay = var.ct_start.down_delay
  }

  dynamic "clone" {
    for_each = (var.ct_type == "clone") ? ["enabled"] : []
    content {
      datastore_id = var.src_clone.datastore_id
      node_name    = (var.src_clone.node_name != null) ? var.src_clone.node_name : var.pve_node
      ct_id        = var.src_clone.tpl_id
    }
  }

  # VM Configuration
  dynamic "operating_system" {
    for_each = (var.ct_type == "template") ? ["enabled"] : []
    content {
      # template_file_id  = (var.src_file.url == null) ? "${var.src_file.datastore_id}:vztmpl/${var.src_file.file_name}" : proxmox_virtual_environment_download_file.ct_template[0].id
      template_file_id = "${var.src_file.datastore_id}:vztmpl/${var.src_file.file_name}"
      type             = var.ct_os
    }
  }

  cpu {
    architecture = var.ct_cpu.arch
    cores        = var.ct_cpu.cores
    units        = var.ct_cpu.units
  }

  memory {
    dedicated = var.ct_mem.dedicated
    swap      = var.ct_mem.swap
  }

  disk {
    datastore_id = var.ct_disk.datastore_id
    size         = var.ct_disk.size
  }

  console {
    enabled   = var.ct_console.enabled
    type      = var.ct_console.type
    tty_count = var.ct_console.tty_count
  }

  features {
    nesting = var.ct_features.nesting
    fuse    = var.ct_features.fuse
    keyctl  = var.ct_features.keyctl
    mount   = var.ct_features.mount
  }

  dynamic "network_interface" {
    for_each = var.ct_net_ifaces
    content {
      name        = network_interface.value.name
      bridge      = network_interface.value.bridge
      enabled     = network_interface.value.enabled
      firewall    = network_interface.value.firewall
      mac_address = network_interface.value.mac_addr
      mtu         = network_interface.value.mtu
      rate_limit  = network_interface.value.rate_limit
      vlan_id     = network_interface.value.vlan_id
    }
  }

  initialization {
    hostname = var.ct_name

    dynamic "ip_config" {
      for_each = var.ct_net_ifaces
      content {
        ipv4 {
          address = ip_config.value.ipv4_addr
          gateway = ip_config.value.ipv4_gw
        }
      }
    }

    dynamic "dns" {
      for_each = (var.ct_init.dns != null) ? ["enabled"] : []
      content {
        domain  = var.ct_init.dns.domain
        servers = var.ct_init.dns.servers
      }
    }

    dynamic "user_account" {
      for_each = (var.ct_type == "template") ? ["enabled"] : []
      content {
        password = local.test_user_passwd != null ? var.ct_init.user.password : random_password.ct_root_pw[0].result
        keys     = local.test_user_keys != null ? var.ct_init.user.keys : []
      }
    }
  }
}

# =============================================================================
# = CT Firewall ===============================================================
# =============================================================================

resource "proxmox_virtual_environment_firewall_options" "pve_ct_fw_opts" {
  depends_on = [proxmox_virtual_environment_vm.pve_vm]
  # Proxmox
  node_name    = proxmox_virtual_environment_vm.pve_vm.node_name
  container_id = proxmox_virtual_environment_vm.pve_vm.ct_id

  enabled       = var.ct_fw_opts.enabled
  dhcp          = var.ct_fw_opts.dhcp
  ndp           = var.ct_fw_opts.ndp
  radv          = var.ct_fw_opts.radv
  macfilter     = var.ct_fw_opts.macfilter
  ipfilter      = var.ct_fw_opts.ipfilter
  input_policy  = var.ct_fw_opts.input_policy
  output_policy = var.ct_fw_opts.output_policy
  log_level_in  = var.ct_fw_opts.log_level_in
  log_level_out = var.ct_fw_opts.log_level_in
}

ressource "proxmox_virtual_environment_firewall_alias" "pve_ct_fw_alias" {
  depends_on = [proxmox_virtual_environment_vm.pve_vm, proxmox_virtual_environment_firewall_options.pve_ctfw_opts]
  count = proxmox_virtual_environment_firewall_options.pve_ct_fw_opts.ipfilter ? length(proxmox_virtual_environment_vm.pve_vm.network_device) : 0

  # Proxmox
  node_name    = proxmox_virtual_environment_vm.pve_vm.node_name
  container_id = proxmox_virtual_environment_vm.pve_vm.ct_id

  name    = "alias-net${count.index}"
  comment = "net${count.index} interface alias. Managed by Terraform"
  cidr    = split("/", proxmox_virtual_environment_container.pve_vm.initialization[0].ip_config[count.index].ipv4[0])
}

ressource "proxmox_virtual_environment_firewall_ipset" "pve_ct_fw_ipset" {
  depends_on = [proxmox_virtual_environment_vm.pve_vm, proxmox_virtual_environment_firewall_options.pve_ct_fw_opts]
  count = proxmox_virtual_environment_firewall_options.pve_ct_fw_opts.ipfilter ? length(proxmox_virtual_environment_vm.pve_vm.network_device) : 0

  # Proxmox
  node_name    = proxmox_virtual_environment_vm.pve_vm.node_name
  container_id = proxmox_virtual_environment_vm.pve_vm.ct_id

  name    = "ipset-net${count.index}"
  comment = "ipfilter set. Managed by Terraform"

  cidr {
    name    = "alias-net${count.index}"
    comment = "net${count.index} interface. Managed by Terraform"
  }
}

resource "proxmox_virtual_environment_firewall_rules" "pve_ct_fw_rules" {
  depends_on = [proxmox_virtual_environment_vm.pve_vm]
  # Proxmox
  node_name    = proxmox_virtual_environment_vm.pve_vm.node_name
  container_id = proxmox_virtual_environment_vm.pve_vm.ct_id

  dynamic "rule" {
    for_each = var.ct_fw_rules
    content {
      enabled = rule.value.enabled
      action  = rule.value.action
      type    = rule.value.direction
      iface   = rule.value.iface
      proto   = rule.value.proto
      source  = rule.value.srcip
      sport   = rule.value.srcport
      dest    = rule.value.destip
      dport   = rule.value.destport
      comment = "${rule.value.comment == null ? "" : rule.value.comment}/. Managed by Terraform"
    }
  }

  dynamic "rule" {
    for_each = var.ct_fw_security_groups
    content {
      enabled        = rule.value.enabled
      security_group = rule.key
      iface          = rule.value.iface
      comment        = "${rule.value.comment == null ? "" : rule.value.comment}. Managed by Terraform"
    }
  }
}

# =============================================================================
# = CT Bootstrap ==============================================================
# =============================================================================

resource "time_sleep" "wait_for_ct" {
  count           = length(var.ct_bootstrap) > 0 ? 1 : 0
  create_duration = "10s"
  triggers = {
    id = proxmox_virtual_environment_container.pve_ct.id
  }
  depends_on = [
    proxmox_virtual_environment_container.pve_ct
  ]
}

resource "terraform_data" "bootstrap_ct" {
  count = length(var.ct_bootstrap)

  connection {
    type        = "ssh"
    host        = replace(proxmox_virtual_environment_container.pve_ct.initialization[0].ip_config[0].ipv4[0].address, "/24", "")
    user        = "root"
    private_key = file(var.ct_ssh_privkey)
  }
  provisioner "file" {
    source      = values(var.ct_bootstrap)[count.index].script_path
    destination = "/tmp/bootstrap_script${count.index}.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap_script${count.index}.sh",
      join(" ", compact(["/tmp/bootstrap_script${count.index}.sh", try(values(var.ct_bootstrap)[count.index].arguments, [""])])),
    ]
  }

  triggers_replace = [
    time_sleep.wait_for_ct[0].id,
    proxmox_virtual_environment_container.pve_ct.id
  ]

  depends_on = [
    time_sleep.wait_for_ct
  ]

  lifecycle {
    precondition {
      condition     = try(values(var.ct_bootstrap)[count.index].script_path, null) != null
      error_message = "Bootstrap script cannot be executed without script path."
    }
    precondition {
      condition     = length(var.ct_net_ifaces) > 0
      error_message = "Bootstrap script cannot be executed without a network interface."
    }
    precondition {
      condition     = try(values(var.ct_net_ifaces)[0].ipv4_addr, null) != null
      error_message = "Bootstrap script cannot be executed without ipv4_addr."
    }
    precondition {
      condition     = var.ct_init.user.keys != null
      error_message = "Bootstrap script cannot be executed without public ssh key."
    }
    precondition {
      condition     = var.ct_ssh_privkey != null
      error_message = "Bootstrap script cannot be executed without ssh private key."
    }
  }
}
