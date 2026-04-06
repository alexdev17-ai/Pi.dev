# Pi + Amazon Bedrock Setup and Examples

This addendum extends the Pi knowledge base with Bedrock-specific guidance so the bundle can be used in environments where Claude is accessed through AWS rather than directly through Anthropic.

## What is supported

Pi's underlying `@mariozechner/pi-ai` library lists **Amazon Bedrock** as a supported provider and maps it to the **Bedrock Converse streaming API** (`bedrock-converse-stream`). Pi/OpenClaw Bedrock docs also describe the provider name as `amazon-bedrock`, and note that authentication uses the **AWS SDK default credential chain**, not an API key.

In practice, that means Pi can talk to Claude on Bedrock in three ways:

1. **Native Bedrock provider** — preferred when your Pi build exposes `amazon-bedrock` directly.
2. **LiteLLM proxy** — useful when you want a stable OpenAI-compatible endpoint or centralised routing.
3. **Custom provider / internal gateway** — best for enterprise setups with a company gateway in front of Bedrock.

## Native Bedrock setup

### Install Pi

```bash
npm install -g @mariozechner/pi-coding-agent
```

### Confirm Bedrock-capable pi-ai is present

```bash
npx @mariozechner/pi-ai list
```

Look for either:
- provider: `amazon-bedrock`
- API: `bedrock-converse-stream`

### Authenticate with AWS credentials

Bedrock uses the AWS credential chain. Typical options:

#### Option A: AWS CLI profile

```bash
aws configure
export AWS_PROFILE=default
export AWS_REGION=eu-west-1
```

#### Option B: AWS SSO

```bash
aws configure sso
aws sso login --profile my-bedrock
export AWS_PROFILE=my-bedrock
export AWS_REGION=eu-west-1
```

#### Option C: Environment credentials

```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...   # if temporary creds
export AWS_REGION=eu-west-1
```

#### Option D: Instance / container role

Run Pi on an EC2 instance, ECS task, or other environment with an attached IAM role that can invoke Bedrock.

### Start Pi against Bedrock

```bash
pi --provider amazon-bedrock --model us.anthropic.claude-sonnet-4-6
```

If your account requires application inference profiles instead of raw model IDs, use the profile ID or ARN instead of the plain Claude model name.

Examples:

```bash
pi --provider amazon-bedrock --model us.anthropic.claude-haiku-4-5-20251001-v1:0
pi --provider amazon-bedrock --model global.anthropic.claude-sonnet-4-6
pi --provider amazon-bedrock --model arn:aws:bedrock:us-east-2:123456789012:application-inference-profile/my-sonnet-profile
```

## IAM requirements

At minimum, the calling identity needs permission to invoke the relevant Bedrock model or inference profile. In many orgs this means access to:

- `bedrock:InvokeModel`
- `bedrock:InvokeModelWithResponseStream`
- any profile-specific Bedrock actions required by your org's policy model

In practice, many teams scope permissions to specific model IDs or application inference profile ARNs.

## Bedrock model IDs vs inference profiles

This is the most common setup mistake.

On Bedrock, some Claude models are accessed using **inference profile IDs** rather than the raw model ID. AWS docs and third-party Bedrock tooling both call out that some newer Anthropic models require cross-region inference profile IDs such as:

```text
us.anthropic.claude-3-7-sonnet-20250219-v1:0
```

Claude Code Bedrock docs also show the same pattern for modern Claude models, including `global.anthropic.claude-sonnet-4-6` and application inference profile ARNs.

**Rule of thumb:** if a plain model ID fails with an on-demand throughput or routing error, try the matching inference profile ID or your org's application inference profile ARN.

## Pi settings example for Bedrock

Create `~/.pi/settings.json` or project-local `.pi/settings.json`:

```json
{
  "defaultProvider": "amazon-bedrock",
  "defaultModel": "global.anthropic.claude-sonnet-4-6",
  "thinkingEnabled": true,
  "thinkingBudget": "medium"
}
```

Then run plain `pi` in that environment.

## Ralph loop on Bedrock

Pi can run the same Ralph-style loop on Bedrock as long as the selected Bedrock Claude model supports tool use and sufficient context.

Example:

```bash
pi   --provider amazon-bedrock   --model global.anthropic.claude-sonnet-4-6   --thinking medium   --max-turns 80   -p "Read PLAN.md and AGENTS.md, then run the Ralph loop."
```

This is especially useful in organisations where all Claude usage must stay inside AWS billing, IAM, networking, and audit controls.

## LiteLLM fallback / proxy pattern

