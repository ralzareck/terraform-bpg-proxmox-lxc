<!-- markdownlint-disable MD033 -->
# terraform-bpg-proxmox-lxc

Based on [bpg's provider](https://github.com/bpg/terraform-provider-proxmox)

## Create a LXC CT on ProxmoxVE using Terraform

This module deploys a LXC Container on ProxmoxVE host, with firewall configuration.
It can be based on an already deployed CT template, or an existing LXC template.

![GitHub License](https://img.shields.io/github/license/ralzareck/terraform-module-bgp-pve-ct?style=flat&color=blue)

## Providers

Here is the list of required providers:

| Name                                                                         | Version   |
| ---------------------------------------------------------------------------- | --------- |
| [bgp/proxmox](https://registry.terraform.io/providers/bpg/proxmox)           | >= 0.66.0 |
| [hashicorp/random](https://registry.terraform.io/providers/hashicorp/random) | ~> 3.0.0  |
| [hashicorp/time](https://registry.terraform.io/providers/hashicorp/time)     | ~> 0.0    |

<!-- BEGIN_TF_DOCS -->
## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [proxmox_virtual_environment_container.pve_ct](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_container) | resource |
| [proxmox_virtual_environment_firewall_alias.pve_fw_alias](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_firewall_alias) | resource |
| [proxmox_virtual_environment_firewall_ipset.pve_fw_ipset](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_firewall_ipset) | resource |
| [proxmox_virtual_environment_firewall_options.pve_fw_opts](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_firewall_options) | resource |
| [proxmox_virtual_environment_firewall_rules.pve_fw_rules](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_firewall_rules) | resource |
| [random_password.ct_root_pw](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [terraform_data.bootstrap_ct](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [time_sleep.wait_for_ct](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |

## Inputs

Here are the input variables of the module:

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_pve_node"></a> [pve\_node](#input\_pve\_node) | PVE Node name on which the VM will be created on. | `string` | `n/a` | **yes** |
| <a name="input_ct_type"></a> [ct\_type](#input\_ct\_type) | The source type used for the creation of the container. Can either be 'clone' or 'template'. | `string` | `n/a` | **yes** |
| <a name="input_ct_template"></a> [ct\_template](#input\_ct\_template) | Defines if the container should be converted to a template or not. | `bool` | `false` | **no** |
| <a name="input_src_clone"></a> [src\_clone](#input\_src\_clone) | The target Container to clone. Can not be used with 'src\_file' | <pre>object({<br/>    datastore\_id = string<br/>    node\_name    = optional(string)<br/>    tpl\_id       = number<br/>  })</pre> | `null` | **no** |
| <a name="input_src_file"></a> [src\_file](#input\_src\_file) | The target template file to use as base for the Container. Cannot be used with 'src\_clone' | <pre>object({<br/>    datastore\_id = string<br/>    file\_name    = string<br/>  })</pre> | `null` | **no** |
| <a name="input_ct_name"></a> [ct\_name](#input\_ct\_name) | The name of the Container. | `string` | `n/a` | **yes** |
| <a name="input_ct_id"></a> [ct\_id](#input\_ct\_id) | The ID of the Container. | `number` | `null` | **no** |
| <a name="input_ct_description"></a> [ct\_description](#input\_ct\_description) | The description of the Container. | `string` | `null` | **no** |
| <a name="input_ct_unprivileged"></a> [ct\_unprivileged](#input\_ct\_unprivileged) | Defines if the container runs as unprivileged on the host. | `bool` | `true` | **no** |
| <a name="input_ct_protection"></a> [ct\_protection](#input\_ct\_protection) | Defines if protection is enabled on the container. | `bool` | `false` | **no** |
| <a name="input_ct_pool"></a> [ct\_pool](#input\_ct\_pool) | The Pool in which to place the Container. | `string` | `null` | **no** |
| <a name="input_ct_tags"></a> [ct\_tags](#input\_ct\_tags) | A list of tags associated to the Container. | `list(string)` | `[]` | **no** |
| <a name="input_ct_start"></a> [ct\_start](#input\_ct\_start) | Defines startup and shutdown behavior of the container. | <pre>object({<br/>    on\_deploy  = bool<br/>    on\_boot    = bool<br/>    order      = optional(number, 0)<br/>    up\_delay   = optional(number, 0)<br/>    down\_delay = optional(number, 0)<br/>  })</pre> | <pre>{<br/>  "down\_delay": 0,<br/>  "on\_boot": true,<br/>  "on\_deploy": true,<br/>  "order": 0,<br/>  "up\_delay": 0<br/>}</pre> | **no** |
| <a name="input_ct_os"></a> [ct\_os](#input\_ct\_os) | The Operating System configuration of the container. | `string` | `"unmanaged"` | **no** |
| <a name="input_ct_cpu"></a> [ct\_cpu](#input\_ct\_cpu) | The CPU Configuration of the container. | <pre>object({<br/>    arch  = optional(string)<br/>    cores = optional(number, 2)<br/>    units = optional(number)<br/>  })</pre> | `{}` | **no** |
| <a name="input_ct_mem"></a> [ct\_mem](#input\_ct\_mem) | The Memory Configuration of the container. | <pre>object({<br/>    dedicated = optional(number, 2048)<br/>    swap      = optional(number)<br/>  })</pre> | `{}` | **no** |
| <a name="input_ct_console"></a> [ct\_console](#input\_ct\_console) | The Console Configuration of the container. | <pre>object({<br/>    enabled   = optional(bool, true)<br/>    type      = optional(string, "shell")<br/>    tty\_count = optional(number, 2)<br/>  })</pre> | `{}` | **no** |
| <a name="input_ct_features"></a> [ct\_features](#input\_ct\_features) | The container feature flags. Changing flags (except nesting) is only allowed for root@pam authenticated user. | <pre>object({<br/>    nesting = optional(bool, false)<br/>    fuse    = optional(bool)<br/>    keyctl  = optional(bool)<br/>    mount   = optional(list(string))<br/>  })</pre> | `{}` | **no** |
| <a name="input_ct_disk"></a> [ct\_disk](#input\_ct\_disk) | The Disks configuration of the container. | <pre>object({<br/>    datastore\_id = string<br/>    size         = number<br/>  })</pre> | `n/a` | **yes** |
| <a name="input_ct_net_ifaces"></a> [ct\_net\_ifaces](#input\_ct\_net\_ifaces) | The network interfaces configuration of the container. | <pre>map(object({<br/>    name         = string<br/>    bridge       = string<br/>    enabled      = optional(bool, true)<br/>    host\_managed = optional(bool, true)<br/>    firewall     = optional(bool, true)<br/>    mac\_addr     = optional(string)<br/>    model        = optional(string, "virtio")<br/>    mtu          = optional(number, 1500)<br/>    rate\_limit   = optional(string)<br/>    vlan\_id      = optional(number)<br/>    ipv4\_addr    = string<br/>    ipv4\_gw      = string<br/>  }))</pre> | `{}` | **no** |
| <a name="input_ct_init"></a> [ct\_init](#input\_ct\_init) | The initialization configuration of the container. | <pre>object({<br/>    user = optional(object({<br/>      password = optional(string)<br/>      keys     = optional(list(string))<br/>    }))<br/>    dns = optional(object({<br/>      domain  = optional(string)<br/>      servers = optional(list(string))<br/>    }))<br/>  })</pre> | `{}` | **no** |
| <a name="input_fw_opts"></a> [fw\_opts](#input\_fw\_opts) | Firewall settings for the VM. | <pre>object({<br/>    enabled       = bool<br/>    dhcp          = optional(bool, true)<br/>    ndp           = optional(bool, false)<br/>    radv          = optional(bool, false)<br/>    macfilter     = optional(bool, true)<br/>    ipfilter      = optional(bool, false)<br/>    input\_policy  = optional(string, "DROP")<br/>    output\_policy = optional(string, "ACCEPT")<br/>    log\_level\_in  = optional(string, "nolog")<br/>    log\_level\_out = optional(string, "nolog")<br/>  })</pre> | <pre>{<br/>  "dhcp": true,<br/>  "enabled": false,<br/>  "input\_policy": "DROP",<br/>  "ipfilter": false,<br/>  "log\_level\_in": "nolog",<br/>  "log\_level\_out": "nolog",<br/>  "macfilter": true,<br/>  "ndp": false,<br/>  "output\_policy": "ACCEPT",<br/>  "radv": false<br/>}</pre> | **no** |
| <a name="input_fw_rules"></a> [fw\_rules](#input\_fw\_rules) | Firewall rules for the VM. | <pre>list(object({<br/>    enabled   = optional(bool, true)<br/>    action    = optional(string)<br/>    direction = optional(string)<br/>    iface     = optional(string)<br/>    proto     = optional(string)<br/>    srcip     = optional(string)<br/>    srcport   = optional(string)<br/>    dstip     = optional(string)<br/>    dstport   = optional(string)<br/>    comment   = optional(string)<br/>    log       = optional(string)<br/>  }))</pre> | `[]` | **no** |
| <a name="input_fw_security_groups"></a> [fw\_security\_groups](#input\_fw\_security\_groups) | Firewall Security Groups for the VM. | <pre>map(object({<br/>    enabled = optional(bool, true)<br/>    iface   = optional(string)<br/>    comment = optional(string)<br/>  }))</pre> | `{}` | **no** |
| <a name="input_ct_ssh_privkey"></a> [ct\_ssh\_privkey](#input\_ct\_ssh\_privkey) | File containing ssh private key to be used for container bootstrap. | `string` | `null` | **no** |
| <a name="input_ct_bootstrap"></a> [ct\_bootstrap](#input\_ct\_bootstrap) | List of paths to script files to be executed after container creation. Scripts will be executed in the order provided. | <pre>map(object({<br/>    script\_path = optional(string)<br/>    arguments   = optional(string)<br/>  }))</pre> | `{}` | **no** |

## Outputs

Here are the outputs of the module:

| Name | Description |
|------|-------------|
| <a name="output_pve_node"></a> [pve\_node](#output\_pve\_node) | Name of the Proxmox Node. |
| <a name="output_pve_id"></a> [pve\_id](#output\_pve\_id) | Proxmox ID of the instance. |
| <a name="output_pve_pool"></a> [pve\_pool](#output\_pve\_pool) | Proxmox Pool of the instance. |
| <a name="output_pve_type"></a> [pve\_type](#output\_pve\_type) | Proxmox type of virtualization. |
| <a name="output_name"></a> [name](#output\_name) | Name of the instance. |
| <a name="output_cpu"></a> [cpu](#output\_cpu) | Number of CPU of the instance. |
| <a name="output_mem"></a> [mem](#output\_mem) | Memory size of the instance (in MB). |
| <a name="output_disk"></a> [disk](#output\_disk) | Disk information of the instance. Contains `datastore_id` and `size` of the disk. |
| <a name="output_iface"></a> [iface](#output\_iface) | List of iface of the instance (excluding the `lo` iface). |
| <a name="output_mac_addresses"></a> [mac\_addresses](#output\_mac\_addresses) | Couple iface => List of MAC addresses of the instance. |
| <a name="output_ipv4_addresses"></a> [ipv4\_addresses](#output\_ipv4\_addresses) | Couple iface => List of IPv4 of the instance |
| <a name="output_ipv6_addresses"></a> [ipv6\_addresses](#output\_ipv6\_addresses) | Couple iface => List of IPv6 addresses of the instance. |
<!-- END_TF_DOCS -->
