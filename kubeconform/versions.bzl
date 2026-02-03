"""Kubeconform version registry with SHA256 hashes."""

DEFAULT_KUBECONFORM_VERSION = "0.6.7"

KUBECONFORM_VERSIONS = {
    "0.6.7-darwin_amd64": ("kubeconform-darwin-amd64.tar.gz", "3b5324ac4fd38ac60a49823b4051ff42ff7eb70144f1e9741fed1d14bc4fdb4e"),
    "0.6.7-darwin_arm64": ("kubeconform-darwin-arm64.tar.gz", "cbb47d938a8d18eb5f79cb33663b2cecdee0c8ac0bf562ebcfca903df5f0802f"),
    "0.6.7-linux_amd64": ("kubeconform-linux-amd64.tar.gz", "95f14e87aa28c09d5941f11bd024c1d02fdc0303ccaa23f61cef67bc92619d73"),
    "0.6.7-linux_arm64": ("kubeconform-linux-arm64.tar.gz", "dc82f79bb03c5479b1ae5fd4af221e4b5a3111f62bf01a2795d9c5c20fa96644"),
    "0.6.7-windows_amd64": ("kubeconform-windows-amd64.zip", "450a561ae833cbd1fc41201f7ebb64395c56e7d01e2dc954332143bff81277a3"),
}

def get_kubeconform_url(version, filename):
    """Returns the download URL for a kubeconform release."""
    return "https://github.com/yannh/kubeconform/releases/download/v{}/{}".format(version, filename)