If native Bedrock setup in Pi is awkward, use LiteLLM as a bridge and point Pi at the proxy as an OpenAI-compatible endpoint.

### Example `litellm_config.yaml`

```yaml
model_list:
  - model_name: anthropic.claude-sonnet-4-6
    litellm_params:
      model: bedrock/global.anthropic.claude-sonnet-4-6
      aws_region_name: eu-west-1
```

### Start LiteLLM

```bash
litellm --config litellm_config.yaml
```

### Point Pi to the proxy

```bash
pi   --provider openai   --model anthropic.claude-sonnet-4-6   --base-url http://localhost:4000/v1
```

Why use this route:
- unified endpoint for multiple backends
- easy rate limits and logging
- central model routing for a team
- smoother integration when a tool expects OpenAI-compatible APIs

Trade-offs:
- one more moving part
- proxy compatibility quirks
- harder debugging when something fails between Pi and Bedrock

## Custom gateway pattern

Pi's provider system can also be used behind an internal company gateway. This is often the cleanest enterprise pattern:

```typescript
// sketch only
export default function (pi) {
  pi.registerProvider({
    name: 'company-bedrock',
    baseUrl: 'https://llm-gateway.company.com/v1',
    headers: {
      'Authorization': `Bearer ${process.env.LLM_GATEWAY_TOKEN}`,
      'x-aws-region': 'eu-west-1'
    }
  });
}
```

Use this when your security team wants all model traffic to go through one auditable service.

## Everyday workflows with Bedrock

### 1. Corporate coding environments

Use Pi + Bedrock when:
- direct Anthropic API access is blocked
- IAM / SSO is mandatory
- cost allocation must stay in AWS accounts
- traffic must stay within enterprise AWS controls

### 2. Claude Code + Pi hybrid

A strong pattern is:
1. Use Claude Code on Bedrock for planning, MCP-heavy exploration, or scheduled tasks.
2. Use Pi on Bedrock for long-running file-and-shell execution loops.
3. Keep `PLAN.md`, `AGENTS.md`, and repo-local logs as the shared source of truth.

### 3. Non-coding tasks

Bedrock-backed Pi is also useful for:
- markdown knowledge base maintenance
- runbook generation from logs and notes
- incident timeline drafting
- weekly summaries from git logs, notes, and task files

The core pattern is unchanged: files as state, shell commands for extraction, and Markdown as the durable output.

## Common pitfalls

### Bedrock is not browser-safe in pi-ai

Pi's underlying library documents that Bedrock is **not supported in browser environments**. It works in Node/server environments only.

### Wrong credential source

If Pi cannot authenticate, verify:
- `AWS_PROFILE`
- `AWS_REGION` / `AWS_DEFAULT_REGION`
- `aws sts get-caller-identity`
- `aws bedrock-runtime` access in the target account

### Wrong model identifier

If requests fail immediately, test whether you should be using:
- raw model ID
- cross-region inference profile ID
- application inference profile ARN

### Corporate SSO expiry

If your org uses AWS SSO, Bedrock failures are often just expired SSO credentials. Re-run:

```bash
aws sso login --profile my-bedrock
```

## Quick verification checklist

Run these before blaming Pi:

```bash
aws sts get-caller-identity
aws configure list
```

Then launch Pi with explicit settings:

```bash
AWS_PROFILE=my-bedrock AWS_REGION=eu-west-1 pi --provider amazon-bedrock --model global.anthropic.claude-sonnet-4-6
```

## Recommended additions to the existing knowledge-base docs

### Add to the Claude integration document

Insert a new section:

- **Bedrock provider**
  - Provider name: `amazon-bedrock`
  - Auth: AWS SDK default credential chain
  - API: Bedrock Converse streaming
  - Works well for AWS-controlled enterprise environments

### Add to the decision framework

Add a Bedrock-specific note:

- If your organisation standardises on AWS IAM/SSO and internal cost allocation, Pi on Bedrock becomes more attractive than direct Anthropic API usage.
- If you want the smoothest official Bedrock UX today, Claude Code on Bedrock is still more turnkey than Pi.

### Add to the Ralph loop document

Add a deployment variant:

- Run the same Ralph loop with `--provider amazon-bedrock`
- Prefer inference profile IDs / ARNs if plain model IDs fail
- Re-authentication steps for AWS SSO should be part of the operator runbook

## Source notes

Primary source categories used for this addendum:
- `@mariozechner/pi-ai` README and package docs
- Claude Code Bedrock docs
- AWS Bedrock Claude/model docs
- OpenClaw Bedrock docs describing Pi/OpenClaw use of Bedrock via pi-ai
