#!/bin/bash
set -e

# --- Configuration (use absolute paths so script works from any cwd) ---
DAY3_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_USER="labuser"
SSH_PORT="22"
CONFIG_DIR="$DAY3_ROOT/config"
LOG_DIR="$DAY3_ROOT/logs"
SCRIPTS_DIR="$DAY3_ROOT/scripts"
SSH_KEY_DIR="$CONFIG_DIR/ssh_keys"
SSH_CONFIG_BACKUP="/etc/ssh/sshd_config.bak_$(date +%Y%m%d%H%M%S)"

# --- UI/Console Dashboard Functions ---
print_header() {
    echo -e "\n\e[1;34m=================================================================\e[0m"
    echo -e "\e[1;34m  🚀 Secure Headless Home Lab: Digital Sovereignty Setup        \e[0m"
    echo -e "\e[1;34m=================================================================\e[0m"
}

print_section() {
    echo -e "\n\e[1;33m--- $1 ---\e[0m"
}

print_success() {
    echo -e "\e[1;32m✅ SUCCESS: $1\e[0m"
}

print_info() {
    echo -e "\e[0;36mℹ️ INFO: $1\e[0m"
}

print_warning() {
    echo -e "\e[1;31m⚠️ WARNING: $1\e[0m"
}

print_error() {
    echo -e "\e[1;31m❌ ERROR: $1\e[0m"
    exit 1
}

# --- Project & File Structure ---
setup_directories() {
    print_section "Setting up project directories"
    mkdir -p "$CONFIG_DIR" "$LOG_DIR" "$SSH_KEY_DIR" "$SCRIPTS_DIR" || print_error "Failed to create directories"
    print_success "Directories created: $CONFIG_DIR, $LOG_DIR, $SSH_KEY_DIR, $SCRIPTS_DIR"
}

# --- Day3 verification, run_tests, and startup scripts (run with full path) ---
create_day3_scripts() {
    print_section "Creating Day3 scripts (verify, run_tests, startup)"
    # verify_setup.sh
    if [ ! -f "$SCRIPTS_DIR/verify_setup.sh" ]; then
        cat << 'EOFVERIFY' > "$SCRIPTS_DIR/verify_setup.sh"
#!/bin/bash
# Day3: Verify all setup artifacts. Run with full path or from DAY3_ROOT.
DAY3_ROOT="${DAY3_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CONFIG_DIR="$DAY3_ROOT/config"
LOG_DIR="$DAY3_ROOT/logs"
SCRIPTS_DIR="$DAY3_ROOT/scripts"
SSH_KEY_DIR="$CONFIG_DIR/ssh_keys"
FAIL=0
check() { if [ -e "$1" ]; then echo "  OK   $1"; else echo "  FAIL $1"; FAIL=1; fi; }
echo "Verifying Day3 setup artifacts under $DAY3_ROOT"
check "$DAY3_ROOT"
check "$CONFIG_DIR"
check "$LOG_DIR"
check "$SCRIPTS_DIR"
check "$SSH_KEY_DIR"
check "$SCRIPTS_DIR/startup.sh"
check "$SCRIPTS_DIR/verify_setup.sh"
check "$SCRIPTS_DIR/run_tests.sh"
if [ $FAIL -eq 0 ]; then echo "  All checks passed."; exit 0; else exit 1; fi
EOFVERIFY
        chmod +x "$SCRIPTS_DIR/verify_setup.sh"
        print_success "Created $SCRIPTS_DIR/verify_setup.sh"
    else
        print_info "verify_setup.sh already exists."
    fi
    # run_tests.sh
    if [ ! -f "$SCRIPTS_DIR/run_tests.sh" ]; then
        cat << 'EOFTESTS' > "$SCRIPTS_DIR/run_tests.sh"
#!/bin/bash
# Day3: Run verification tests. Use full path or run from DAY3_ROOT.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY="$SCRIPT_DIR/verify_setup.sh"
if [ ! -f "$VERIFY" ]; then
    echo "ERROR: Run setup.sh first. $VERIFY not found."
    exit 1
fi
exec "$VERIFY"
EOFTESTS
        chmod +x "$SCRIPTS_DIR/run_tests.sh"
        print_success "Created $SCRIPTS_DIR/run_tests.sh"
    else
        print_info "run_tests.sh already exists."
    fi
    # startup.sh (demo: show status, no duplicate)
    if [ ! -f "$SCRIPTS_DIR/startup.sh" ]; then
        cat << 'EOFSTART' > "$SCRIPTS_DIR/startup.sh"
#!/bin/bash
# Day3: Startup/demo script. Run with full path: $SCRIPTS_DIR/startup.sh
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAY3_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$DAY3_ROOT" || exit 1
# Avoid duplicate: only one demo at a time (lock file)
LOCK="${TMPDIR:-/tmp}/day3_startup.lock"
if [ -f "$LOCK" ]; then
    old_pid=$(cat "$LOCK" 2>/dev/null)
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null && [ "$old_pid" != "$$" ]; then
        echo "  [SKIP] Day3 startup already running (avoid duplicate)."
        exit 0
    fi
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT
echo "  [START] Day3 demo from $DAY3_ROOT"
echo -e "\n\e[1;35m===========================================================\e[0m"
echo -e "\e[1;35m  Day3: Secure Headless Home Lab - Demo\e[0m"
echo -e "\e[1;35m===========================================================\e[0m"
echo -e "  Config:  $DAY3_ROOT/config"
echo -e "  Logs:    $DAY3_ROOT/logs"
echo -e "  Scripts: $DAY3_ROOT/scripts"
echo -e "  Time:    $(date)"
echo -e "\e[1;35m===========================================================\e[0m\n"
EOFSTART
        chmod +x "$SCRIPTS_DIR/startup.sh"
        print_success "Created $SCRIPTS_DIR/startup.sh"
    else
        print_info "startup.sh already exists."
    fi
}

