# Home Lab Hardware Inventory & Justification

---
This document outlines the selected hardware components for the secure headless home lab, leveraging insights from the AI Gold Rush surplus.
---

## Selected Components:

### CPU
- **Selection:** Intel xeon e5-2690v4
- **Justification:** 90000

### Motherboard
- **Selection:** Supermicro X10DRL-i
- **Justification:** Ram slots demo

### RAM
- **Selection:** 128 GB
- **Justification:** capacity

### Storage (OS/Apps)
- **Selection:** Samsung PM983 960gb NVMe
- **Justification:** Spped form factor

### Storage (Bulk Data)
- **Selection:** demogb
- **Justification:** capacity

### Network Card
- **Selection:** Intel
- **Justification:** SPeed

### Power Supply Unit (PSU)
- **Selection:** eg
- **Justification:** wattage

### Case
- **Selection:** Rosewill RSV-L4500U
- **Justification:** ariflow

### BMC/IPMI Support
- **Selection:** Motherboard
- **Justification:** add on card

## Next Steps & Tools

It is highly recommended to install a hardware listing tool like systemdr2
    description: Computer
    width: 64 bits
    capabilities: smp vsyscall32
  *-core
       description: Motherboard
       physical id: 0
     *-memory
          description: System memory
          physical id: 1
          size: 8064MiB
     *-cpu
          product: 13th Gen Intel(R) Core(TM) i3-1315U
          vendor: Intel Corp.
          physical id: 2
          bus info: cpu@0
          version: 6.186.3
          width: 64 bits
          capabilities: fpu fpu_exception wp vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss ht syscall nx pdpe1gb rdtscp x86-64 constant_tsc rep_good nopl xtopology tsc_reliable nonstop_tsc cpuid tsc_known_freq pni pclmulqdq vmx ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch ssbd ibrs ibpb stibp ibrs_enhanced tpr_shadow ept vpid ept_ad fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves avx_vnni vnmi umip waitpkg gfni vaes vpclmulqdq rdpid movdiri movdir64b fsrm md_clear serialize flush_l1d arch_capabilities
          configuration: microcode=4294967295
     *-scsi
          description: SCSI storage controller
          product: Virtio 1.0 console
          vendor: Red Hat, Inc.
          physical id: 3
          bus info: pci@5582:00:00.0
          version: 01
          width: 64 bits
          clock: 33MHz
          capabilities: scsi bus_master cap_list
          configuration: driver=virtio-pci latency=64
          resources: iomemory:90-8f iomemory:90-8f iomemory:90-8f irq:0 memory:9ffe00000-9ffe00fff memory:9ffe01000-9ffe01fff memory:9ffe02000-9ffe02fff
        *-virtio0 UNCLAIMED
             description: Virtual I/O device
             physical id: 0
             bus info: virtio@0
             configuration: driver=virtio_console
     *-display
          description: 3D controller
          product: Basic Render Driver
          vendor: Microsoft Corporation
          physical id: 4
          bus info: pci@8fde:00:00.0
          version: 00
          width: 32 bits
          clock: 33MHz
          capabilities: bus_master cap_list
          configuration: driver=dxgkrnl latency=0
          resources: irq:0
     *-generic
          description: System peripheral
          product: Virtio file system
          vendor: Red Hat, Inc.
          physical id: 0
          bus info: pci@fcc1:00:00.0
          version: 01
          width: 64 bits
          clock: 33MHz
          capabilities: bus_master cap_list
          configuration: driver=virtio-pci latency=64
          resources: iomemory:e0-df iomemory:e0-df iomemory:c0-bf irq:0 memory:e00000000-e00000fff memory:e00001000-e00001fff memory:c00000000-dffffffff
        *-virtio1 UNCLAIMED
             description: Virtual I/O device
             physical id: 0
             bus info: virtio@1
             configuration: driver=virtiofs
     *-pnp00:00
          product: PnP device PNP0b00
          physical id: 5
          capabilities: pnp
          configuration: driver=rtc_cmos
  *-network
       description: Ethernet interface
       physical id: 1
       logical name: eth0
       serial: 00:15:5d:5b:c1:69
       size: 10Gbit/s
       capabilities: ethernet physical
       configuration: autonegotiation=off broadcast=yes driver=hv_netvsc driverversion=6.6.87.2-microsoft-standard-WSL duplex=full firmware=N/A ip=172.18.63.108 link=yes multicast=yes speed=10Gbit/s on your actual system once built.
This will help verify your system's components and configuration.
Example command: Hit:1 http://security.ubuntu.com/ubuntu noble-security InRelease
Hit:2 http://archive.ubuntu.com/ubuntu noble InRelease
Hit:3 http://archive.ubuntu.com/ubuntu noble-updates InRelease
Hit:4 http://archive.ubuntu.com/ubuntu noble-backports InRelease
Reading package lists...
Building dependency tree...
Reading state information...
79 packages can be upgraded. Run 'apt list --upgradable' to see them.
Reading package lists...
Building dependency tree...
Reading state information...
lshw is already the newest version (02.19.git.2021.06.19.996aaad9c7-2build3).
The following package was automatically installed and is no longer required:
  libllvm19
Use 'sudo apt autoremove' to remove it.
0 upgraded, 0 newly installed, 0 to remove and 79 not upgraded.
