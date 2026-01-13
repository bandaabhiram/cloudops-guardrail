from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckResult, CheckCategories


class StorageTLS12(BaseResourceCheck):
    def __init__(self):
        name = "Storage must require TLS 1.2 minimum"
        id = "GR_AZURE_003"
        supported_resources = ["azurerm_storage_account"]
        categories = [CheckCategories.ENCRYPTION]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        tls = conf.get("min_tls_version")
        if not tls:
            return CheckResult.FAILED
        return CheckResult.PASSED if tls[0] == "TLS1_2" else CheckResult.FAILED


check = StorageTLS12()