# --- Core Setup Logic (on target system - VM/Physical or Docker Container) ---
perform_hardening() {
    local target_prefix="$1" # Empty for host, "docker exec <container_id>" for docker
    local is_docker_target="$2"

    print_section "Performing SSH Hardening"

    # 1. Backup sshd_config
    print_info "Backing up current sshd_config..."
    if [ -z "$target_prefix" ]; then
        sudo cp /etc/ssh/sshd_config "$SSH_CONFIG_BACKUP" || print_error "Failed to backup sshd_config"
    else
        # For docker, we'll backup inside the container's filesystem
        $target_prefix cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak_pre_hardening || print_error "Failed to backup sshd_config in container"
    fi
    print_success "sshd_config backed up."

    # 2. Create dedicated sudo user
    print_info "Creating dedicated sudo user: $LAB_USER..."
    if ! $target_prefix id -u "$LAB_USER" >/dev/null 2>&1; then
        $target_prefix sudo useradd -m -s /bin/bash "$LAB_USER" || print_error "Failed to add user $LAB_USER"
        echo "$LAB_USER:securepassword" | $target_prefix sudo chpasswd || print_error "Failed to set password for $LAB_USER"
        $target_prefix sudo usermod -aG sudo "$LAB_USER" || print_error "Failed to add $LAB_USER to sudo group"
        print_success "User '$LAB_USER' created with sudo privileges and password 'securepassword'."
        print_warning "NOTE: Password 'securepassword' is for initial access. You MUST replace it with SSH keys."
    else
        print_info "User '$LAB_USER' already exists."
    fi

    # 3. Generate SSH key pair for the lab user (for demonstration purposes on the server)
    # In a real scenario, you'd copy *your client's* public key here.
    print_info "Generating SSH key pair for $LAB_USER (on target system)..."
    $target_prefix sudo -u "$LAB_USER" mkdir -p /home/"$LAB_USER"/.ssh || print_error "Failed to create .ssh dir"
    $target_prefix sudo -u "$LAB_USER" chmod 700 /home/"$LAB_USER"/.ssh || print_error "Failed to set .ssh dir permissions"
    if ! $target_prefix sudo -u "$LAB_USER" test -f /home/"$LAB_USER"/.ssh/id_ed25519; then
        $target_prefix sudo -u "$LAB_USER" ssh-keygen -t ed25519 -f /home/"$LAB_USER"/.ssh/id_ed25519 -N "" || print_error "Failed to generate SSH key for $LAB_USER"
        $target_prefix sudo -u "$LAB_USER" cat /home/"$LAB_USER"/.ssh/id_ed25519.pub > /home/"$LAB_USER"/.ssh/authorized_keys || print_error "Failed to add public key to authorized_keys"
        $target_prefix sudo -u "$LAB_USER" chmod 600 /home/"$LAB_USER"/.ssh/authorized_keys || print_error "Failed to set authorized_keys permissions"
        print_success "SSH key pair generated for $LAB_USER and public key added to authorized_keys."
    else
        print_info "SSH key already exists for $LAB_USER."
    fi

    # 4. Harden sshd_config
    print_info "Modifying /etc/ssh/sshd_config for hardening..."
    config_content=$(cat <<EOF
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
AllowUsers $LAB_USER
EOF
)
    # Use a temporary file to modify config to avoid issues with direct sed/awk on container
    if [ -z "$target_prefix" ]; then
        # Host: direct modification
        sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
        sudo sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
        sudo sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
        sudo sed -i '/^AllowUsers/d' /etc/ssh/sshd_config # Remove existing AllowUsers
        echo "AllowUsers $LAB_USER" | sudo tee -a /etc/ssh/sshd_config > /dev/null
    else
        # Docker: use a temp file inside container, then move
        $target_prefix sh -c "
            sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && 
            sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && 
            sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config && 
            sed -i '/^AllowUsers/d' /etc/ssh/sshd_config && 
            echo "AllowUsers $LAB_USER" >> /etc/ssh/sshd_config
        " || print_error "Failed to modify sshd_config in container"
    fi
    print_success "sshd_config hardened: Root login and password auth disabled, AllowUsers set to '$LAB_USER'."

    # 5. Configure Firewall (UFW) - Only for host system
    if [ -z "$target_prefix" ]; then
        print_info "Configuring UFW firewall..."
        sudo apt-get update && sudo apt-get install -y ufw || print_error "Failed to install UFW"
        sudo ufw default deny incoming || print_error "Failed to set default deny incoming"
        sudo ufw default allow outgoing || print_error "Failed to set default allow outgoing"
        sudo ufw allow "$SSH_PORT"/tcp || print_error "Failed to allow SSH port $SSH_PORT"
        echo "y" | sudo ufw enable || print_error "Failed to enable UFW"
        print_success "UFW configured and enabled. SSH port $SSH_PORT allowed."
        sudo ufw status verbose
    else
        print_info "Skipping UFW configuration for Docker container (container networking is different)."
    fi

    # 6. Restart SSH Service
    print_info "Restarting SSH service..."
    if [ -z "$target_prefix" ]; then
        sudo systemctl restart sshd || print_error "Failed to restart sshd service"
    else
        $target_prefix service ssh restart || print_error "Failed to restart ssh service in container"
    fi
    print_success "SSH service restarted."
}

