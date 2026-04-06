# Bedrock Cheat Sheet for Pi

## Native Pi + Bedrock

```bash
aws sso login --profile my-bedrock
export AWS_PROFILE=my-bedrock
export AWS_REGION=eu-west-1
pi --provider amazon-bedrock --model global.anthropic.claude-sonnet-4-6
```

## Headless / loop run

```bash
AWS_PROFILE=my-bedrock AWS_REGION=eu-west-1 pi --provider amazon-bedrock    --model global.anthropic.claude-sonnet-4-6    --thinking medium    --max-turns 80    -p "Read PLAN.md and AGENTS.md, then run the loop."
```

## LiteLLM bridge

`litellm_config.yaml`

```yaml
model_list:
  - model_name: anthropic.claude-sonnet-4-6
    litellm_params:
      model: bedrock/global.anthropic.claude-sonnet-4-6
      aws_region_name: eu-west-1
```

Run:

```bash
litellm --config litellm_config.yaml
pi --provider openai --model anthropic.claude-sonnet-4-6 --base-url http://localhost:4000/v1
```

## Troubleshooting

```bash
aws sts get-caller-identity
aws configure list
aws sso login --profile my-bedrock
```

## Common gotcha

If a model ID fails, try the matching:
- cross-region inference profile ID, or
- application inference profile ARN
