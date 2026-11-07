//go:build integration

package mongo

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
)

const jsonSchemaValidator = `{"$jsonSchema":{"bsonType":"object","required":["name"],"properties":{"name":{"bsonType":"string"},"age":{"bsonType":"int","minimum":0}}}}`

func TestIntegrationValidationLifecycle(t *testing.T) {
	c := connect(t)
	ctx := context.Background()
	coll := scratch(t, c)
	if _, err := c.Insert(ctx, "queravue", coll, []engine.Document{`{"name":"a"}`}, engine.WriteOptions{}); err != nil {
		t.Fatal(err)
	}

	before, err := c.GetValidation(ctx, "queravue", coll)
	if err != nil || before.Validator != "" {
		t.Fatalf("fresh collection: %+v %v", before, err)
	}

	command, err := c.SetValidation(ctx, "queravue", coll, engine.ValidationRule{Validator: jsonSchemaValidator, Level: "strict", Action: "error"}, true)
	if err != nil || !strings.Contains(command, "collMod") || !strings.Contains(command, "$jsonSchema") {
		t.Fatalf("dry run: %q %v", command, err)
	}
	if got, _ := c.GetValidation(ctx, "queravue", coll); got.Validator != "" {
		t.Fatalf("dry run changed the validator: %+v", got)
	}

	if _, err := c.SetValidation(ctx, "queravue", coll, engine.ValidationRule{Validator: jsonSchemaValidator, Level: "strict", Action: "error"}, false); err != nil {
		t.Fatal(err)
	}
	got, err := c.GetValidation(ctx, "queravue", coll)
	if err != nil || !strings.Contains(got.Validator, "$jsonSchema") || got.Level != "strict" || got.Action != "error" {
		t.Fatalf("after set: %+v %v", got, err)
	}
	if _, err := c.Insert(ctx, "queravue", coll, []engine.Document{`{"age":{"$numberInt":"3"}}`}, engine.WriteOptions{}); err == nil {
		t.Error("a document without the required name was accepted")
	}

	if _, err := c.SetValidation(ctx, "queravue", coll, engine.ValidationRule{Level: "off"}, false); err != nil {
		t.Fatal(err)
	}
	if got, _ := c.GetValidation(ctx, "queravue", coll); got.Validator != "" || got.Level != "off" {
		t.Errorf("after removal: %+v", got)
	}
}

func TestIntegrationValidationErrors(t *testing.T) {
	c := connect(t)
	ctx := context.Background()
	coll := scratch(t, c)

	_, err := c.SetValidation(ctx, "queravue", coll, engine.ValidationRule{Validator: `{"$jsonSchema": `}, true)
	var ee *engine.Error
	if !errors.As(err, &ee) || ee.Kind != engine.KindParse || ee.Input != engine.InputValidator {
		t.Errorf("syntax error: %v", err)
	}
	if _, err := c.SetValidation(ctx, "queravue", coll, engine.ValidationRule{Level: "sometimes"}, true); !errors.As(err, &ee) || ee.Kind != engine.KindInvalidConfig {
		t.Errorf("bad level: %v", err)
	}
	if _, err := c.GetValidation(ctx, "queravue", "qv_no_such_collection"); !errors.As(err, &ee) || ee.Kind != engine.KindNotFound {
		t.Errorf("missing collection: %v", err)
	}
	if _, err := c.SetValidation(ctx, "queravue", coll, engine.ValidationRule{Validator: `{"$jsonSchema":{"bsonType":"nonsense"}}`}, false); err == nil {
		t.Error("the server accepted an invalid $jsonSchema")
	}
}
