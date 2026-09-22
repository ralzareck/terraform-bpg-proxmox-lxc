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
# ===== Outputs ===============================================================
# =============================================================================

output "pve_node" {
  description = "Name of the Proxmox Node."
  value       = resource.proxmox_virtual_environment_container.pve_ct.node_name
}

output "pve_id" {
  description = "Proxmox ID of the instance."
  value       = resource.proxmox_virtual_environment_container.pve_ct.vm_id
}

output "pve_pool" {
  description = "Proxmox Pool of the instance."
  value       = resource.proxmox_virtual_environment_container.pve_ct.pool_id
}

output "pve_type" {
  description = "Proxmox type of virtualization."
  value       = "lxc"
}

output "name" {
  description = "Name of the instance."
  value       = resource.proxmox_virtual_environment_container.pve_ct.initialization[0].hostname
}

output "cpu" {
  description = "Number of CPU of the instance."
  value       = resource.proxmox_virtual_environment_container.pve_ct.cpu[0].cores
}

output "mem" {
  description = "Memory size of the instance (in MB)."
  value       = resource.proxmox_virtual_environment_container.pve_ct.memory[0].dedicated
}

output "disk" {
  description = "Disk information of the instance. Contains `datastore_id` and `size` of the disk."
  value = [
    for disk in proxmox_virtual_environment_container.pve_ct.disk :
    {
      datastore_id = disk.datastore_id
      size         = disk.size
    }
  ]
}

output "iface" {
  description = "List of iface of the instance (excluding the `lo` iface)."
  value = [
    for iface in proxmox_virtual_environment_container.pve_ct.network_interface :
    iface.name
  ]
}

output "ip" {
  description = "Couple iface => List of IP of the instance."
  value = {
    for idx in range(length(proxmox_virtual_environment_container.pve_ct.network_interface)) :
    proxmox_virtual_environment_container.pve_ct.network_interface[idx].name => [
      for ip in proxmox_virtual_environment_container.pve_ct.initialization[0].ip_config[idx].ipv4 :
      split("/", ip.address)[0]
    ]
  }
}

output "ipv6_addresses" {
  description = "Couple iface => List of IPv6 addresses of the instance."
  value = {
    for idx in range(length(proxmox_virtual_environment_container.pve_ct.network_interface)) :
    proxmox_virtual_environment_container.pve_ct.network_interface[idx].name => [
      for ip in proxmox_virtual_environment_container.pve_ct.initialization[0].ip_config[idx].ipv6 :
      split("/", ip.address)[0]
    ]
  }
}
