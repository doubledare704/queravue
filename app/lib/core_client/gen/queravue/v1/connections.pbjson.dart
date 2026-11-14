// This is a generated file - do not edit.
//
// Generated from queravue/v1/connections.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use colorTagDescriptor instead')
const ColorTag$json = {
  '1': 'ColorTag',
  '2': [
    {'1': 'COLOR_TAG_UNSPECIFIED', '2': 0},
    {'1': 'COLOR_TAG_RED', '2': 1},
    {'1': 'COLOR_TAG_ORANGE', '2': 2},
    {'1': 'COLOR_TAG_YELLOW', '2': 3},
    {'1': 'COLOR_TAG_GREEN', '2': 4},
    {'1': 'COLOR_TAG_BLUE', '2': 5},
    {'1': 'COLOR_TAG_PURPLE', '2': 6},
    {'1': 'COLOR_TAG_GRAY', '2': 7},
  ],
};

/// Descriptor for `ColorTag`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List colorTagDescriptor = $convert.base64Decode(
    'CghDb2xvclRhZxIZChVDT0xPUl9UQUdfVU5TUEVDSUZJRUQQABIRCg1DT0xPUl9UQUdfUkVEEA'
    'ESFAoQQ09MT1JfVEFHX09SQU5HRRACEhQKEENPTE9SX1RBR19ZRUxMT1cQAxITCg9DT0xPUl9U'
    'QUdfR1JFRU4QBBISCg5DT0xPUl9UQUdfQkxVRRAFEhQKEENPTE9SX1RBR19QVVJQTEUQBhISCg'
    '5DT0xPUl9UQUdfR1JBWRAH');

@$core.Deprecated('Use sshAuthMethodDescriptor instead')
const SshAuthMethod$json = {
  '1': 'SshAuthMethod',
  '2': [
    {'1': 'SSH_AUTH_METHOD_UNSPECIFIED', '2': 0},
    {'1': 'SSH_AUTH_METHOD_PASSWORD', '2': 1},
    {'1': 'SSH_AUTH_METHOD_KEY_FILE', '2': 2},
    {'1': 'SSH_AUTH_METHOD_AGENT', '2': 3},
  ],
};

/// Descriptor for `SshAuthMethod`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sshAuthMethodDescriptor = $convert.base64Decode(
    'Cg1Tc2hBdXRoTWV0aG9kEh8KG1NTSF9BVVRIX01FVEhPRF9VTlNQRUNJRklFRBAAEhwKGFNTSF'
    '9BVVRIX01FVEhPRF9QQVNTV09SRBABEhwKGFNTSF9BVVRIX01FVEhPRF9LRVlfRklMRRACEhkK'
    'FVNTSF9BVVRIX01FVEhPRF9BR0VOVBAD');

@$core.Deprecated('Use tlsModeDescriptor instead')
const TlsMode$json = {
  '1': 'TlsMode',
  '2': [
    {'1': 'TLS_MODE_UNSPECIFIED', '2': 0},
    {'1': 'TLS_MODE_DISABLE', '2': 1},
    {'1': 'TLS_MODE_PREFER', '2': 2},
    {'1': 'TLS_MODE_REQUIRE', '2': 3},
    {'1': 'TLS_MODE_VERIFY_CA', '2': 4},
    {'1': 'TLS_MODE_VERIFY_FULL', '2': 5},
  ],
};

/// Descriptor for `TlsMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List tlsModeDescriptor = $convert.base64Decode(
    'CgdUbHNNb2RlEhgKFFRMU19NT0RFX1VOU1BFQ0lGSUVEEAASFAoQVExTX01PREVfRElTQUJMRR'
    'ABEhMKD1RMU19NT0RFX1BSRUZFUhACEhQKEFRMU19NT0RFX1JFUVVJUkUQAxIWChJUTFNfTU9E'
    'RV9WRVJJRllfQ0EQBBIYChRUTFNfTU9ERV9WRVJJRllfRlVMTBAF');

@$core.Deprecated('Use fieldKindDescriptor instead')
const FieldKind$json = {
  '1': 'FieldKind',
  '2': [
    {'1': 'FIELD_KIND_UNSPECIFIED', '2': 0},
    {'1': 'FIELD_KIND_TEXT', '2': 1},
    {'1': 'FIELD_KIND_INTEGER', '2': 2},
    {'1': 'FIELD_KIND_PASSWORD', '2': 3},
    {'1': 'FIELD_KIND_FILE', '2': 4},
    {'1': 'FIELD_KIND_BOOLEAN', '2': 5},
    {'1': 'FIELD_KIND_SELECT', '2': 6},
  ],
};

/// Descriptor for `FieldKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List fieldKindDescriptor = $convert.base64Decode(
    'CglGaWVsZEtpbmQSGgoWRklFTERfS0lORF9VTlNQRUNJRklFRBAAEhMKD0ZJRUxEX0tJTkRfVE'
    'VYVBABEhYKEkZJRUxEX0tJTkRfSU5URUdFUhACEhcKE0ZJRUxEX0tJTkRfUEFTU1dPUkQQAxIT'
    'Cg9GSUVMRF9LSU5EX0ZJTEUQBBIWChJGSUVMRF9LSU5EX0JPT0xFQU4QBRIVChFGSUVMRF9LSU'
    '5EX1NFTEVDVBAG');

