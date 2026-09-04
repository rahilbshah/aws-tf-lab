# 11-cloudfront — verification runbook

```bash
terraform apply        # distribution deployment takes a few minutes
cf=$(terraform output -raw cloudfront_url)
s3=$(terraform output -raw direct_s3_url)
```

---

## 1. The security lesson — is the back door actually shut?

```bash
curl -s -o /dev/null -w '%{http_code}\n' "$cf"    # expect 200
curl -s -o /dev/null -w '%{http_code}\n' "$s3"    # expect 403
```

Block Public Access is **fully on** and the bucket policy trusts only *this*
distribution. CloudFront is the only route in. Contrast with `10-route53`,
where S3 *website* endpoints forced the buckets public — a website endpoint is
a "custom origin" and cannot use OAC at all.

**Now break it deliberately:** delete the `condition` block from the bucket
policy in `cloudfront.tf` and re-apply. Everything still works — and that is the
point. The condition isn't what makes *your* distribution work; it's what stops
*everyone else's* distribution from working. That failure is invisible until
someone exploits it. Put it back.

## 2. Watch the cache actually work

```bash
for i in 1 2 3; do
  curl -s -D- -o /dev/null "$cf" | grep -iE 'x-cache|age|x-amz-cf-pop'
  echo '---'
done
```

**Predict:** what does `x-cache` say on the first request vs the second?

- `Miss from cloudfront` → went to S3
- `Hit from cloudfront` → served from the edge
- `Age:` → seconds this object has been cached
- `X-Amz-Cf-Pop:` → **which edge served you**

## 3. Price class, observed

Look at that `X-Amz-Cf-Pop` code. We set `price_class = "PriceClass_100"`
(US / Canada / Europe / Israel only), so from India you are being served from a
*distant* edge.

Change it to `PriceClass_All`, re-apply, and check the POP again. That is
exactly what the price class buys: more edge locations, closer to more users,
for more money.

## 4. TTL and invalidation

Change "version 1" to "version 2" in `main.tf` and apply.

```bash
curl -s "$cf" | grep version
```

**Predict:** do you see version 2 immediately? Why not? (The HTML cache policy
has `default_ttl = 60`.)

Wait it out, or force it:

```bash
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw distribution_id) --paths '/*'
```

**Costs:** the first **1,000 invalidation paths per month per account** are
free, and `/*` counts as **one path** no matter how many files it clears.

## 5. Why fingerprinted filenames beat invalidation

`/static/app.a1b2c3.css` uses the long managed TTL. It never needs invalidating
— a new build produces `app.d4e5f6.css`, a *different cache key*. AWS
recommends this over invalidation because a user's browser or corporate proxy
may keep serving the old file even after you invalidate CloudFront. You can't
invalidate someone else's cache; you can only stop asking for that name.

## 6. Teardown

```bash
terraform destroy
```

Distribution deletion is slow — CloudFront disables it first, then deletes.
Several minutes is normal.
