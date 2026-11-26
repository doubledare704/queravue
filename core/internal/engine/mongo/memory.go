package mongo

import (
	"runtime/debug"
	"sync"
	"time"
)

const reclaimTransferThreshold = 32 << 20

var memoryRelease struct {
	sync.Mutex
	timer      *time.Timer
	generation uint64
}

func scheduleMemoryRelease() {
	memoryRelease.Lock()
	defer memoryRelease.Unlock()
	memoryRelease.generation++
	generation := memoryRelease.generation
	if memoryRelease.timer != nil {
		memoryRelease.timer.Stop()
	}
	memoryRelease.timer = time.AfterFunc(5*time.Second, func() {
		memoryRelease.Lock()
		if generation != memoryRelease.generation {
			memoryRelease.Unlock()
			return
		}
		memoryRelease.timer = nil
		memoryRelease.Unlock()
		debug.FreeOSMemory()
	})
}
