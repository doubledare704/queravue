package mockdata

import (
	"crypto/sha256"
	"encoding/binary"
	"math/rand/v2"
)

func deriveSeeds(seed uint64, parts ...string) (uint64, uint64) {
	h := sha256.New()
	var buf [8]byte
	binary.LittleEndian.PutUint64(buf[:], seed)
	_, _ = h.Write(buf[:])
	for _, p := range parts {
		binary.LittleEndian.PutUint64(buf[:], uint64(len(p)))
		_, _ = h.Write(buf[:])
		_, _ = h.Write([]byte(p))
	}
	sum := h.Sum(nil)
	return binary.LittleEndian.Uint64(sum[:8]), binary.LittleEndian.Uint64(sum[8:16])
}

func derivePCG(seed uint64, parts ...string) *rand.PCG {
	s1, s2 := deriveSeeds(seed, parts...)
	return rand.NewPCG(s1, s2)
}

func deriveRNG(seed uint64, parts ...string) *rand.Rand {
	return rand.New(derivePCG(seed, parts...)) //nolint:gosec // mock data generation does not require cryptographic randomness
}