@$core.Deprecated('Use errorKindDescriptor instead')
const ErrorKind$json = {
  '1': 'ErrorKind',
  '2': [
    {'1': 'ERROR_KIND_UNSPECIFIED', '2': 0},
    {'1': 'ERROR_KIND_AUTH', '2': 1},
    {'1': 'ERROR_KIND_NETWORK', '2': 2},
    {'1': 'ERROR_KIND_TLS', '2': 3},
    {'1': 'ERROR_KIND_NOT_FOUND', '2': 4},
    {'1': 'ERROR_KIND_TIMEOUT', '2': 5},
    {'1': 'ERROR_KIND_INVALID_CONFIG', '2': 6},
    {'1': 'ERROR_KIND_SSH_HOST_KEY_UNKNOWN', '2': 7},
    {'1': 'ERROR_KIND_SSH_HOST_KEY_CHANGED', '2': 8},
    {'1': 'ERROR_KIND_SSH_AUTH', '2': 9},
    {'1': 'ERROR_KIND_TUNNEL_LOST', '2': 10},
  ],
};

/// Descriptor for `ErrorKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List errorKindDescriptor = $convert.base64Decode(
    'CglFcnJvcktpbmQSGgoWRVJST1JfS0lORF9VTlNQRUNJRklFRBAAEhMKD0VSUk9SX0tJTkRfQV'
    'VUSBABEhYKEkVSUk9SX0tJTkRfTkVUV09SSxACEhIKDkVSUk9SX0tJTkRfVExTEAMSGAoURVJS'
    'T1JfS0lORF9OT1RfRk9VTkQQBBIWChJFUlJPUl9LSU5EX1RJTUVPVVQQBRIdChlFUlJPUl9LSU'
    '5EX0lOVkFMSURfQ09ORklHEAYSIwofRVJST1JfS0lORF9TU0hfSE9TVF9LRVlfVU5LTk9XThAH'
    'EiMKH0VSUk9SX0tJTkRfU1NIX0hPU1RfS0VZX0NIQU5HRUQQCBIXChNFUlJPUl9LSU5EX1NTSF'
    '9BVVRIEAkSGgoWRVJST1JfS0lORF9UVU5ORUxfTE9TVBAK');

@$core.Deprecated('Use testStageDescriptor instead')
const TestStage$json = {
  '1': 'TestStage',
  '2': [
    {'1': 'TEST_STAGE_UNSPECIFIED', '2': 0},
    {'1': 'TEST_STAGE_SSH', '2': 1},
    {'1': 'TEST_STAGE_TLS', '2': 2},
    {'1': 'TEST_STAGE_AUTH', '2': 3},
    {'1': 'TEST_STAGE_PING', '2': 4},
  ],
};

/// Descriptor for `TestStage`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List testStageDescriptor = $convert.base64Decode(
    'CglUZXN0U3RhZ2USGgoWVEVTVF9TVEFHRV9VTlNQRUNJRklFRBAAEhIKDlRFU1RfU1RBR0VfU1'
    'NIEAESEgoOVEVTVF9TVEFHRV9UTFMQAhITCg9URVNUX1NUQUdFX0FVVEgQAxITCg9URVNUX1NU'
    'QUdFX1BJTkcQBA==');

@$core.Deprecated('Use connectionDescriptor instead')
const Connection$json = {
  '1': 'Connection',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'engine_id', '3': 3, '4': 1, '5': 9, '10': 'engineId'},
    {
      '1': 'params',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.Connection.ParamsEntry',
      '10': 'params'
    },
    {'1': 'folder', '3': 5, '4': 1, '5': 9, '10': 'folder'},
    {
      '1': 'color',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.ColorTag',
      '10': 'color'
    },
    {'1': 'production', '3': 7, '4': 1, '5': 8, '10': 'production'},
    {'1': 'has_password', '3': 8, '4': 1, '5': 8, '10': 'hasPassword'},
    {
      '1': 'created_at',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'createdAt'
    },
    {
      '1': 'updated_at',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'updatedAt'
    },
    {
      '1': 'ssh_tunnel',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SshTunnel',
      '10': 'sshTunnel'
    },
    {
      '1': 'tls',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TlsSettings',
      '10': 'tls'
    },
  ],
  '3': [Connection_ParamsEntry$json],
};

