# Hardware-Adaptive Model Quantization

Haven 42 treats quantization as an evidence-bound model lifecycle, not a bit-count shortcut. The preferred result is a trusted compatible pre-quantized artifact. Local conversion is proposed only when no trustworthy compatible artifact exists and the exact runtime, hardware, license, storage, and quality gates can be satisfied.

## Contracts

- `config/quantization-plan-contract.json` defines dry-run decisions: `existing-artifact`, `local-derivative`, or `no-safe-recommendation`.
- `config/quantized-artifact-manifest-contract.json` records immutable source identity, input and output hashes, pinned tools, the full recipe, runtime compatibility, exact evidence scope, activation, rollback, and cleanup state.
- `config/quantization-support-matrix.json` defines candidate format/runtime boundaries. It deliberately does not claim that equal bit counts or different accelerators are interchangeable.

Source weights and derivatives stay outside the application and repository. A conversion never overwrites its source. Moving branches, missing hashes, unknown licenses, unapproved calibration material, unsupported kernels, silent CPU fallback, and inadequate temporary storage all produce `no-safe-recommendation`.

## Planning Inputs

The local-only hardware profile must include operating system and architecture, accelerator vendor/model/runtime, usable dedicated or unified memory, system memory, CPU instruction support, driver/runtime versions, available storage, target context, concurrency, and workload lane. Hostnames, IP addresses, usernames, endpoints, serial numbers, local paths, and model files are not committed.

## Consent And Provenance

Before download or conversion, disclose immutable source, license and derivative rights, published hashes, download size, temporary and final storage, estimated memory and compute time, network use, calibration provenance/privacy, cleanup, and rollback. Private repositories, prompts, conversations, and user documents are not calibration data by default.

## Comparative Promotion Gates

Compare the candidate with its source or trusted baseline for cold-load time, first-token latency, token throughput, peak accelerator and system memory, disk use, accelerator confirmation, context stability, and concurrency. Quality checks cover general chat, summarization, tool calls, read-only engineering, and approved-write reliability when that lane is intended. A speed or memory improvement cannot compensate for unacceptable quality loss or malformed tool behavior.

Each model revision, recipe, runtime version, operating system, accelerator, context target, and operation is a separate evidence cell. Failed candidates leave a sanitized decision record only and ship no conversion harness, runtime configuration, artifact, or active catalog entry.

## Local Dry Run

Generate a local-only profile without contacting a model endpoint:

```powershell
.\scripts\get-quantization-profile.ps1 -ContextTokens 16384 -Concurrency 1 -WorkloadLane tool-use > quantization-profile.local.json
```

```bash
./scripts/get-quantization-profile.linux.sh --context-tokens 16384 --concurrency 1 --workload-lane tool-use > quantization-profile.local.json
```

The macOS wrapper has the same arguments. The profile contains useful hardware values, so keep it local even though it omits hostnames, addresses, usernames, serial numbers, endpoints, and paths.

Create a local request JSON containing `source`, `target`, `hardwareProfile`, optional `trustedArtifacts`, `storageEstimate`, and disclosures, then evaluate it without effects:

```powershell
.\scripts\plan-model-quantization.ps1 -RequestPath quantization-request.local.json
```

```bash
./scripts/plan-model-quantization.linux.sh --request quantization-request.local.json
```

The result always reports `network`, `downloads`, `writes`, `conversion`, and `activation` as false. A `local-derivative` result is only a proposal for a later approved and independently validated workflow.
