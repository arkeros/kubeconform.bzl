package main

import (
	"encoding/json"
	"testing"
)

func TestAdditionalProperties_TopLevelSkipped(t *testing.T) {
	schema := map[string]interface{}{
		"type": "object",
		"properties": map[string]interface{}{
			"spec": map[string]interface{}{
				"type": "object",
				"properties": map[string]interface{}{
					"replicas": map[string]interface{}{
						"type": "integer",
					},
				},
			},
		},
	}

	result := additionalProperties(schema, true)

	// Top level should NOT have additionalProperties (skip=true)
	if _, ok := result["additionalProperties"]; ok {
		t.Error("top-level should not have additionalProperties set")
	}

	// Nested "spec" SHOULD have additionalProperties: false
	spec := result["properties"].(map[string]interface{})["spec"].(map[string]interface{})
	ap, ok := spec["additionalProperties"]
	if !ok {
		t.Fatal("spec should have additionalProperties set")
	}
	if ap != false {
		t.Errorf("spec.additionalProperties = %v, want false", ap)
	}
}

func TestAdditionalProperties_NestedStrictness(t *testing.T) {
	// Simulate a CRD schema like PeerAuthentication
	crdYAML := `
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: tests.example.com
spec:
  group: example.com
  names:
    kind: Test
  versions:
    - name: v1
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                replicas:
                  type: integer
                name:
                  type: string
`
	_ = crdYAML // used conceptually; we test writeSchemaFile output directly

	// Build a schema mimicking what processFile extracts
	schema := map[string]interface{}{
		"type": "object",
		"properties": map[string]interface{}{
			"spec": map[string]interface{}{
				"type": "object",
				"properties": map[string]interface{}{
					"replicas": map[string]interface{}{"type": "integer"},
					"name":     map[string]interface{}{"type": "string"},
				},
			},
		},
	}

	// Apply the same transform writeSchemaFile does
	schema = additionalProperties(schema, true)
	schema = replaceIntOrString(schema).(map[string]interface{})

	// Marshal to JSON and parse back for clean comparison
	data, err := json.Marshal(schema)
	if err != nil {
		t.Fatal(err)
	}

	var parsed map[string]interface{}
	if err := json.Unmarshal(data, &parsed); err != nil {
		t.Fatal(err)
	}

	// Top level: NO additionalProperties (allows kind, apiVersion, metadata)
	if _, ok := parsed["additionalProperties"]; ok {
		t.Error("top-level schema must not have additionalProperties (Kubernetes injects kind/apiVersion/metadata)")
	}

	// spec level: HAS additionalProperties=false (catches typos like spec.replcas)
	spec := parsed["properties"].(map[string]interface{})["spec"].(map[string]interface{})
	if ap, ok := spec["additionalProperties"]; !ok || ap != false {
		t.Errorf("spec must have additionalProperties=false to catch invalid fields, got %v", ap)
	}
}