# --- Docker Specific Logic ---
build_docker_image() {
    print_section "Building Docker Image"
    cat > Dockerfile <<EOF
FROM ubuntu:22.04
LABEL author="Your Name"
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y openssh-server sudo ufw && 
    mkdir /var/run/sshd && 
    echo 'root:rootpassword' | chpasswd && 
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && 
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config && 
    sed -i 's/#UsePAM yes/UsePAM yes/' /etc/ssh/sshd_config && 
    echo 'PermitEmptyPasswords no' >> /etc/ssh/sshd_config && 
    echo 'UseDNS no' >> /etc/ssh/sshd_config && 
    echo 'Port 22' >> /etc/ssh/sshd_config && 
    # Clean up apt cache
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
EOF
    docker build -t secure-lab-ssh . || print_error "Failed to build Docker image"
    print_success "Docker image 'secure-lab-ssh' built."
}

run_docker_container() {
    print_section "Running Docker Container"
    CONTAINER_ID=$(docker run -d -p 2222:22 secure-lab-ssh) || print_error "Failed to run Docker container"
    print_success "Docker container '$CONTAINER_ID' running on port 2222."
    echo "$CONTAINER_ID" > "$LOG_DIR/container_id.log"
    sleep 5 # Give SSHD time to start
    echo "$CONTAINER_ID"
}

# --- Main Execution Flow ---
print_header
setup_directories
create_day3_scripts