@$core.Deprecated('Use connectionDescriptor instead')
const Connection_ParamsEntry$json = {
  '1': 'ParamsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `Connection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectionDescriptor = $convert.base64Decode(
    'CgpDb25uZWN0aW9uEg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEhsKCWVuZ2'
    'luZV9pZBgDIAEoCVIIZW5naW5lSWQSOwoGcGFyYW1zGAQgAygLMiMucXVlcmF2dWUudjEuQ29u'
    'bmVjdGlvbi5QYXJhbXNFbnRyeVIGcGFyYW1zEhYKBmZvbGRlchgFIAEoCVIGZm9sZGVyEisKBW'
    'NvbG9yGAYgASgOMhUucXVlcmF2dWUudjEuQ29sb3JUYWdSBWNvbG9yEh4KCnByb2R1Y3Rpb24Y'
    'ByABKAhSCnByb2R1Y3Rpb24SIQoMaGFzX3Bhc3N3b3JkGAggASgIUgtoYXNQYXNzd29yZBI5Cg'
    'pjcmVhdGVkX2F0GAkgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJY3JlYXRlZEF0'
    'EjkKCnVwZGF0ZWRfYXQYCiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgl1cGRhdG'
    'VkQXQSNQoKc3NoX3R1bm5lbBgLIAEoCzIWLnF1ZXJhdnVlLnYxLlNzaFR1bm5lbFIJc3NoVHVu'
    'bmVsEioKA3RscxgMIAEoCzIYLnF1ZXJhdnVlLnYxLlRsc1NldHRpbmdzUgN0bHMaOQoLUGFyYW'
    '1zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AQ==');

@$core.Deprecated('Use sshTunnelDescriptor instead')
const SshTunnel$json = {
  '1': 'SshTunnel',
  '2': [
    {'1': 'host', '3': 1, '4': 1, '5': 9, '10': 'host'},
    {'1': 'port', '3': 2, '4': 1, '5': 13, '10': 'port'},
    {'1': 'user', '3': 3, '4': 1, '5': 9, '10': 'user'},
    {
      '1': 'auth_method',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.SshAuthMethod',
      '10': 'authMethod'
    },
    {'1': 'key_file', '3': 5, '4': 1, '5': 9, '10': 'keyFile'},
    {
      '1': 'keepalive_seconds',
      '3': 6,
      '4': 1,
      '5': 13,
      '10': 'keepaliveSeconds'
    },
    {
      '1': 'connect_timeout_seconds',
      '3': 7,
      '4': 1,
      '5': 13,
      '10': 'connectTimeoutSeconds'
    },
    {
      '1': 'jump_host',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SshTunnel',
      '10': 'jumpHost'
    },
    {'1': 'has_password', '3': 9, '4': 1, '5': 8, '10': 'hasPassword'},
    {
      '1': 'has_key_passphrase',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'hasKeyPassphrase'
    },
  ],
};

/// Descriptor for `SshTunnel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sshTunnelDescriptor = $convert.base64Decode(
    'CglTc2hUdW5uZWwSEgoEaG9zdBgBIAEoCVIEaG9zdBISCgRwb3J0GAIgASgNUgRwb3J0EhIKBH'
    'VzZXIYAyABKAlSBHVzZXISOwoLYXV0aF9tZXRob2QYBCABKA4yGi5xdWVyYXZ1ZS52MS5Tc2hB'
    'dXRoTWV0aG9kUgphdXRoTWV0aG9kEhkKCGtleV9maWxlGAUgASgJUgdrZXlGaWxlEisKEWtlZX'
    'BhbGl2ZV9zZWNvbmRzGAYgASgNUhBrZWVwYWxpdmVTZWNvbmRzEjYKF2Nvbm5lY3RfdGltZW91'
    'dF9zZWNvbmRzGAcgASgNUhVjb25uZWN0VGltZW91dFNlY29uZHMSMwoJanVtcF9ob3N0GAggAS'
    'gLMhYucXVlcmF2dWUudjEuU3NoVHVubmVsUghqdW1wSG9zdBIhCgxoYXNfcGFzc3dvcmQYCSAB'
    'KAhSC2hhc1Bhc3N3b3JkEiwKEmhhc19rZXlfcGFzc3BocmFzZRgKIAEoCFIQaGFzS2V5UGFzc3'
    'BocmFzZQ==');

@$core.Deprecated('Use sshSecretsDescriptor instead')
const SshSecrets$json = {
  '1': 'SshSecrets',
  '2': [
    {
      '1': 'password',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'password',
      '17': true
    },
    {
      '1': 'key_passphrase',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'keyPassphrase',
      '17': true
    },
    {
      '1': 'jump_password',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'jumpPassword',
      '17': true
    },
    {
      '1': 'jump_key_passphrase',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'jumpKeyPassphrase',
      '17': true
    },
    {'1': 'clear', '3': 5, '4': 1, '5': 8, '10': 'clear'},
  ],
  '8': [
    {'1': '_password'},
    {'1': '_key_passphrase'},
    {'1': '_jump_password'},
    {'1': '_jump_key_passphrase'},
  ],
};

/// Descriptor for `SshSecrets`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sshSecretsDescriptor = $convert.base64Decode(
    'CgpTc2hTZWNyZXRzEh8KCHBhc3N3b3JkGAEgASgJSABSCHBhc3N3b3JkiAEBEioKDmtleV9wYX'
    'NzcGhyYXNlGAIgASgJSAFSDWtleVBhc3NwaHJhc2WIAQESKAoNanVtcF9wYXNzd29yZBgDIAEo'
    'CUgCUgxqdW1wUGFzc3dvcmSIAQESMwoTanVtcF9rZXlfcGFzc3BocmFzZRgEIAEoCUgDUhFqdW'
    '1wS2V5UGFzc3BocmFzZYgBARIUCgVjbGVhchgFIAEoCFIFY2xlYXJCCwoJX3Bhc3N3b3JkQhEK'
    'D19rZXlfcGFzc3BocmFzZUIQCg5fanVtcF9wYXNzd29yZEIWChRfanVtcF9rZXlfcGFzc3Bocm'
    'FzZQ==');

