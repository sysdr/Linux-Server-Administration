#!/bin/bash
set -euo pipefail

LAB_DIR="home_lab_planning"
INVENTORY_FILE="$LAB_DIR/hardware_inventory.md"
LSHW_INSTALL_FILE="$LAB_DIR/lshw_install_status.txt"

echo "=========================================================="
echo "  Home Lab Hardware Selection Assistant (AI Gold Rush Edition)"
echo "=========================================================="
echo ""

# Create project directory
echo "Creating project directory: $LAB_DIR"
mkdir -p "$LAB_DIR"

echo "Initializing hardware inventory file: $INVENTORY_FILE"
cat > "$INVENTORY_FILE" <<- EOF
# Home Lab Hardware Inventory & Justification

---
This document outlines the selected hardware components for the secure headless home lab, leveraging insights from the AI Gold Rush surplus.
---

## Selected Components:

EOF

# Function to get user input for a component (use defaults when non-interactive)
get_component_input() {
    local component_name="$1"
    local default_value="$2"
    local justification_prompt="$3"
    local default_justification="${4:-Selected for home lab compatibility and value.}"

    local component_choice="$default_value"
    local component_justification="$default_justification"
    if [ -t 0 ]; then
        echo ""
        read -rp "Enter your chosen ${component_name} (e.g., ${default_value}): " component_choice
        component_choice="${component_choice:-$default_value}"
        read -rp "Justify your ${component_name} choice: ${justification_prompt} " component_justification
        component_justification="${component_justification:-$default_justification}"
    fi

    echo "### ${component_name}" >> "$INVENTORY_FILE"
    echo "- **Selection:** ${component_choice}" >> "$INVENTORY_FILE"
    echo "- **Justification:** ${component_justification}" >> "$INVENTORY_FILE"
    echo "" >> "$INVENTORY_FILE"
}

# Collect hardware choices
echo "Please provide your preliminary hardware selections and justifications."

get_component_input "CPU" "Intel Xeon E5-2690v4" "Why this CPU? (e.g., core count, price, virtualization features)"
get_component_input "Motherboard" "Supermicro X10DRL-i" "Why this Motherboard? (e.g., IPMI, RAM slots, PCIe lanes)"
get_component_input "RAM" "64GB (4x16GB) ECC DDR4 2133MHz" "Why this RAM? (e.g., ECC for reliability, capacity)"
get_component_input "Storage (OS/Apps)" "Samsung PM983 960GB NVMe U.2 SSD" "Why this storage? (e.g., speed, enterprise-grade, form factor)"
get_component_input "Storage (Bulk Data)" "Western Digital Red Pro 8TB HDD" "Why this storage? (e.g., capacity, 24/7 reliability, RAID potential)"
get_component_input "Network Card" "Intel X540-T2 10GbE NIC" "Why this NIC? (e.g., speed, dual ports, driver support)"
get_component_input "Power Supply Unit (PSU)" "Seasonic FOCUS Plus 850W Platinum" "Why this PSU? (e.g., efficiency rating, wattage)"
get_component_input "Case" "Rosewill RSV-L4500U 4U Rackmount" "Why this Case? (e.g., drive bays, airflow, form factor)"
get_component_input "BMC/IPMI Support" "Integrated ASPEED AST2400 via Motherboard" "How will you manage this headless? (e.g., integrated, add-on card)"

echo "## Next Steps & Tools" >> "$INVENTORY_FILE"
echo "" >> "$INVENTORY_FILE"
echo "It is highly recommended to install a hardware listing tool like `lshw` on your actual system once built." >> "$INVENTORY_FILE"
echo "This will help verify your system's components and configuration." >> "$INVENTORY_FILE"
echo "Example command: `sudo apt update && sudo apt install -y lshw`" >> "$INVENTORY_FILE"

# Attempt to install lshw for local runs, or note it for Docker (non-fatal if sudo unavailable)
# Optional: set SUDO_PASSWORD only when running (never commit). Enables lshw install when sudo needs a password.
echo ""
echo "Attempting to install 'lshw' (useful for verifying hardware later)..."
run_sudo() {
    if [ -n "${SUDO_PASSWORD:-}" ]; then
        echo "$SUDO_PASSWORD" | sudo -S "$@" 2>/dev/null
    else
        sudo -n "$@" 2>/dev/null
    fi
}
if command -v apt &> /dev/null; then
    if run_sudo apt update -qq && run_sudo apt install -y lshw; then
        echo "lshw installation: SUCCESS" > "$LSHW_INSTALL_FILE"
    else
        echo "lshw installation: SKIPPED (sudo unavailable or install failed). Install manually: sudo apt install -y lshw" > "$LSHW_INSTALL_FILE"
    fi
elif command -v yum &> /dev/null; then
    if run_sudo yum install -y lshw; then
        echo "lshw installation: SUCCESS" > "$LSHW_INSTALL_FILE"
    else
        echo "lshw installation: SKIPPED (sudo unavailable or install failed). Install manually when setting up your lab." > "$LSHW_INSTALL_FILE"
    fi
else
    echo "lshw installation: SKIPPED (package manager not found or not supported for auto-install in this environment)." > "$LSHW_INSTALL_FILE"
    echo "Please install 'lshw' manually for your distribution when setting up your lab."
fi

echo ""
echo "=========================================================="
echo "  Hardware Inventory Complete!"
echo "=========================================================="
echo "Your hardware selections have been recorded in: $INVENTORY_FILE"
echo "You can review and edit this file as your plans evolve."
echo ""
echo "To view the content, run: cat $INVENTORY_FILE"
echo ""

# For Docker, print the content to stdout so it's easily visible
if [ -n "${DOCKER_CONTAINER_ID:-}" ] || [ -f "/.dockerenv" ]; then
    echo "--- Content of $INVENTORY_FILE (inside container) ---"
    cat "$INVENTORY_FILE"
    echo "-----------------------------------------------------"
    echo "To retrieve this file from the container, use 'docker cp <container_id>:$INVENTORY_FILE .'"
fi