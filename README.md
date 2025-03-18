# iptables-basic-setup

## Description
This script configures iptables rules for managing network traffic, ensuring security and proper filtering. It can be used to apply, reset, or modify firewall rules as needed.

## Installation & usage

### 1 backup existing iptables rules
Before applying new rules, **always** back up your current iptables configuration to avoid accidental misconfigurations:
```bash
sudo iptables-save > <path>/iptables-backup-$(date +%F).rules
```
This will create a backup file with the current date.

### 2 Apply the new iptables rules
Run the script with root privileges:
```bash
sudo bash iptables.sh
```

### 3 Verify the applied rules
Check if the rules were successfully applied:
```bash
sudo iptables -L -v -n
```

### 4 Restore previous iptables configuration (if needed)
If something goes wrong, restore the old rules using:
```bash
sudo iptables-restore < <path>/iptables-backup-YYYY-MM-DD.rules
```
Replace `YYYY-MM-DD` with the actual backup date.

## Additional notes
- Ensure you have `iptables` installed before running the script.
- Consider adding the script to system startup if persistent firewall rules are required:
  ```bash
  apt install -y iptables-persistent
  iptables-save &gt; /etc/iptables/rules.v4
  ```