@$core.Deprecated('Use tlsSettingsDescriptor instead')
const TlsSettings$json = {
  '1': 'TlsSettings',
  '2': [
    {
      '1': 'mode',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.TlsMode',
      '10': 'mode'
    },
    {'1': 'ca_file', '3': 2, '4': 1, '5': 9, '10': 'caFile'},
    {'1': 'client_cert_file', '3': 3, '4': 1, '5': 9, '10': 'clientCertFile'},
    {'1': 'client_key_file', '3': 4, '4': 1, '5': 9, '10': 'clientKeyFile'},
    {'1': 'server_name', '3': 5, '4': 1, '5': 9, '10': 'serverName'},
    {
      '1': 'has_client_key_passphrase',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'hasClientKeyPassphrase'
    },
  ],
};

/// Descriptor for `TlsSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tlsSettingsDescriptor = $convert.base64Decode(
    'CgtUbHNTZXR0aW5ncxIoCgRtb2RlGAEgASgOMhQucXVlcmF2dWUudjEuVGxzTW9kZVIEbW9kZR'
    'IXCgdjYV9maWxlGAIgASgJUgZjYUZpbGUSKAoQY2xpZW50X2NlcnRfZmlsZRgDIAEoCVIOY2xp'
    'ZW50Q2VydEZpbGUSJgoPY2xpZW50X2tleV9maWxlGAQgASgJUg1jbGllbnRLZXlGaWxlEh8KC3'
    'NlcnZlcl9uYW1lGAUgASgJUgpzZXJ2ZXJOYW1lEjkKGWhhc19jbGllbnRfa2V5X3Bhc3NwaHJh'
    'c2UYBiABKAhSFmhhc0NsaWVudEtleVBhc3NwaHJhc2U=');

@$core.Deprecated('Use tlsSecretsDescriptor instead')
const TlsSecrets$json = {
  '1': 'TlsSecrets',
  '2': [
    {
      '1': 'client_key_passphrase',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'clientKeyPassphrase',
      '17': true
    },
    {'1': 'clear', '3': 2, '4': 1, '5': 8, '10': 'clear'},
  ],
  '8': [
    {'1': '_client_key_passphrase'},
  ],
};

/// Descriptor for `TlsSecrets`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tlsSecretsDescriptor = $convert.base64Decode(
    'CgpUbHNTZWNyZXRzEjcKFWNsaWVudF9rZXlfcGFzc3BocmFzZRgBIAEoCUgAUhNjbGllbnRLZX'
    'lQYXNzcGhyYXNliAEBEhQKBWNsZWFyGAIgASgIUgVjbGVhckIYChZfY2xpZW50X2tleV9wYXNz'
    'cGhyYXNl');

@$core.Deprecated('Use trustHostKeyRequestDescriptor instead')
const TrustHostKeyRequest$json = {
  '1': 'TrustHostKeyRequest',
  '2': [
    {'1': 'host', '3': 1, '4': 1, '5': 9, '10': 'host'},
    {'1': 'port', '3': 2, '4': 1, '5': 13, '10': 'port'},
    {
      '1': 'fingerprint_sha256',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'fingerprintSha256'
    },
  ],
};

/// Descriptor for `TrustHostKeyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trustHostKeyRequestDescriptor = $convert.base64Decode(
    'ChNUcnVzdEhvc3RLZXlSZXF1ZXN0EhIKBGhvc3QYASABKAlSBGhvc3QSEgoEcG9ydBgCIAEoDV'
    'IEcG9ydBItChJmaW5nZXJwcmludF9zaGEyNTYYAyABKAlSEWZpbmdlcnByaW50U2hhMjU2');

@$core.Deprecated('Use trustHostKeyResponseDescriptor instead')
const TrustHostKeyResponse$json = {
  '1': 'TrustHostKeyResponse',
};

/// Descriptor for `TrustHostKeyResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trustHostKeyResponseDescriptor =
    $convert.base64Decode('ChRUcnVzdEhvc3RLZXlSZXNwb25zZQ==');

@$core.Deprecated('Use fieldSpecDescriptor instead')
const FieldSpec$json = {
  '1': 'FieldSpec',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {
      '1': 'kind',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.FieldKind',
      '10': 'kind'
    },
    {'1': 'required', '3': 4, '4': 1, '5': 8, '10': 'required'},
    {'1': 'default_value', '3': 5, '4': 1, '5': 9, '10': 'defaultValue'},
    {'1': 'placeholder', '3': 6, '4': 1, '5': 9, '10': 'placeholder'},
    {'1': 'options', '3': 7, '4': 3, '5': 9, '10': 'options'},
  ],
};

