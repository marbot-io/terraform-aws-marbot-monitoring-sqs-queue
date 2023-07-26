package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func configSQSqueue(t *testing.T) *terraform.Options {
	terraformPath := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/sqs-queue")

	return terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: terraformPath,
	})
}
