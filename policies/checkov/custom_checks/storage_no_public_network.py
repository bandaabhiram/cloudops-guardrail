from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckResult, CheckCategories


class StorageNoPublicNetwork(BaseResourceCheck):
    def __init__(self):
        name = "Storage must disable public network access"
        id = "GR_AZURE_002"
        supported_resources = ["azurerm_storage_account"]
        categories = [CheckCategories.NETWORKING]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        val = conf.get("public_network_access_enabled")
        if not val:
            # If not set, treat as failed (default is public in many setups)
            return CheckResult.FAILED

        enabled = val[0]
        if enabled is False:
            return CheckResult.PASSED
        return CheckResult.FAILED


check = StorageNoPublicNetwork()