/// Descriptor for `FieldSpec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldSpecDescriptor = $convert.base64Decode(
    'CglGaWVsZFNwZWMSEAoDa2V5GAEgASgJUgNrZXkSFAoFbGFiZWwYAiABKAlSBWxhYmVsEioKBG'
    'tpbmQYAyABKA4yFi5xdWVyYXZ1ZS52MS5GaWVsZEtpbmRSBGtpbmQSGgoIcmVxdWlyZWQYBCAB'
    'KAhSCHJlcXVpcmVkEiMKDWRlZmF1bHRfdmFsdWUYBSABKAlSDGRlZmF1bHRWYWx1ZRIgCgtwbG'
    'FjZWhvbGRlchgGIAEoCVILcGxhY2Vob2xkZXISGAoHb3B0aW9ucxgHIAMoCVIHb3B0aW9ucw==');

@$core.Deprecated('Use engineInfoDescriptor instead')
const EngineInfo$json = {
  '1': 'EngineInfo',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'display_name', '3': 2, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'family', '3': 3, '4': 1, '5': 9, '10': 'family'},
    {
      '1': 'fields',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.FieldSpec',
      '10': 'fields'
    },
    {'1': 'supports_uri', '3': 5, '4': 1, '5': 8, '10': 'supportsUri'},
    {'1': 'capabilities', '3': 6, '4': 3, '5': 9, '10': 'capabilities'},
    {'1': 'uri_example', '3': 7, '4': 1, '5': 9, '10': 'uriExample'},
    {'1': 'supports_ssh', '3': 8, '4': 1, '5': 8, '10': 'supportsSsh'},
    {'1': 'supports_tls', '3': 9, '4': 1, '5': 8, '10': 'supportsTls'},
  ],
};

/// Descriptor for `EngineInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List engineInfoDescriptor = $convert.base64Decode(
    'CgpFbmdpbmVJbmZvEg4KAmlkGAEgASgJUgJpZBIhCgxkaXNwbGF5X25hbWUYAiABKAlSC2Rpc3'
    'BsYXlOYW1lEhYKBmZhbWlseRgDIAEoCVIGZmFtaWx5Ei4KBmZpZWxkcxgEIAMoCzIWLnF1ZXJh'
    'dnVlLnYxLkZpZWxkU3BlY1IGZmllbGRzEiEKDHN1cHBvcnRzX3VyaRgFIAEoCFILc3VwcG9ydH'
    'NVcmkSIgoMY2FwYWJpbGl0aWVzGAYgAygJUgxjYXBhYmlsaXRpZXMSHwoLdXJpX2V4YW1wbGUY'
    'ByABKAlSCnVyaUV4YW1wbGUSIQoMc3VwcG9ydHNfc3NoGAggASgIUgtzdXBwb3J0c1NzaBIhCg'
    'xzdXBwb3J0c190bHMYCSABKAhSC3N1cHBvcnRzVGxz');

@$core.Deprecated('Use serverInfoDescriptor instead')
const ServerInfo$json = {
  '1': 'ServerInfo',
  '2': [
    {'1': 'product', '3': 1, '4': 1, '5': 9, '10': 'product'},
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
    {'1': 'banner', '3': 3, '4': 1, '5': 9, '10': 'banner'},
  ],
};

/// Descriptor for `ServerInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverInfoDescriptor = $convert.base64Decode(
    'CgpTZXJ2ZXJJbmZvEhgKB3Byb2R1Y3QYASABKAlSB3Byb2R1Y3QSGAoHdmVyc2lvbhgCIAEoCV'
    'IHdmVyc2lvbhIWCgZiYW5uZXIYAyABKAlSBmJhbm5lcg==');

@$core.Deprecated('Use connectionErrorDescriptor instead')
const ConnectionError$json = {
  '1': 'ConnectionError',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.ErrorKind',
      '10': 'kind'
    },
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'ssh_host', '3': 3, '4': 1, '5': 9, '10': 'sshHost'},
    {
      '1': 'ssh_fingerprint_sha256',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'sshFingerprintSha256'
    },
    {
      '1': 'ssh_trusted_fingerprint_sha256',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'sshTrustedFingerprintSha256'
    },
  ],
};

/// Descriptor for `ConnectionError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectionErrorDescriptor = $convert.base64Decode(
    'Cg9Db25uZWN0aW9uRXJyb3ISKgoEa2luZBgBIAEoDjIWLnF1ZXJhdnVlLnYxLkVycm9yS2luZF'
    'IEa2luZBIYCgdtZXNzYWdlGAIgASgJUgdtZXNzYWdlEhkKCHNzaF9ob3N0GAMgASgJUgdzc2hI'
    'b3N0EjQKFnNzaF9maW5nZXJwcmludF9zaGEyNTYYBCABKAlSFHNzaEZpbmdlcnByaW50U2hhMj'
    'U2EkMKHnNzaF90cnVzdGVkX2ZpbmdlcnByaW50X3NoYTI1NhgFIAEoCVIbc3NoVHJ1c3RlZEZp'
    'bmdlcnByaW50U2hhMjU2');

