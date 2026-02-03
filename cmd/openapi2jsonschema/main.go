// Command openapi2jsonschema converts Kubernetes CRD YAML files to JSON schema files.
// It is a Go port of the Python script from kubeconform.
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"go.yaml.in/yaml/v4"
)

var outputDir = flag.String("output-dir", "", "Output directory for JSON schema files")

func main() {
	flag.Parse()
	if flag.NArg() < 1 {
		log.Fatal("Usage: openapi2jsonschema --output-dir <dir> <crd-files...>")
	}
	if *outputDir == "" {
		log.Fatal("--output-dir is required")
	}

	for _, crdFile := range flag.Args() {
		if err := processFile(crdFile, *outputDir); err != nil {
			log.Fatalf("processing %s: %v", crdFile, err)
		}
	}
}

func processFile(crdFile, outDir string) error {
	data, err := os.ReadFile(crdFile)
	if err != nil {
		return err
	}

	// Replace tabs with spaces
	content := strings.ReplaceAll(string(data), "\t", "    ")

	var defs []map[string]interface{}
	decoder := yaml.NewDecoder(strings.NewReader(content))
	for {
		var doc map[string]interface{}
		if err := decoder.Decode(&doc); err != nil {
			break
		}
		if doc == nil {
			continue
		}
		if items, ok := doc["items"]; ok {
			if itemList, ok := items.([]interface{}); ok {
				for _, item := range itemList {
					if m, ok := item.(map[string]interface{}); ok {
						defs = append(defs, m)
					}
				}
			}
		}
		kind, _ := doc["kind"].(string)
		if kind == "" {
			continue
		}
		if kind != "CustomResourceDefinition" {
			continue
		}
		defs = append(defs, doc)
	}

	for _, y := range defs {
		spec, _ := y["spec"].(map[string]interface{})
		if spec == nil {
			continue
		}
		names, _ := spec["names"].(map[string]interface{})
		if names == nil {
			continue
		}
		group, _ := spec["group"].(string)
		kindName, _ := names["kind"].(string)

		versions, hasVersions := spec["versions"].([]interface{})
		validation, _ := spec["validation"].(map[string]interface{})

		if hasVersions && len(versions) > 0 {
			for _, ver := range versions {
				version, ok := ver.(map[string]interface{})
				if !ok {
					continue
				}
				versionName, _ := version["name"].(string)

				var schema map[string]interface{}
				if schemaObj, ok := version["schema"].(map[string]interface{}); ok {
					schema, _ = schemaObj["openAPIV3Schema"].(map[string]interface{})
				}
				if schema == nil && validation != nil {
					schema, _ = validation["openAPIV3Schema"].(map[string]interface{})
				}
				if schema == nil {
					continue
				}

				filename := fmt.Sprintf("%s_%s_%s.json",
					strings.ToLower(group),
					strings.ToLower(versionName),
					strings.ToLower(kindName))

				if err := writeSchemaFile(schema, filename, outDir); err != nil {
					return err
				}
			}
		} else if validation != nil {
			schema, _ := validation["openAPIV3Schema"].(map[string]interface{})
			if schema == nil {
				continue
			}
			versionName, _ := spec["version"].(string)
			filename := fmt.Sprintf("%s_%s_%s.json",
				strings.ToLower(group),
				strings.ToLower(versionName),
				strings.ToLower(kindName))

			if err := writeSchemaFile(schema, filename, outDir); err != nil {
				return err
			}
		}
	}
	return nil
}

func writeSchemaFile(schema map[string]interface{}, filename, dir string) error {
	schema = additionalProperties(schema, true)
	schema = replaceIntOrString(schema).(map[string]interface{})

	data, err := json.MarshalIndent(schema, "", "  ")
	if err != nil {
		return err
	}

	outPath := filepath.Join(dir, filename)
	// Write with trailing newline to match Python's print()
	if err := os.WriteFile(outPath, append(data, '\n'), 0o644); err != nil {
		return err
	}
	log.Printf("JSON schema written to %s", outPath)
	return nil
}

func additionalProperties(data map[string]interface{}, skip bool) map[string]interface{} {
	if data == nil {
		return nil
	}
	if _, hasProps := data["properties"]; hasProps && !skip {
		if _, hasAdditional := data["additionalProperties"]; !hasAdditional {
			data["additionalProperties"] = false
		}
	}
	for _, v := range data {
		switch val := v.(type) {
		case map[string]interface{}:
			additionalProperties(val, false)
		case []interface{}:
			for _, item := range val {
				if m, ok := item.(map[string]interface{}); ok {
					additionalProperties(m, false)
				}
			}
		}
	}
	return data
}

func replaceIntOrString(data interface{}) interface{} {
	switch d := data.(type) {
	case map[string]interface{}:
		result := make(map[string]interface{}, len(d))
		for k, v := range d {
			switch val := v.(type) {
			case map[string]interface{}:
				if format, ok := val["format"]; ok && format == "int-or-string" {
					result[k] = map[string]interface{}{
						"oneOf": []interface{}{
							map[string]interface{}{"type": "string"},
							map[string]interface{}{"type": "integer"},
						},
					}
				} else {
					result[k] = replaceIntOrString(val)
				}
			case []interface{}:
				newList := make([]interface{}, len(val))
				for i, item := range val {
					newList[i] = replaceIntOrString(item)
				}
				result[k] = newList
			default:
				result[k] = v
			}
		}
		return result
	default:
		return data
	}
}
