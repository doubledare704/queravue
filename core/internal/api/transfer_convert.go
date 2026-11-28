package api

import (
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/transfer"
)

var transferFormats = map[queravuev1.TransferFormat]transfer.Format{
	queravuev1.TransferFormat_TRANSFER_FORMAT_CSV:     transfer.CSV,
	queravuev1.TransferFormat_TRANSFER_FORMAT_TSV:     transfer.TSV,
	queravuev1.TransferFormat_TRANSFER_FORMAT_JSON:    transfer.JSON,
	queravuev1.TransferFormat_TRANSFER_FORMAT_NDJSON:  transfer.NDJSON,
	queravuev1.TransferFormat_TRANSFER_FORMAT_SQL:     transfer.SQL,
	queravuev1.TransferFormat_TRANSFER_FORMAT_PARQUET: transfer.Parquet,
}

func formatFromProto(f queravuev1.TransferFormat) (transfer.Format, bool) {
	out, ok := transferFormats[f]
	return out, ok
}

func formatToProto(f transfer.Format) queravuev1.TransferFormat {
	for p, v := range transferFormats {
		if v == f {
			return p
		}
	}
	return queravuev1.TransferFormat_TRANSFER_FORMAT_UNSPECIFIED
}

func optionsFromProto(o *queravuev1.TransferFormatOptions) transfer.Options {
	return transfer.Options{
		Delimiter: o.GetDelimiter(), Quote: o.GetQuote(), Header: o.GetHeader(), NullText: o.GetNullText(),
		CanonicalJSON: o.GetJsonFlavor() == queravuev1.JsonFlavor_JSON_FLAVOR_CANONICAL,
		SQLIncludeDDL: o.GetSqlIncludeDdl(), SQLTable: o.GetSqlTargetTable(),
	}
}

func optionsToProto(o transfer.Options) *queravuev1.TransferFormatOptions {
	flavor := queravuev1.JsonFlavor_JSON_FLAVOR_RELAXED
	if o.CanonicalJSON {
		flavor = queravuev1.JsonFlavor_JSON_FLAVOR_CANONICAL
	}
	return &queravuev1.TransferFormatOptions{
		Delimiter: o.Delimiter, Quote: o.Quote, Header: o.Header, NullText: o.NullText, JsonFlavor: flavor,
		SqlIncludeDdl: o.SQLIncludeDDL, SqlTargetTable: o.SQLTable,
	}
}

var transferErrorKinds = map[transfer.ErrorKind]queravuev1.TransferErrorKind{
	transfer.KindParse:                queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_PARSE,
	transfer.KindMapping:              queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_MAPPING,
	transfer.KindConstraint:           queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_CONSTRAINT,
	transfer.KindConfirmationRequired: queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_CONFIRMATION_REQUIRED,
	transfer.KindAuth:                 queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_AUTH,
	transfer.KindNetwork:              queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_NETWORK,
	transfer.KindTimeout:              queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_TIMEOUT,
	transfer.KindCanceled:             queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_CANCELED,
	transfer.KindUnsupported:          queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_UNSUPPORTED,
	transfer.KindServer:               queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_SERVER,
}

func transferErrorToProto(err error) *queravuev1.TransferError {
	typed := transfer.Classify(err)
	return &queravuev1.TransferError{Kind: transferErrorKinds[typed.Kind], Message: typed.Message}
}

var engineKindsOfProto = map[queravuev1.ValueKind]engine.ValueKind{
	queravuev1.ValueKind_VALUE_KIND_BOOL:        engine.VBool,
	queravuev1.ValueKind_VALUE_KIND_INT:         engine.VInt,
	queravuev1.ValueKind_VALUE_KIND_FLOAT:       engine.VFloat,
	queravuev1.ValueKind_VALUE_KIND_DECIMAL:     engine.VDecimal,
	queravuev1.ValueKind_VALUE_KIND_TEXT:        engine.VText,
	queravuev1.ValueKind_VALUE_KIND_BYTES:       engine.VBytes,
	queravuev1.ValueKind_VALUE_KIND_TIMESTAMPTZ: engine.VTimestamptz,
	queravuev1.ValueKind_VALUE_KIND_JSON:        engine.VJSON,
	queravuev1.ValueKind_VALUE_KIND_UUID:        engine.VUUID,
	queravuev1.ValueKind_VALUE_KIND_ARRAY:       engine.VArray,
}

func engineKindOfProto(k queravuev1.ValueKind) engine.ValueKind {
	if out, ok := engineKindsOfProto[k]; ok {
		return out
	}
	return engine.VText
}

func engineColumnsOfProto(cols []*queravuev1.Column) []engine.Column {
	out := make([]engine.Column, len(cols))
	for i, c := range cols {
		out[i] = engine.Column{Name: c.GetName(), TypeName: c.GetTypeName(), Kind: engineKindOfProto(c.GetKind())}
	}
	return out
}