@$core.Deprecated('Use listEnginesRequestDescriptor instead')
const ListEnginesRequest$json = {
  '1': 'ListEnginesRequest',
};

/// Descriptor for `ListEnginesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listEnginesRequestDescriptor =
    $convert.base64Decode('ChJMaXN0RW5naW5lc1JlcXVlc3Q=');

@$core.Deprecated('Use listEnginesResponseDescriptor instead')
const ListEnginesResponse$json = {
  '1': 'ListEnginesResponse',
  '2': [
    {
      '1': 'engines',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.EngineInfo',
      '10': 'engines'
    },
  ],
};

/// Descriptor for `ListEnginesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listEnginesResponseDescriptor = $convert.base64Decode(
    'ChNMaXN0RW5naW5lc1Jlc3BvbnNlEjEKB2VuZ2luZXMYASADKAsyFy5xdWVyYXZ1ZS52MS5Fbm'
    'dpbmVJbmZvUgdlbmdpbmVz');

@$core.Deprecated('Use listConnectionsRequestDescriptor instead')
const ListConnectionsRequest$json = {
  '1': 'ListConnectionsRequest',
};

/// Descriptor for `ListConnectionsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listConnectionsRequestDescriptor =
    $convert.base64Decode('ChZMaXN0Q29ubmVjdGlvbnNSZXF1ZXN0');

@$core.Deprecated('Use listConnectionsResponseDescriptor instead')
const ListConnectionsResponse$json = {
  '1': 'ListConnectionsResponse',
  '2': [
    {
      '1': 'connections',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.Connection',
      '10': 'connections'
    },
  ],
};

/// Descriptor for `ListConnectionsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listConnectionsResponseDescriptor =
    $convert.base64Decode(
        'ChdMaXN0Q29ubmVjdGlvbnNSZXNwb25zZRI5Cgtjb25uZWN0aW9ucxgBIAMoCzIXLnF1ZXJhdn'
        'VlLnYxLkNvbm5lY3Rpb25SC2Nvbm5lY3Rpb25z');

@$core.Deprecated('Use getConnectionRequestDescriptor instead')
const GetConnectionRequest$json = {
  '1': 'GetConnectionRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `GetConnectionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getConnectionRequestDescriptor = $convert
    .base64Decode('ChRHZXRDb25uZWN0aW9uUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQ=');

@$core.Deprecated('Use getConnectionResponseDescriptor instead')
const GetConnectionResponse$json = {
  '1': 'GetConnectionResponse',
  '2': [
    {
      '1': 'connection',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.Connection',
      '10': 'connection'
    },
  ],
};

/// Descriptor for `GetConnectionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getConnectionResponseDescriptor = $convert.base64Decode(
    'ChVHZXRDb25uZWN0aW9uUmVzcG9uc2USNwoKY29ubmVjdGlvbhgBIAEoCzIXLnF1ZXJhdnVlLn'
    'YxLkNvbm5lY3Rpb25SCmNvbm5lY3Rpb24=');

@$core.Deprecated('Use createConnectionRequestDescriptor instead')
const CreateConnectionRequest$json = {
  '1': 'CreateConnectionRequest',
  '2': [
    {
      '1': 'connection',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.Connection',
      '10': 'connection'
    },
    {
      '1': 'password',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'password',
      '17': true
    },
    {
      '1': 'ssh_secrets',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SshSecrets',
      '10': 'sshSecrets'
    },
    {
      '1': 'tls_secrets',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TlsSecrets',
      '10': 'tlsSecrets'
    },
  ],
  '8': [
    {'1': '_password'},
  ],
};

/// Descriptor for `CreateConnectionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createConnectionRequestDescriptor = $convert.base64Decode(
    'ChdDcmVhdGVDb25uZWN0aW9uUmVxdWVzdBI3Cgpjb25uZWN0aW9uGAEgASgLMhcucXVlcmF2dW'
    'UudjEuQ29ubmVjdGlvblIKY29ubmVjdGlvbhIfCghwYXNzd29yZBgCIAEoCUgAUghwYXNzd29y'
    'ZIgBARI4Cgtzc2hfc2VjcmV0cxgDIAEoCzIXLnF1ZXJhdnVlLnYxLlNzaFNlY3JldHNSCnNzaF'
    'NlY3JldHMSOAoLdGxzX3NlY3JldHMYBCABKAsyFy5xdWVyYXZ1ZS52MS5UbHNTZWNyZXRzUgp0'
    'bHNTZWNyZXRzQgsKCV9wYXNzd29yZA==');

@$core.Deprecated('Use createConnectionResponseDescriptor instead')
const CreateConnectionResponse$json = {
  '1': 'CreateConnectionResponse',
  '2': [
    {
      '1': 'connection',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.Connection',
      '10': 'connection'
    },
  ],
};

/// Descriptor for `CreateConnectionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createConnectionResponseDescriptor =
    $convert.base64Decode(
        'ChhDcmVhdGVDb25uZWN0aW9uUmVzcG9uc2USNwoKY29ubmVjdGlvbhgBIAEoCzIXLnF1ZXJhdn'
        'VlLnYxLkNvbm5lY3Rpb25SCmNvbm5lY3Rpb24=');

