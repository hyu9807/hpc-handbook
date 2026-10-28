
# Remote Access and Development

## Overview

Ye Lab HPC provides secure remote access to its
research computing infrastructure through SSH.

Node01 is a lab-managed Ubuntu workstation connected
to the Colorado School of Mines Research Network.

The remote development workflow was successfully
validated on October 28, 2026.

### Validated Access Path

```text
MacBook Pro (macOS 27)
    |
    | GlobalProtect VPN
    v
Mines Research DMZ
    |
    | SSH / TCP 22
    v
yelab-node01 (Ubuntu 24.04 LTS)
    |
    +-- SSH terminal
    +-- VS Code Remote-SSH
    +-- Slurm workload submission
    +-- NVIDIA RTX 5080
    +-- Windows 11 KVM guest
```

VPN access and remote development are separate
components. SSH authentication does not replace
campus network access authorization.

## 1. Campus Network Configuration

### Research DMZ

Node01 is a non-Mines-managed research workstation.

The original campus Ethernet network policy restricted
remote SSH and RDP access to unmanaged devices.

Mines IT approved moving Node01 to the Research
Network through a Special Network Access Request.

Official request portal:

https://helpcenter.mines.edu/TDClient/1946/Portal/Requests/Service/55429/Special-Network-Access-Request

The physical Ethernet MAC address was provided to
Mines IT for network registration.

Following IT confirmation, Node01 was rebooted
and the approved remote access path was validated.

### Network Properties

| Property | Configuration |
|---|---|
| Hostname | yelab-node01 |
| Interface | enp132s0 |
| Connection | netplan-enp132s0 |
| Address assignment | DHCP |
| Network | Mines Research Network |
| Remote access | GlobalProtect + SSH |
| SSH port | TCP 22 |

The IP address is assigned dynamically and must
not be assumed to remain unchanged.

Actual IP addresses, hardware identifiers, and
administrative ticket details should be maintained
in a private infrastructure inventory.

### Access Restrictions

Direct SSH from Mines WiFi is not the approved
access path established during this deployment.

GlobalProtect VPN is required for the validated
remote access workflow.

Future multi-node communication must be separately
verified with the campus Network Group.

Research DMZ membership does not automatically
guarantee unrestricted inter-node connectivity.

## 2. GlobalProtect on macOS

### Prerequisites

- An authorized Mines account
- GlobalProtect VPN client
- A supported macOS configuration
- Access to the approved Research Network

### macOS 27 Compatibility

During deployment, GlobalProtect initially failed
to connect on the MacBook running macOS 27.

Mines IT identified a configuration workaround:
enable macOS Firewall Stealth Mode.

On the tested system:

1. Open System Settings.
2. Navigate to Network > Firewall.
3. Open Firewall Options.
4. Enable Stealth Mode.
5. Reconnect GlobalProtect.

After enabling Stealth Mode, GlobalProtect connected
successfully without the previous error.

**Validation:** Successful on October 28, 2026.

This is a deployment-specific observed workaround,
not a universal requirement for all macOS devices
or GlobalProtect versions.

Do not disable system firewall protections as a
substitute for proper troubleshooting.

## 3. SSH Key Authentication

### Generate a Dedicated Key

On the MacBook:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh

ssh-keygen -t ed25519 -a 100 \
  -f ~/.ssh/id_ed25519_yelab \
  -C "yelab-node01-macbook"
```

Use a passphrase to protect the private key.

The generated files are:

```text
~/.ssh/id_ed25519_yelab
~/.ssh/id_ed25519_yelab.pub
```

The private key must never be uploaded to GitHub
or copied to the remote workstation.

### Install the Public Key

With GlobalProtect connected:

```bash
cat ~/.ssh/id_ed25519_yelab.pub | \
ssh <USERNAME>@<NODE_IP> \
'umask 077; mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys'
```

This appends the public key without replacing
existing authorized keys.

### Verify Key Authentication

```bash
ssh -i ~/.ssh/id_ed25519_yelab \
  -o PreferredAuthentications=publickey \
  -o PasswordAuthentication=no \
  <USERNAME>@<NODE_IP>
```

A successful login without the Ubuntu account
password confirms public-key authentication.

Password-based SSH access should not be disabled
until key authentication and recovery access
have been independently verified.

## 4. macOS Keychain and SSH Config

### Add Key to macOS Keychain

```bash
ssh-add --apple-use-keychain \
  ~/.ssh/id_ed25519_yelab
```

### Configure SSH Host Alias

Edit:

```text
~/.ssh/config
```

Add:

```sshconfig
Host yelab-node01
    HostName <NODE_IP_OR_DNS>
    User <USERNAME>
    IdentityFile ~/.ssh/id_ed25519_yelab
    IdentitiesOnly yes
    AddKeysToAgent yes
    UseKeychain yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

The `UseKeychain` directive is specific to
Apple's SSH client.

Protect the config file:

```bash
chmod 600 ~/.ssh/config
```

### Connect

With GlobalProtect active:

```bash
ssh yelab-node01
```

This workflow was successfully validated using
ED25519 authentication and macOS Keychain.

## 5. VS Code Remote-SSH

### Installation

Install Visual Studio Code on the MacBook.

Install the Microsoft Remote - SSH extension.

