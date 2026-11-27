package mockdata

import (
	"encoding/binary"
	"encoding/hex"
	"fmt"
	"math/rand/v2"
	"slices"
	"strings"

	"github.com/brianvoe/gofakeit/v7"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var supportedFakerKinds = []string{
	"bool",
	"city",
	"color",
	"company",
	"country",
	"country_code",
	"currency_code",
	"domain",
	"email",
	"first_name",
	"ipv4",
	"ipv6",
	"job_title",
	"json_object",
	"last_name",
	"lorem",
	"name",
	"object_id",
	"paragraph",
	"phone",
	"product_name",
	"sentence",
	"state",
	"street",
	"url",
	"user_agent",
	"username",
	"uuid",
	"word",
	"zip",
}

var supportedFakerKindSet = func() map[string]bool {
	m := make(map[string]bool, len(supportedFakerKinds))
	for _, k := range supportedFakerKinds {
		m[k] = true
	}
	return m
}()

// SupportedFakerKinds returns the sorted list of faker kinds supported by core.
func SupportedFakerKinds() []string {
	return slices.Clone(supportedFakerKinds)
}

// IsSupportedFakerKind reports whether kind is in SupportedFakerKinds.
func IsSupportedFakerKind(kind string) bool {
	return supportedFakerKindSet[kind]
}

type fakerSource struct {
	kind  string
	rng   *rand.Rand
	faker *gofakeit.Faker
}

func newFakerSource(kind string, seed uint64, targetKey, colPath string) *fakerSource {
	pcg := derivePCG(seed, targetKey, colPath, "faker", kind)
	rng := rand.New(pcg) //nolint:gosec // deterministic mock generation
	return &fakerSource{
		kind:  kind,
		rng:   rng,
		faker: gofakeit.NewFaker(derivePCG(seed, targetKey, colPath, "gofakeit", kind), false),
	}
}

func (f *fakerSource) next() engine.Value {
	switch f.kind {
	case "bool":
		return engine.Bool(f.rng.IntN(2) == 1)
	case "uuid":
		return engine.UUID(randomUUID(f.rng))
	case "object_id":
		return engine.Text(randomObjectIDHex(f.rng))
	case "json_object":
		return engine.JSON(fmt.Sprintf(`{"id":%d,"tag":%q,"active":%t}`, f.rng.IntN(10000), f.faker.Word(), f.rng.IntN(2) == 1))
	case "city":
		return engine.Text(f.faker.City())
	case "color":
		return engine.Text(f.faker.Color())
	case "company":
		return engine.Text(f.faker.Company())
	case "country":
		return engine.Text(f.faker.Country())
	case "country_code":
		return engine.Text(f.faker.CountryAbr())
	case "currency_code":
		return engine.Text(f.faker.CurrencyShort())
	case "domain":
		return engine.Text(f.faker.DomainName())
	case "email":
		return engine.Text(strings.ToLower(f.faker.Email()))
	case "first_name":
		return engine.Text(f.faker.FirstName())
	case "ipv4":
		return engine.Text(f.faker.IPv4Address())
	case "ipv6":
		return engine.Text(f.faker.IPv6Address())
	case "job_title":
		return engine.Text(f.faker.JobTitle())
	case "last_name":
		return engine.Text(f.faker.LastName())
	case "lorem":
		return engine.Text(f.faker.LoremIpsumSentence(8))
	case "name":
		return engine.Text(f.faker.Name())
	case "paragraph":
		return engine.Text(f.faker.Paragraph(1, 3, 8, " "))
	case "phone":
		return engine.Text(f.faker.Phone())
	case "product_name":
		return engine.Text(f.faker.ProductName())
	case "sentence":
		return engine.Text(f.faker.Sentence(8))
	case "state":
		return engine.Text(f.faker.State())
	case "street":
		return engine.Text(f.faker.Street())
	case "url":
		return engine.Text(f.faker.URL())
	case "user_agent":
		return engine.Text(f.faker.UserAgent())
	case "username":
		return engine.Text(f.faker.Username())
	case "word":
		return engine.Text(f.faker.Word())
	case "zip":
		return engine.Text(f.faker.Zip())
	default:
		return engine.Text(f.faker.Word())
	}
}

func randomUUID(rng *rand.Rand) string {
	var b [16]byte
	binary.LittleEndian.PutUint64(b[0:8], rng.Uint64())
	binary.LittleEndian.PutUint64(b[8:16], rng.Uint64())
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	var out [36]byte
	hex.Encode(out[0:8], b[0:4])
	out[8] = '-'
	hex.Encode(out[9:13], b[4:6])
	out[13] = '-'
	hex.Encode(out[14:18], b[6:8])
	out[18] = '-'
	hex.Encode(out[19:23], b[8:10])
	out[23] = '-'
	hex.Encode(out[24:36], b[10:16])
	return string(out[:])
}

func randomObjectIDHex(rng *rand.Rand) string {
	var b [16]byte
	binary.LittleEndian.PutUint64(b[0:8], rng.Uint64())
	binary.LittleEndian.PutUint64(b[8:16], rng.Uint64())
	return hex.EncodeToString(b[:12])
}
