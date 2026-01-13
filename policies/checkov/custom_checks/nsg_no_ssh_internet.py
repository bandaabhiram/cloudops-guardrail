from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckResult, CheckCategories

class NSGNoSSHFromInternet(BaseResourceCheck):
    def __init__(self):
        super().__init__(
            name="Disallow SSH (22) from Internet on NSG rules",
            id="GR_AZURE_001",
            categories=[CheckCategories.NETWORKING],
            supported_resources=["azurerm_network_security_group"],
        )

    def scan_resource_conf(self, conf):
        rules = conf.get("security_rule", [])
        for rule in rules:
            dst_port = (rule.get("destination_port_range") or [""])[0]
            direction = (rule.get("direction") or [""])[0]
            access = (rule.get("access") or [""])[0]
            src = (rule.get("source_address_prefix") or [""])[0]

            if direction == "Inbound" and access == "Allow" and str(dst_port) == "22":
                if src in ["*", "0.0.0.0/0", "Internet", "Any"]:
                    return CheckResult.FAILED

        return CheckResult.PASSED

check = NSGNoSSHFromInternet()
