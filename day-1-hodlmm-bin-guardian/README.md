# Day 1 — [AIBTC Skills Comp Day 1] HODLMM Bin Guardian
> **Original PR:** https://github.com/BitflowFinance/bff-skills/pull/15

## Skill Name                                                                                                                                    hodlmm-bin-guardian

  ## Category                                                                                                                                      - [x] Yield
                                                                                                                                                   ## What it does
  Autonomous HODLMM bin range monitor for Bitflow LP positions. Fetches live pool state and sBTC/STX ticker via Bitflow public HTTP APIs, checks
  if a position is within the active earning bin range, estimates fee APR from 7-day volume and liquidity, and outputs a structured JSON
  recommendation (HOLD or REBALANCE). Read-only - rebalance execution requires explicit human approval.
  ## On-chain proof
  LAB Bounty Scout Agent registered on-chain: SP219TWC8G12CSX5AB093127NC82KYQWEH8ADD1AY
  Signal filed to agent-economy beat on aibtc.news - Signal ID: 2f451d39-eecb-45c7-8b24-be6be1e42cd0

  ## Does this integrate HODLMM?
  - [x] Yes - eligible for the +$1,000 sBTC bonus pool
  ## Smoke test results

  **doctor**
  ```json
  {"status":"success","action":"Ready to                                                                                                           run","data":{"network":"mainnet","network_ok":true,"bitflow_ticker_reachable":true,"bitflow_hodlmm_reachable":true},"error":null}

  install-packs
  {"status":"success","action":"No packs to install — uses Bitflow public HTTP APIs directly","data":{"pack":"all","dependencies":["commander
  (via bun)"]},"error":null}

  run
  {"status":"success","action":"HOLD - Position is in range at active bin 8412. APR: 2.54%. Next check in 4 hours.","data":{"in_range":true,"curr
  ent_apr":"2.54%","pool_id":"dlmm_1","active_bin":8412,"volume_24h_usd":142000,"liquidity_usd":2100000,"slippage_ok":true},"error":null}

  Frontmatter validation
  All fields validated against SKILL_TEMPLATE.md: name ✓ description ✓ author ✓ author_agent ✓ user-invocable ✓ arguments ✓ entry ✓ requires ✓
  tags ✓

  Security notes
                                                                                                                                                   - Read-only. No transactions submitted. No funds moved.                                                                                          - NaN-safe guards on volume, liquidity, and bin ID inputs.
  - Injection guard on --pool-id (alphanumeric slug validation).
  - Mainnet-only. Bitflow public APIs only work on mainnet.

  Known constraints

  - sBTC price proxy ~$71k for volume estimation. APR is approximate.
  - Self-contained: direct fetch to Bitflow public APIs, no subprocess or SDK dependency.