if [ "$1" == "docker" ]; then
    print_info "Running in Docker mode."
    build_docker_image
    CONTAINER_ID=$(run_docker_container)
    print_info "Applying hardening inside container: $CONTAINER_ID"
    perform_hardening "docker exec $CONTAINER_ID" "true"

    print_section "Verification (Docker)"
    print_info "Attempting to SSH into hardened Docker container on localhost:2222 as $LAB_USER..."
    print_info "Public key for $LAB_USER on container:"
    docker exec "$CONTAINER_ID" sudo -u "$LAB_USER" cat /home/"$LAB_USER"/.ssh/id_ed25519.pub
    print_info "Private key for $LAB_USER on container (for testing, copy this to ~/.ssh/id_test_lab):"
    docker exec "$CONTAINER_ID" sudo -u "$LAB_USER" cat /home/"$LAB_USER"/.ssh/id_ed25519 > "$SSH_KEY_DIR/id_test_lab"
    chmod 600 "$SSH_KEY_DIR/id_test_lab"

    echo -e "\n\e[1;36mTo test SSH access to the hardened Docker container:\e[0m"
    echo -e "\e[0;36m1. Copy the private key to your local machine (already done to $SSH_KEY_DIR/id_test_lab).\e[0m"
    echo -e "\e[0;36m2. Try: ssh -i $SSH_KEY_DIR/id_test_lab -p 2222 $LAB_USER@localhost\e[0m"
    echo -e "\e[0;36m3. This should succeed.\e[0m"
    echo -e "\e[0;36m4. Try to SSH as root or with password (should fail):\e[0m"
    echo -e "\e[0;36m   ssh -p 2222 root@localhost (should fail)\e[0m"
    echo -e "\e[0;36m   ssh -o PreferredAuthentications=password -p 2222 $LAB_USER@localhost (should fail)\e[0m"

    print_success "Docker hardening and verification instructions provided. Container ID: $CONTAINER_ID"

else
    print_info "Running in Host (VM/Physical) mode."
    print_warning "This script will modify your host system's SSH configuration and UFW rules."
    read -p "Are you sure you want to proceed? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[yY]$ ]]; then
        print_info "Aborting host system hardening."
        # Still show dashboard and completion (dirs/scripts were created)
        DIRS_COUNT=0; FILES_COUNT=0
        for d in "$DAY3_ROOT" "$CONFIG_DIR" "$LOG_DIR" "$SCRIPTS_DIR" "$SSH_KEY_DIR"; do [ -d "$d" ] && DIRS_COUNT=$((DIRS_COUNT+1)); done
        [ -f "$SCRIPTS_DIR/startup.sh" ] 2>/dev/null && FILES_COUNT=$((FILES_COUNT+1))
        [ -f "$SCRIPTS_DIR/verify_setup.sh" ] 2>/dev/null && FILES_COUNT=$((FILES_COUNT+1))
        [ -f "$SCRIPTS_DIR/run_tests.sh" ] 2>/dev/null && FILES_COUNT=$((FILES_COUNT+1))
        print_section "5. Setup Dashboard Metrics"
        printf "  %-45s %s\n" "Directories created/verified" "$DIRS_COUNT"
        printf "  %-45s %s\n" "Scripts created (startup, verify, run_tests)" "$FILES_COUNT"
        echo -e "  \e[1;33mRun \e[1;37m$SCRIPTS_DIR/run_tests.sh\e[1;33m to test. Run \e[1;37m$SCRIPTS_DIR/startup.sh\e[1;33m to start demo.\e[0m"
        echo -e "\e[1;34m=================================================================\e[0m"
        echo -e "\e[1;32m🚀 Setup process completed (hardening skipped).\e[0m"
        echo -e "\e[1;34m=================================================================\e[0m\n"
        exit 0
    fi

    # Check for sudo
    if ! command -v sudo &> /dev/null; then
        print_error "sudo is not installed. Please install sudo or run as root directly (not recommended)."
    fi

    # Check for OpenSSH server (sshd_config) before hardening
    if [ ! -f /etc/ssh/sshd_config ]; then
        print_warning "/etc/ssh/sshd_config not found. OpenSSH server is not installed (common on WSL/desktop)."
        print_info "Skipping host hardening. Install with: sudo apt install openssh-server (then re-run with y if desired)."
        # Show dashboard and exit instead of failing
        DIRS_COUNT=0; FILES_COUNT=0
        for d in "$DAY3_ROOT" "$CONFIG_DIR" "$LOG_DIR" "$SCRIPTS_DIR" "$SSH_KEY_DIR"; do [ -d "$d" ] && DIRS_COUNT=$((DIRS_COUNT+1)); done
        [ -f "$SCRIPTS_DIR/startup.sh" ] 2>/dev/null && FILES_COUNT=$((FILES_COUNT+1))
        [ -f "$SCRIPTS_DIR/verify_setup.sh" ] 2>/dev/null && FILES_COUNT=$((FILES_COUNT+1))
        [ -f "$SCRIPTS_DIR/run_tests.sh" ] 2>/dev/null && FILES_COUNT=$((FILES_COUNT+1))
        print_section "5. Setup Dashboard Metrics"
        printf "  %-45s %s\n" "Directories created/verified" "$DIRS_COUNT"
        printf "  %-45s %s\n" "Scripts created (startup, verify, run_tests)" "$FILES_COUNT"
        echo -e "  \e[1;33mRun \e[1;37m$SCRIPTS_DIR/run_tests.sh\e[1;33m to test. Run \e[1;37m$SCRIPTS_DIR/startup.sh\e[1;33m to start demo.\e[0m"
        echo -e "\e[1;34m=================================================================\e[0m"
        echo -e "\e[1;32m🚀 Setup process completed (hardening skipped - no sshd).\e[0m"
        echo -e "\e[1;34m=================================================================\e[0m\n"
        exit 0
    fi

    perform_hardening "" "false"

    print_section "Verification (Host)"
    print_info "Please attempt to SSH into your server using the new '$LAB_USER' and the *server-generated* key."
    print_info "For a real-world scenario, you would copy *your client's* public key to /home/$LAB_USER/.ssh/authorized_keys."
    print_info "The server-generated public key for $LAB_USER is:"
    sudo -u "$LAB_USER" cat /home/"$LAB_USER"/.ssh/id_ed25519.pub
    print_info "The server-generated private key for $LAB_USER (for testing, not for production use):"
    sudo -u "$LAB_USER" cat /home/"$LAB_USER"/.ssh/id_ed25519 > "$SSH_KEY_DIR/id_test_lab_host"
    chmod 600 "$SSH_KEY_DIR/id_test_lab_host"

    echo -e "\n\e[1;36mTo test SSH access to the hardened host system from your client machine:\e[0m"
    echo -e "\e[0;36m1. Copy the private key generated by the server to your local machine (already done to $SSH_KEY_DIR/id_test_lab_host).\e[0m"
    echo -e "\e[0;36m2. Try: ssh -i $SSH_KEY_DIR/id_test_lab_host $LAB_USER@your_server_ip_address\e[0m"
    echo -e "\e[0;36m3. This should succeed.\e[0m"
    echo -e "\e[0;36m4. Try to SSH as root or with password (should fail):\e[0m"
    echo -e "\e[0;36m   ssh root@your_server_ip_address (should fail)\e[0m"
    echo -e "\e[0;36m   ssh -o PreferredAuthentications=password $LAB_USER@your_server_ip_address (should fail)\e[0m"

    print_success "Host hardening complete. Please verify access."