Extension identifier:

```text
ms-vscode-remote.remote-ssh
```

### Connection

1. Connect GlobalProtect.
2. Open VS Code.
3. Open the Command Palette.
4. Select `Remote-SSH: Connect to Host...`.
5. Choose `yelab-node01`.
6. Select Linux when prompted.

VS Code automatically installs its remote server
under the remote user's home directory:

```text
~/.vscode-server/
```

The first installation requires access to the
appropriate VS Code Server download resources.

### Validated Client Settings

The initial Remote-SSH attempt timed out despite
successful SSH access from macOS Terminal.

The following VS Code User Settings were applied:

```json
{
    "remote.SSH.showLoginTerminal": true,
    "remote.SSH.useLocalServer": false,
    "remote.SSH.connectTimeout": 60
}
```

These settings resolved the connection issue
in the tested deployment.

They should be merged with existing VS Code
settings rather than replacing unrelated entries.

### Server Installation Verification

The successful installation log reported:

```text
Download complete
unpackResult==success==
osReleaseId==ubuntu==
arch==x86_64==
```

The VS Code Server started successfully and
exposed a localhost listener for SSH forwarding.

The local SSH startup terminal may display:

"This shell is running on your local machine,
NOT on the connected remote machine"

This message alone does not indicate failure.

### Remote Workspace Verification

Once connected, open a folder on Node01 and
create a new integrated terminal.

Run:

```bash
hostname
whoami
nvidia-smi
```

Expected results:

- Hostname identifies yelab-node01.
- Username matches the authenticated remote account.
- NVIDIA GPU information is available.

The user confirmed that VS Code Remote-SSH was
operational on October 28, 2026.

## 6. Remote Research Computing

VS Code provides the development interface while
execution takes place on Node01.

Remote terminal commands, Python interpreters,
and Jupyter kernels should be checked to ensure
they are running on the intended host.

A VS Code Remote-SSH connection does not itself
allocate resources through Slurm.

Long-running or resource-intensive workloads
should follow the lab's Slurm scheduling policy.

See:

- [Slurm Workload Management](slurm.md)
- [GPU Computing](gpu-computing.md)

Do not assume that GPU availability in a remote
terminal guarantees an exclusive GPU allocation.

## 7. Troubleshooting

### SSH Fails Without VPN

Confirm that GlobalProtect is connected.

Research DMZ access requires the approved VPN
path. SSH keys alone do not provide network access.

### Existing SSH Works but New Connections Fail

An existing SSH session may remain active even
when new connections are unsuccessful.

On macOS, test a new connection:

```bash
ssh -o ConnectTimeout=10 \
  yelab-node01 'echo SSH_OK && hostname'
```

### Check TCP Connectivity

On macOS:

```bash
nc -vz -G 5 <NODE_IP> 22
```

A successful connection confirms TCP reachability,
but not necessarily SSH authentication.

For a VPN routing diagnostic:

```bash
route -n get <NODE_IP>
```

Verify the selected route and interface against
the expected VPN configuration.

### SSH Server Diagnostics

On Node01:

```bash
systemctl is-active ssh
sudo ss -lntp | grep ':22'
```

Do not change host firewall or campus network
rules without understanding the actual failure.

### VS Code Connection Timeout

First verify that a new Terminal SSH session
can be established.

Then enable the validated Remote-SSH settings
from Section 5 and retry.

Inspect the Remote-SSH output log for:

- Authentication errors
- SSH connection timeout
- Server installation failures
- Remote server startup failures

Do not reinstall SSH or change network settings
when ordinary SSH works and the error is isolated
to VS Code.

### IP Address Changes

Node01 currently uses DHCP.

After a campus network change, verify:

```bash
ip -4 -br addr show enp132s0
ip route
nmcli device status
```

Update the client-side SSH HostName if the
address has changed.

A stable DNS name or DHCP reservation may be
requested through campus IT.

## 8. Security and Operational Notes

- Keep SSH private keys on authorized client devices.
- Never commit private keys, passwords, or VPN tokens.
- Use GlobalProtect for approved remote access.
- Do not expose SSH or RDP directly to the internet.
- Do not bypass campus network access controls.
- Treat Node01 as a shared research resource.
- Follow Slurm policy for compute-intensive workloads.
- Keep research data and credentials out of this repository.
- Revalidate VPN and SSH connectivity after network changes.

## 9. Current Limitations

The following are not yet validated as part of
this remote-access workflow:

- Stable DNS or reserved IP for Node01
- Direct cross-node communication within Research DMZ
- Remote access to the Windows VM through SSH tunneling
- Multi-user SSH onboarding and authorization policies
- Full multi-node access and network recovery procedures

These items will be addressed during subsequent
infrastructure development.

## Validation Record

| Component | Status |
|---|---|
| Research DMZ registration | PASS |
| GlobalProtect on macOS 27 | PASS |
| SSH access through VPN | PASS |
| ED25519 public-key authentication | PASS |
| macOS Keychain integration | PASS |
| SSH host alias | PASS |
| VS Code Server installation | PASS |
| VS Code Remote-SSH connection | PASS |

**Validation date:** October 28, 2026.

**Deployment:** Ye Lab HPC Node01.

This record reflects the tested configuration.
Future changes require renewed verification.
