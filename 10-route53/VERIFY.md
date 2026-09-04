# 10-route53 — verification runbook

**Rule: write down your prediction before you run each command.** The Terraform
here is plumbing; the learning is in whether the answer matches what you expected.

```bash
terraform apply
ns=$(terraform output -raw ns)
zone=$(terraform output -raw zone_name)
```

---

## 1. Simple routing — no balancing, no health checks

```bash
for i in $(seq 5); do dig +short @$ns simple.$zone A | tr '\n' ' '; echo; done
```

**Predict:** how many addresses come back per query? Same order every time?

*What it proves:* all three values, **random order**, client picks. Route 53 is not
load balancing and is not checking health — this is the record type people wrongly
believe distributes traffic.

## 2. Weighted — 90 / 10

```bash
for i in $(seq 100); do dig +short @$ns weighted.$zone A; done | sort | uniq -c
```

**Predict:** roughly what split, and which IP dominates? (`.10` is weight 90, `.20` is 10.)

*What it proves:* Route 53 chooses **one** record per query, in proportion to weight.
Contrast with #1, which returned everything.

## 3. Failover — the main event

```bash
dig +short @$ns www.$zone CNAME          # baseline
```
**Predict:** primary or secondary?

Now break the primary:
```bash
aws s3 rm s3://$(terraform output -raw primary_bucket)/index.html
```

**Predict:** how long until the answer changes, and why that number?
*(interval x threshold = 30 x 3 = 90s, plus aggregation — budget ~2 min.)*

Watch it flip:
```bash
while true; do date +%T; dig +short @$ns www.$zone CNAME; sleep 15; done
```

Confirm Route 53 agrees:
```bash
aws route53 get-health-check-status --health-check-id $(terraform output -raw health_check_id) \
  --query 'HealthCheckObservations[].StatusReport.Status' --output text
```

Then restore it and watch it flip back:
```bash
echo '<h1>PRIMARY — us-east-1</h1>' > /tmp/index.html
aws s3 cp /tmp/index.html s3://$(terraform output -raw primary_bucket)/index.html --content-type text/html
```

## 4. Multivalue — the health-checked contrast to #1

```bash
dig +short @$ns multivalue.$zone A
```

Run it **while the primary is broken**. **Predict:** how many of the three come back?

*What it proves:* `203.0.113.1` shares the failing health check, so it is removed
from the answer. Same shape as simple routing, but health-aware. That difference
is the whole exam question.

## 5. Geolocation — by where the USER is

```bash
dig +short @$ns geo.$zone A                              # you
dig +short +subnet=13.234.0.0/24  @$ns geo.$zone A       # Mumbai  -> expect .102
dig +short +subnet=3.5.140.0/24   @$ns geo.$zone A       # Seoul   -> expect ?
dig +short +subnet=52.94.76.0/24  @$ns geo.$zone A       # Virginia-> expect .101
```

**Predict each one.** Seoul matches no country record — what does it get, and what
would happen if the `*` default record did not exist?

*What it proves:* EDNS0 client subnet, and why a missing default is an outage.

## 6. Latency — by which REGION is fastest

```bash
dig +short +subnet=13.234.0.0/24 @$ns latency.$zone A
dig +short +subnet=52.94.76.0/24 @$ns latency.$zone A
```

**Predict:** does this pick by *country* like #5, or by something else?

---

## Teardown — this one has a clock on it

The hosted zone is **free only if deleted within 12 hours of creation**. After that
it is $0.50/month. Unlike your other labs, don't leave this running.

```bash
terraform destroy
```
