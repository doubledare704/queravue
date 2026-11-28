package engine

// CheckLoadWidths rejects a batch that has a row whose width differs from the
// column list, before anything is written.
func CheckLoadWidths(engineID string, rows [][]Value, columns int) error {
	for i, row := range rows {
		if len(row) != columns {
			return Errorf(KindInvalidConfig, engineID, "load rows", "row %d has %d values for %d columns", i, len(row), columns)
		}
	}
	return nil
}
