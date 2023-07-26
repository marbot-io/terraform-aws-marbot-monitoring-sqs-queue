package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestDefault(t *testing.T) {
	t.Parallel()

	terraformPath := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/default")

	sqsOptions := configSQSqueue(t)

	defer terraform.Destroy(t, sqsOptions)
	terraform.InitAndApply(t, sqsOptions)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: terraformPath,
		Vars: map[string]interface{}{
			"endpoint_id": os.Getenv("MARBOT_ENDPOINT_ID"),
			"queue_name": terraform.Output(t, sqsOptions, "queue_name"),
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}