@$core.Deprecated('Use updateConnectionRequestDescriptor instead')
const UpdateConnectionRequest$json = {
  '1': 'UpdateConnectionRequest',
  '2': [
    {
      '1': 'connection',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.Connection',
      '10': 'connection'
    },
    {
      '1': 'password',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'password',
      '17': true
    },
    {'1': 'clear_password', '3': 3, '4': 1, '5': 8, '10': 'clearPassword'},
    {
      '1': 'ssh_secrets',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SshSecrets',
      '10': 'sshSecrets'
    },
    {
      '1': 'tls_secrets',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TlsSecrets',
      '10': 'tlsSecrets'
    },
  ],
  '8': [
    {'1': '_password'},
  ],
};

/// Descriptor for `UpdateConnectionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateConnectionRequestDescriptor = $convert.base64Decode(
    'ChdVcGRhdGVDb25uZWN0aW9uUmVxdWVzdBI3Cgpjb25uZWN0aW9uGAEgASgLMhcucXVlcmF2dW'
    'UudjEuQ29ubmVjdGlvblIKY29ubmVjdGlvbhIfCghwYXNzd29yZBgCIAEoCUgAUghwYXNzd29y'
    'ZIgBARIlCg5jbGVhcl9wYXNzd29yZBgDIAEoCFINY2xlYXJQYXNzd29yZBI4Cgtzc2hfc2Vjcm'
    'V0cxgEIAEoCzIXLnF1ZXJhdnVlLnYxLlNzaFNlY3JldHNSCnNzaFNlY3JldHMSOAoLdGxzX3Nl'
    'Y3JldHMYBSABKAsyFy5xdWVyYXZ1ZS52MS5UbHNTZWNyZXRzUgp0bHNTZWNyZXRzQgsKCV9wYX'
    'Nzd29yZA==');

@$core.Deprecated('Use updateConnectionResponseDescriptor instead')
const UpdateConnectionResponse$json = {
  '1': 'UpdateConnectionResponse',
  '2': [
    {
      '1': 'connection',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.Connection',
      '10': 'connection'
    },
  ],
};

/// Descriptor for `UpdateConnectionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateConnectionResponseDescriptor =
    $convert.base64Decode(
        'ChhVcGRhdGVDb25uZWN0aW9uUmVzcG9uc2USNwoKY29ubmVjdGlvbhgBIAEoCzIXLnF1ZXJhdn'
        'VlLnYxLkNvbm5lY3Rpb25SCmNvbm5lY3Rpb24=');

@$core.Deprecated('Use deleteConnectionRequestDescriptor instead')
const DeleteConnectionRequest$json = {
  '1': 'DeleteConnectionRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `DeleteConnectionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteConnectionRequestDescriptor = $convert
    .base64Decode('ChdEZWxldGVDb25uZWN0aW9uUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQ=');

@$core.Deprecated('Use deleteConnectionResponseDescriptor instead')
const DeleteConnectionResponse$json = {
  '1': 'DeleteConnectionResponse',
};

/// Descriptor for `DeleteConnectionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteConnectionResponseDescriptor =
    $convert.base64Decode('ChhEZWxldGVDb25uZWN0aW9uUmVzcG9uc2U=');

@$core.Deprecated('Use testConnectionRequestDescriptor instead')
const TestConnectionRequest$json = {
  '1': 'TestConnectionRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'draft',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.Connection',
      '10': 'draft'
    },
    {
      '1': 'password',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'password',
      '17': true
    },
    {'1': 'timeout_ms', '3': 4, '4': 1, '5': 13, '10': 'timeoutMs'},
    {
      '1': 'ssh_secrets',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.SshSecrets',
      '10': 'sshSecrets'
    },
    {
      '1': 'tls_secrets',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.TlsSecrets',
      '10': 'tlsSecrets'
    },
  ],
  '8': [
    {'1': '_password'},
  ],
};

/// Descriptor for `TestConnectionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testConnectionRequestDescriptor = $convert.base64Decode(
    'ChVUZXN0Q29ubmVjdGlvblJlcXVlc3QSDgoCaWQYASABKAlSAmlkEi0KBWRyYWZ0GAIgASgLMh'
    'cucXVlcmF2dWUudjEuQ29ubmVjdGlvblIFZHJhZnQSHwoIcGFzc3dvcmQYAyABKAlIAFIIcGFz'
    'c3dvcmSIAQESHQoKdGltZW91dF9tcxgEIAEoDVIJdGltZW91dE1zEjgKC3NzaF9zZWNyZXRzGA'
    'UgASgLMhcucXVlcmF2dWUudjEuU3NoU2VjcmV0c1IKc3NoU2VjcmV0cxI4Cgt0bHNfc2VjcmV0'
    'cxgGIAEoCzIXLnF1ZXJhdnVlLnYxLlRsc1NlY3JldHNSCnRsc1NlY3JldHNCCwoJX3Bhc3N3b3'
    'Jk');