fi

# --- 5. Setup Dashboard Metrics (non-zero after demo) ---
print_section "5. Setup Dashboard Metrics"
DIRS_COUNT=0
FILES_COUNT=0
for d in "$DAY3_ROOT" "$CONFIG_DIR" "$LOG_DIR" "$SCRIPTS_DIR" "$SSH_KEY_DIR"; do
    [ -d "$d" ] && DIRS_COUNT=$((DIRS_COUNT+1))
done
[ -f "$SCRIPTS_DIR/startup.sh" ] 2>/dev/null && FILES_COUNT=$((FILES_COUNT+1))
[ -f "$SCRIPTS_DIR/verify_setup.sh" ] 2>/dev/null && FILES_COUNT=$((FILES_COUNT+1))
[ -f "$SCRIPTS_DIR/run_tests.sh" ] 2>/dev/null && FILES_COUNT=$((FILES_COUNT+1))
printf "  %-45s %s\n" "Directories created/verified" "$DIRS_COUNT"
printf "  %-45s %s\n" "Scripts created (startup, verify, run_tests)" "$FILES_COUNT"
echo -e "  \e[1;33mRun \e[1;37m$SCRIPTS_DIR/run_tests.sh\e[1;33m to test. Run \e[1;37m$SCRIPTS_DIR/startup.sh\e[1;33m to start demo.\e[0m"

print_info "Refer to the lesson for detailed verification steps."
echo -e "\e[1;34m=================================================================\e[0m"
echo -e "\e[1;32m🚀 Setup process completed. Digital sovereignty established!\e[0m"
echo -e "\e[1;34m=================================================================\e[0m\n"