#!/bin/bash
# inject-env-vars.sh
# Injects workshop environment variables into Antora configuration
# Called by ocp4-workload-days-ops-track after showroom deployment

set -e

REPO_DIR="/showroom/repo"
SITE_FILE="${REPO_DIR}/default-site.yml"

echo "=== Injecting workshop environment variables ==="
echo "Working directory: ${REPO_DIR}"

# Check if default-site.yml exists
if [ ! -f "$SITE_FILE" ]; then
    echo "ERROR: ${SITE_FILE} not found"
    exit 1
fi

# Build asciidoc attributes based on MODULE_ENABLE_* environment variables
# These control which nav items are shown via ifdef:: conditionals

echo "Module settings (with workloads):"
echo "  MODULE_ENABLE_VIRT=${MODULE_ENABLE_VIRT:-true}"
echo "  MODULE_ENABLE_ACM=${MODULE_ENABLE_ACM:-true}"
echo "  MODULE_ENABLE_BACKUP=${MODULE_ENABLE_BACKUP:-true}"
echo "  MODULE_ENABLE_DEVHUB=${MODULE_ENABLE_DEVHUB:-true}"
echo "  MODULE_ENABLE_OLS=${MODULE_ENABLE_OLS:-true}"
echo "  MODULE_ENABLE_SECURITY=${MODULE_ENABLE_SECURITY:-true}"
echo "  MODULE_ENABLE_WAF=${MODULE_ENABLE_WAF:-true}"
echo "Module settings (content only):"
echo "  MODULE_ENABLE_LDAP=${MODULE_ENABLE_LDAP:-true}"
echo "  MODULE_ENABLE_OIDC=${MODULE_ENABLE_OIDC:-true}"
echo "  MODULE_ENABLE_OBSERVABILITY=${MODULE_ENABLE_OBSERVABILITY:-true}"
echo "  MODULE_ENABLE_PERFORMANCE=${MODULE_ENABLE_PERFORMANCE:-true}"
echo "  MODULE_ENABLE_CLOUD_INFRA=${MODULE_ENABLE_CLOUD_INFRA:-true}"

# Create attributes section for Antora
# Only set attributes for ENABLED modules (ifdef checks for presence, not value)
ATTRS=""

# Modules with workloads
if [ "${MODULE_ENABLE_VIRT:-true}" = "true" ]; then
    ATTRS="${ATTRS}    module_virt: ''"$'\n'
fi

if [ "${MODULE_ENABLE_ACM:-true}" = "true" ]; then
    ATTRS="${ATTRS}    module_acm: ''"$'\n'
fi

if [ "${MODULE_ENABLE_BACKUP:-true}" = "true" ]; then
    ATTRS="${ATTRS}    module_oadp: ''"$'\n'
fi

if [ "${MODULE_ENABLE_DEVHUB:-true}" = "true" ]; then
    ATTRS="${ATTRS}    module_devhub: ''"$'\n'
fi

if [ "${MODULE_ENABLE_OLS:-true}" = "true" ]; then
    ATTRS="${ATTRS}    module_ols: ''"$'\n'
fi

if [ "${MODULE_ENABLE_SECURITY:-true}" = "true" ]; then
    ATTRS="${ATTRS}    module_security: ''"$'\n'
fi

if [ "${MODULE_ENABLE_WAF:-true}" = "true" ]; then
    ATTRS="${ATTRS}    module_waf: ''"$'\n'
fi

# Modules without workloads (content only)
if [ "${MODULE_ENABLE_LDAP:-true}" = "true" ]; then
    ATTRS="${ATTRS}    module_ldap: ''"$'\n'
fi

if [ "${MODULE_ENABLE_OIDC:-true}" = "true" ]; then
    ATTRS="${ATTRS}    module_oidc: ''"$'\n'
fi

if [ "${MODULE_ENABLE_OBSERVABILITY:-true}" = "true" ]; then
    ATTRS="${ATTRS}    module_observability: ''"$'\n'
fi

if [ "${MODULE_ENABLE_PERFORMANCE:-true}" = "true" ]; then
    ATTRS="${ATTRS}    module_performance: ''"$'\n'
fi

if [ "${MODULE_ENABLE_CLOUD_INFRA:-true}" = "true" ]; then
    ATTRS="${ATTRS}    module_cloud_infra: ''"$'\n'
fi

# TOC depth - only show main sections
ATTRS="${ATTRS}    toclevels: 2"$'\n'

# Also add standard workshop variables
ATTRS="${ATTRS}    api_url: '${API_URL:-}'"$'\n'
ATTRS="${ATTRS}    master_url: '${MASTER_URL:-}'"$'\n'
ATTRS="${ATTRS}    kubeadmin_password: '${KUBEADMIN_PASSWORD:-}'"$'\n'
ATTRS="${ATTRS}    ssh_username: '${SSH_USERNAME:-}'"$'\n'
ATTRS="${ATTRS}    ssh_password: '${SSH_PASSWORD:-}'"$'\n'
ATTRS="${ATTRS}    bastion_fqdn: '${BASTION_FQDN:-}'"$'\n'
ATTRS="${ATTRS}    guid: '${GUID:-}'"$'\n'
ATTRS="${ATTRS}    route_subdomain: '${ROUTE_SUBDOMAIN:-}'"$'\n'
ATTRS="${ATTRS}    environment: '${ENVIRONMENT:-Amazon Web Services}'"$'\n'

echo "Attributes to inject:"
echo "$ATTRS"

# Check if asciidoc section already exists
if grep -q "^asciidoc:" "$SITE_FILE"; then
    echo "asciidoc section already exists, replacing attributes..."
    # Remove existing asciidoc section and add new one
    # This is a simple approach - backup and rewrite
    cp "$SITE_FILE" "${SITE_FILE}.bak"

    # Remove old asciidoc section (everything from "asciidoc:" to next top-level key or EOF)
    awk '
        /^asciidoc:/ { in_asciidoc=1; next }
        in_asciidoc && /^[a-z]/ { in_asciidoc=0 }
        !in_asciidoc { print }
    ' "${SITE_FILE}.bak" > "$SITE_FILE"
fi

# Append asciidoc section with attributes
echo "" >> "$SITE_FILE"
echo "asciidoc:" >> "$SITE_FILE"
echo "  attributes:" >> "$SITE_FILE"
echo -n "$ATTRS" >> "$SITE_FILE"

echo "=== Injection complete ==="
echo "Updated ${SITE_FILE}:"
cat "$SITE_FILE"