@$core.Deprecated('Use testConnectionResponseDescriptor instead')
const TestConnectionResponse$json = {
  '1': 'TestConnectionResponse',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
    {
      '1': 'server',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ServerInfo',
      '10': 'server'
    },
    {'1': 'connect_ms', '3': 3, '4': 1, '5': 13, '10': 'connectMs'},
    {'1': 'latency_ms', '3': 4, '4': 1, '5': 13, '10': 'latencyMs'},
    {
      '1': 'error',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ConnectionError',
      '10': 'error'
    },
    {
      '1': 'steps',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.TestStep',
      '10': 'steps'
    },
  ],
};

/// Descriptor for `TestConnectionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testConnectionResponseDescriptor = $convert.base64Decode(
    'ChZUZXN0Q29ubmVjdGlvblJlc3BvbnNlEg4KAm9rGAEgASgIUgJvaxIvCgZzZXJ2ZXIYAiABKA'
    'syFy5xdWVyYXZ1ZS52MS5TZXJ2ZXJJbmZvUgZzZXJ2ZXISHQoKY29ubmVjdF9tcxgDIAEoDVIJ'
    'Y29ubmVjdE1zEh0KCmxhdGVuY3lfbXMYBCABKA1SCWxhdGVuY3lNcxIyCgVlcnJvchgFIAEoCz'
    'IcLnF1ZXJhdnVlLnYxLkNvbm5lY3Rpb25FcnJvclIFZXJyb3ISKwoFc3RlcHMYBiADKAsyFS5x'
    'dWVyYXZ1ZS52MS5UZXN0U3RlcFIFc3RlcHM=');

@$core.Deprecated('Use testStepDescriptor instead')
const TestStep$json = {
  '1': 'TestStep',
  '2': [
    {
      '1': 'stage',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.queravue.v1.TestStage',
      '10': 'stage'
    },
    {'1': 'ok', '3': 2, '4': 1, '5': 8, '10': 'ok'},
    {'1': 'elapsed_ms', '3': 3, '4': 1, '5': 13, '10': 'elapsedMs'},
    {
      '1': 'error',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.queravue.v1.ConnectionError',
      '10': 'error'
    },
  ],
};

/// Descriptor for `TestStep`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testStepDescriptor = $convert.base64Decode(
    'CghUZXN0U3RlcBIsCgVzdGFnZRgBIAEoDjIWLnF1ZXJhdnVlLnYxLlRlc3RTdGFnZVIFc3RhZ2'
    'USDgoCb2sYAiABKAhSAm9rEh0KCmVsYXBzZWRfbXMYAyABKA1SCWVsYXBzZWRNcxIyCgVlcnJv'
    'chgEIAEoCzIcLnF1ZXJhdnVlLnYxLkNvbm5lY3Rpb25FcnJvclIFZXJyb3I=');

@$core.Deprecated('Use parseConnectionStringRequestDescriptor instead')
const ParseConnectionStringRequest$json = {
  '1': 'ParseConnectionStringRequest',
  '2': [
    {'1': 'engine_id', '3': 1, '4': 1, '5': 9, '10': 'engineId'},
    {
      '1': 'connection_string',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'connectionString'
    },
  ],
};

/// Descriptor for `ParseConnectionStringRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parseConnectionStringRequestDescriptor =
    $convert.base64Decode(
        'ChxQYXJzZUNvbm5lY3Rpb25TdHJpbmdSZXF1ZXN0EhsKCWVuZ2luZV9pZBgBIAEoCVIIZW5naW'
        '5lSWQSKwoRY29ubmVjdGlvbl9zdHJpbmcYAiABKAlSEGNvbm5lY3Rpb25TdHJpbmc=');

@$core.Deprecated('Use parseConnectionStringResponseDescriptor instead')
const ParseConnectionStringResponse$json = {
  '1': 'ParseConnectionStringResponse',
  '2': [
    {
      '1': 'params',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.queravue.v1.ParseConnectionStringResponse.ParamsEntry',
      '10': 'params'
    },
    {
      '1': 'password',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'password',
      '17': true
    },
  ],
  '3': [ParseConnectionStringResponse_ParamsEntry$json],
  '8': [
    {'1': '_password'},
  ],
};

@$core.Deprecated('Use parseConnectionStringResponseDescriptor instead')
const ParseConnectionStringResponse_ParamsEntry$json = {
  '1': 'ParamsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `ParseConnectionStringResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parseConnectionStringResponseDescriptor = $convert.base64Decode(
    'Ch1QYXJzZUNvbm5lY3Rpb25TdHJpbmdSZXNwb25zZRJOCgZwYXJhbXMYASADKAsyNi5xdWVyYX'
    'Z1ZS52MS5QYXJzZUNvbm5lY3Rpb25TdHJpbmdSZXNwb25zZS5QYXJhbXNFbnRyeVIGcGFyYW1z'
    'Eh8KCHBhc3N3b3JkGAIgASgJSABSCHBhc3N3b3JkiAEBGjkKC1BhcmFtc0VudHJ5EhAKA2tleR'
    'gBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAFCCwoJX3Bhc3N3b3Jk');
