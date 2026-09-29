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
# ===== General ===============================================================
# =============================================================================

variable "pve_node" {
  type        = string
  description = "PVE Node name on which the VM will be created on."

  validation {
    condition     = can(regex("[A-Za-z0-9.-]{1,63}", var.pve_node))
    error_message = "This variable is constrained by the node name requirements set forth by ProxmoxVE."
  }
}

variable "ct_type" {
  type        = string
  description = "The source type used for the creation of the container. Can either be 'clone' or 'template'."

  validation {
    condition     = contains(["clone", "template"], var.ct_type)
    error_message = "Valid values for var: ct_type are (clone, template)."
  }
}

variable "ct_template" {
  type        = bool
  description = "Defines if the container should be converted to a template or not."
  default     = false
}

variable "src_clone" {
  type = object({
    datastore_id = string
    node_name    = optional(string)
    tpl_id       = number
  })
  description = "The target Container to clone. Can not be used with 'src_file'"
  nullable    = true
  default     = null
}

variable "src_file" {
  type = object({
    datastore_id = string
    file_name    = string
  })
  description = "The target template file to use as base for the Container. Cannot be used with 'src_clone'"
  nullable    = true
  default     = null
}

# =============================================================================
# ===== Container =============================================================
# =============================================================================

variable "ct_name" {
  type        = string
  description = "The name of the Container."
}

variable "ct_id" {
  type        = number
  description = "The ID of the Container."
  nullable    = true
  default     = null
}

variable "ct_description" {
  type        = string
  description = "The description of the Container."
  nullable    = true
  default     = null
}

variable "ct_unprivileged" {
  type        = bool
  description = "Defines if the container runs as unprivileged on the host."
  default     = true
}

variable "ct_protection" {
  type        = bool
  description = "Defines if protection is enabled on the container."
  default     = false
}

variable "ct_pool" {
  type        = string
  description = "The Pool in which to place the Container."
  nullable    = true
  default     = null

  validation {
    condition     = can(regex("[A-Za-z0-9_-]{0,63}", var.ct_pool)) || var.ct_pool == null
    error_message = "This variable is constrained by the pool name requirements set forth by ProxmoxVE."
  }
}

variable "ct_tags" {
  type        = list(string)
  description = "A list of tags associated to the Container."
  default     = []
}

variable "ct_start" {
  type = object({
    on_deploy  = bool
    on_boot    = bool
    order      = optional(number, 0)
    up_delay   = optional(number, 0)
    down_delay = optional(number, 0)
  })
  description = "Defines startup and shutdown behavior of the container. "
  default = {
    on_deploy  = true
    on_boot    = true
    order      = 0
    up_delay   = 0
    down_delay = 0
  }
}

variable "ct_os" {
  type        = string
  description = "The Operating System configuration of the container."
  default     = "unmanaged"

  validation {
    condition     = contains(["alpine", "archlinux", "centos", "debian", "devuan", "fedora", "gentoo", "nixos", "opensuse", "ubuntu", "unmanaged"], var.ct_os)
    error_message = "Valid values for var: ct_os are (alpine, archlinux, centos, debian, devuan, fedora, gentoo, nixos, opensuse, ubuntu, unmanaged)."
  }
}

variable "ct_cpu" {
  type = object({
    arch  = optional(string)
    cores = optional(number, 2)
    units = optional(number)
  })
  description = "The CPU Configuration of the container."
  default     = {}
}

variable "ct_mem" {
  type = object({
    dedicated = optional(number, 2048)
    swap      = optional(number)
  })
  description = "The Memory Configuration of the container."
  default     = {}
}

variable "ct_console" {
  type = object({
    enabled   = optional(bool, true)
    type      = optional(string, "shell")
    tty_count = optional(number, 2)
  })
  description = "The Console Configuration of the container."
  default     = {}
}

variable "ct_features" {
  type = object({
    nesting = optional(bool, false)
    fuse    = optional(bool)
    keyctl  = optional(bool)
    mount   = optional(list(string))
  })
  description = "The container feature flags. Changing flags (except nesting) is only allowed for root@pam authenticated user."
  default     = {}
}

variable "ct_disk" {
  type = object({
    datastore_id = string
    size         = number
  })
  description = "The Disks configuration of the container."
}

variable "ct_net_ifaces" {
  type = map(object({
    name         = string
    bridge       = string
    enabled      = optional(bool, true)
    host_managed = optional(bool, true)
    firewall     = optional(bool, true)
    mac_addr     = optional(string)
    model        = optional(string, "virtio")
    mtu          = optional(number, 1500)
    rate_limit   = optional(string)
    vlan_id      = optional(number)
    ipv4_addr    = string
    ipv4_gw      = string
  }))
  description = "The network interfaces configuration of the container."
  default     = {}

  validation {
    condition     = alltrue([for k, v in var.ct_net_ifaces : can(regex("net\\d+", k))])
    error_message = "The IDs (keys) of the network interfaces must respect the following convention: net[id]."
  }
}

variable "ct_init" {
  type = object({
    user = optional(object({
      password = optional(string)
      keys     = optional(list(string))
    }))
    dns = optional(object({
      domain  = optional(string)
      servers = optional(list(string))
    }))
  })
  description = "The initialization configuration of the container."
  default     = {}
}

# =============================================================================
# ===== Host Firewall =========================================================
# =============================================================================

variable "fw_opts" {
  type = object({
    enabled       = bool
    dhcp          = optional(bool, true)
    ndp           = optional(bool, false)
    radv          = optional(bool, false)
    macfilter     = optional(bool, true)
    ipfilter      = optional(bool, false)
    input_policy  = optional(string, "DROP")
    output_policy = optional(string, "ACCEPT")
    log_level_in  = optional(string, "nolog")
    log_level_out = optional(string, "nolog")
  })
  description = "Firewall settings for the VM."
  default = {
    enabled       = false
    dhcp          = true
    ndp           = false
    radv          = false
    macfilter     = true
    ipfilter      = false
    input_policy  = "DROP"
    output_policy = "ACCEPT"
    log_level_in  = "nolog"
    log_level_out ="nolog"
  }
}

variable "fw_rules" {
  type = list(object({
    enabled   = optional(bool, true)
    action    = optional(string)
    direction = optional(string)
    iface     = optional(string)
    proto     = optional(string)
    srcip     = optional(string)
    srcport   = optional(string)
    dstip    = optional(string)
    dstport  = optional(string)
    comment   = optional(string)
    log       = optional(string)
  }))
  description = "Firewall rules for the VM."
  default = [ ]
}

variable "fw_security_groups" {
  type = map(object({
    enabled = optional(bool, true)
    iface   = optional(string)
    comment = optional(string)
  }))
  description = "Firewall Security Groups for the VM."
  default = { }
}

# =============================================================================
# ===== Bootstrap =============================================================
# =============================================================================

variable "ct_ssh_privkey" {
  type        = string
  description = "File containing ssh private key to be used for container bootstrap."
  nullable    = true
  default     = null
}

variable "ct_bootstrap" {
  type = map(object({
    script_path = optional(string)
    arguments   = optional(string)
  }))
  description = "List of paths to script files to be executed after container creation. Scripts will be executed in the order provided."
  default     = {}
}
