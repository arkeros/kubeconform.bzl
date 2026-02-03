module kubeconform_hermetic_example

go 1.24.3

require github.com/yannh/kubeconform v0.6.7 // indirect

require (
	github.com/hashicorp/go-cleanhttp v0.5.2 // indirect
	github.com/hashicorp/go-retryablehttp v0.7.7 // indirect
	github.com/santhosh-tekuri/jsonschema/v5 v5.3.1 // indirect
	sigs.k8s.io/yaml v1.4.0 // indirect
)

tool github.com/yannh/kubeconform/cmd/kubeconform
