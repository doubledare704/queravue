package mongo

import (
	"context"
	"fmt"
	"strconv"
	"strings"

	"go.mongodb.org/mongo-driver/v2/bson"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.ValidationManager = (*Conn)(nil)

// GetValidation implements engine.ValidationManager.
func (c *Conn) GetValidation(ctx context.Context, database, collection string) (engine.ValidationRule, error) {
	coll, err := c.coll("get validation", database, collection)
	if err != nil {
		return engine.ValidationRule{}, err
	}
	specs, err := coll.Database().ListCollectionSpecifications(ctx, bson.D{{Key: "name", Value: collection}})
	if err != nil {
		return engine.ValidationRule{}, c.fail("get validation", err)
	}
	if len(specs) == 0 {
		return engine.ValidationRule{}, engine.Errorf(engine.KindNotFound, c.id, "get validation", "collection %q not found", collection)
	}
	var rule engine.ValidationRule
	options := specs[0].Options
	if v, err := options.LookupErr("validator"); err == nil {
		if doc, ok := v.DocumentOK(); ok && len(doc) > 0 {
			if rule.Validator, err = toEJSON(doc); err != nil {
				return rule, engine.Errorf(engine.KindServer, c.id, "get validation", "render validator: %v", err)
			}
		}
	}
	if v, err := options.LookupErr("validationLevel"); err == nil {
		rule.Level, _ = v.StringValueOK()
	}
	if v, err := options.LookupErr("validationAction"); err == nil {
		rule.Action, _ = v.StringValueOK()
	}
	return rule, nil
}

// SetValidation implements engine.ValidationManager.
func (c *Conn) SetValidation(ctx context.Context, database, collection string, rule engine.ValidationRule, dryRun bool) (string, error) {
	coll, err := c.coll("set validation", database, collection)
	if err != nil {
		return "", err
	}
	if !oneOf(rule.Level, "", "off", "moderate", "strict") {
		return "", engine.Errorf(engine.KindInvalidConfig, c.id, "set validation", "validation level %q is not off, moderate or strict", rule.Level)
	}
	if !oneOf(rule.Action, "", "error", "warn") {
		return "", engine.Errorf(engine.KindInvalidConfig, c.id, "set validation", "validation action %q is not error or warn", rule.Action)
	}
	var validator any = bson.D{}
	if strings.TrimSpace(rule.Validator) != "" {
		if validator, err = parseDocument(rule.Validator, false, engine.InputValidator); err != nil {
			return "", c.parseErr(err)
		}
	}
	cmd := bson.D{{Key: "collMod", Value: collection}, {Key: "validator", Value: validator}}
	if rule.Level != "" {
		cmd = append(cmd, bson.E{Key: "validationLevel", Value: rule.Level})
	}
	if rule.Action != "" {
		cmd = append(cmd, bson.E{Key: "validationAction", Value: rule.Action})
	}
	text, err := bson.MarshalExtJSON(cmd, false, false)
	if err != nil {
		return "", engine.Errorf(engine.KindServer, c.id, "set validation", "render command: %v", err)
	}
	statement := fmt.Sprintf("db.getSiblingDB(%s).runCommand(%s)", strconv.Quote(coll.Database().Name()), text)
	if dryRun {
		return statement, nil
	}
	if err := coll.Database().RunCommand(ctx, cmd).Err(); err != nil {
		return statement, c.fail("set validation", err)
	}
	return statement, nil
}

func oneOf(s string, options ...string) bool {
	for _, o := range options {
		if s == o {
			return true
		}
	}
	return false
}
